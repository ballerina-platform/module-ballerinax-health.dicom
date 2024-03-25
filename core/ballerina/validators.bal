// Copyright (c) 2024 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/lang.regexp;

# Validates a dataset.
#
# + dataset - The dataset to be validated 
# + transferSyntax - The transfer syntax to be used for the validation
# + return - A `ValidationError` if the validation fails
isolated function validateDataset(Dataset dataset, TransferSyntax transferSyntax) returns ValidationError? {
    do {
        foreach DataElement dataElement in dataset {
            check validateDataElement(dataElement, transferSyntax);
        }
    } on fail error e {
        return error ValidationError(string `Data set validation failed`, e);
    }
}

# Validates a data element.
#
# + dataElement - The data element to be validated
# + transferSyntax - The transfer syntax to be used for the validation
# + return - A `ValidationError` if the validation fails, otherwise `()`
isolated function validateDataElement(DataElement dataElement,
        TransferSyntax transferSyntax) returns ValidationError? {
    do {
        // TODO: Add private data element validation support for known private data elements. 
        // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1531
        if isPrivateTag(dataElement.tag) {
            fail error ValidationError("Private data element validation is not supported");
        }

        // Validate tag
        check validateTag(dataElement.tag);

        // Get tag information from DICOM dictionaries
        TagInfo? tagInfo = getTagInfo(dataElement.tag);
        if tagInfo == () {
            fail error ValidationError("Could not find tag information of the data element");
        }

        // Validate VR (for explicit transfer syntaxes)
        if isExplicitTransferSyntax(transferSyntax) {
            check validateVr(dataElement, tagInfo);
        }

        // VR
        Vr? vr = dataElement.vr ?: tagInfo.vr;
        if vr == () {
            fail error ValidationError("Could not determine the VR of the data element");
        }

        // Validate value
        // Only validate if the value is not empty. In other words, 
        // if the value is not nil, as an empty value is permissible for a data element.
        if dataElement.value != () {
            check validateValue(vr, dataElement.value, getByteOrder(transferSyntax));
        }
    } on fail error e {
        return error ValidationError(string `Data element validation failed: ${dataElement.toString()}`, e);
    }
}

# Validates a tag.
#
# + tag - The tag to be validated
# + return - A `ValidationError` if the validation fails, otherwise `()`
isolated function validateTag(Tag tag) returns ValidationError? {
    if !isValidTag(tag) {
        return error ValidationError(string `Tag validation failed: ${tagToStr(tag)}`,
                error ValidationError("Invalid tag"));
    }
}

# Validates the VR of a data element.
#
# + dataElement - The data element
# + tagInfo - The tag information
# + return - A `ValidationError` if the validation fails, otherwise `()`
isolated function validateVr(DataElement dataElement, TagInfo tagInfo) returns ValidationError? {
    do {
        if dataElement.vr == () {
            fail error ValidationError("Missing VR field");
        }
        // Check if the VR matches the VR from the dictionaries
        if dataElement.vr != tagInfo.vr {
            fail error ValidationError(string `Invalid VR for the tag: ` +
                string `expected: ${tagInfo.vr.toString()}, found: ${dataElement.vr.toString()}`);
        }
    } on fail error e {
        return error ValidationError(string `VR validation failed: ${dataElement.vr ?: ""}`, e);
    }
}

# Validates a data element value.
#
# + vr - The VR of the data element 
# + value - The data element value to be validated
# + byteOrder - The byte order of the value
# + return - A `ValidationError` if the validation fails, otherwise `()`
isolated function validateValue(Vr vr, DataElementValue value, ByteOrder byteOrder) returns ValidationError? {
    do {
        // VR value validation logic is based off of Section 6.2 in Part 5
        // Validate value type
        check validateValueType(vr, value);
        // Validate value length
        check validateValueLength(vr, value, byteOrder);
        // Validate value of string VRs
        if isStringVr(vr) && value is string {
            check validateValueCharset(vr, value);
            check validateValueFormat(vr, value);
        }
    } on fail error e {
        return error ValidationError(string `Value validation failed: ${value.toString()}`, e);
    }
}

# Validates the value type of a data element value.
#
# + vr - The VR of the data element  
# + value - The data element value to be validated
# + return - A `ValidationError` if the validation fails, otherwise `()`
isolated function validateValueType(Vr vr, DataElementValue value) returns ValidationError? {
    do {
        if isStringVr(vr) {
            if value !is string {
                fail error ValidationError(constructInvalidValueTypeErrorMsg(vr, value, "string"));
            }
        } else if isBytesVr(vr) {
            if value !is byte[] {
                fail error ValidationError(constructInvalidValueTypeErrorMsg(vr, value, "byte[]"));
            }
        } else if isIntVr(vr) {
            if value !is int {
                fail error ValidationError(constructInvalidValueTypeErrorMsg(vr, value, "int"));
            }
        } else if isFloatVr(vr) {
            if value !is float {
                fail error ValidationError(constructInvalidValueTypeErrorMsg(vr, value, "float"));
            }
        } else {
            fail error ValidationError(string `Could not determine the value type of the VR ${vr}`);
        }
    } on fail error e {
        return error ValidationError("Value type validation failed", e);
    }
}

# Validates the value length (VL) of a data element value.
#
# + vr - The VR of the data element
# + value - The data element value
# + byteOrder - The byte order 
# + return - A `ValidationError` if the validation fails, otherwise `()`
isolated function validateValueLength(Vr vr, DataElementValue value,
        ByteOrder byteOrder) returns ValidationError? {
    do {
        int? valueLength = getValueLength(vr, value, byteOrder);
        if valueLength == () {
            fail error ValidationError("Could not calculate the value length of the value");
        }
        if FIXED_LENGTH_VALUE_BYTES.hasKey(vr) && valueLength > FIXED_LENGTH_VALUE_BYTES.get(vr) {
            fail error ValidationError(constructInvalidValueLengthErrorMsg(vr, valueLength,
                    FIXED_LENGTH_VALUE_BYTES.get(vr)));
        }
        if VARIABLE_LENGTH_VALUE_BYTES.hasKey(vr) && valueLength > VARIABLE_LENGTH_VALUE_BYTES.get(vr) {
            fail error ValidationError(constructInvalidValueLengthErrorMsg(vr, valueLength,
                    VARIABLE_LENGTH_VALUE_BYTES.get(vr)));
        }
    } on fail error e {
        return error ValidationError("Value length validation failed", e);
    }
}

# Validates the value character set of a string type data element value.
#
# + vr - The VR of the data element
# + value - The string type data element value to be validated
# + return - A `ValidationError` if the validation fails, otherwise `()`
isolated function validateValueCharset(Vr vr, string value) returns ValidationError? {
    do {
        string? regexStr = getCharsetValidator(vr);
        if regexStr == () {
            fail error ValidationError(string `Value charset validation is not supported for the VR ${vr}`);
        }
        regexp:RegExp r = check regexp:fromString(regexStr);
        if !value.matches(r) {
            fail error(string `Value contains invalid characters`);
        }
    } on fail error e {
        return error ValidationError("Value charset validation failed", e);
    }
}

# Validates the value format of a string type data element value.
#
# + vr - The VR of the data element 
# + value - The string type data element value to be validated
# + return - A `ValidationError` if the validation fails, otherwise `()`
isolated function validateValueFormat(Vr vr, string value) returns ValidationError? {
    do {
        ValueFormatValidator? validator = getFormatValidator(vr);
        if validator == () {
            fail error ValidationError(string `Value format validation is not supported for the VR ${vr}`);
        }
        if validator is ValueFormatValidatorRegex {
            check validateUsingValueFormatValidatorRegex(vr, validator, value);
        } else { // Validator is a function
            check validator(vr, value);
        }
    } on fail error e {
        return error ValidationError("Value format validation failed", e);
    }
}

# Validates a string type data element value using a `ValueFormatValidatorRegex`.
#
# + vr - The VR of the data element
# + validator - The value format validator regex
# + value - The string type data element value
# + return - A `ValidationError` if the validation fails, otherwise `()`
isolated function validateUsingValueFormatValidatorRegex(Vr vr, ValueFormatValidatorRegex validator,
        string value) returns ValidationError|error? {
    regexp:RegExp r = check regexp:fromString(validator);
    return !value.matches(r) ? error ValidationError(constructInvalidValueFormatErrorMsg(vr, value)) : ();
}

# Constructs an invalid value type error message.
#
# + vr - The VR of the data element 
# + value - The invalid value
# + expectedType - The expected value type
# + return - The constructed invalid value type error message
public isolated function constructInvalidValueTypeErrorMsg(Vr vr, DataElementValue value,
        string expectedType) returns string
    => string `Invalid value type for VR ${vr}: ${value.toString()}. Value must be of '${expectedType}' type.`;

# Constructs an invalid value length error message.
#
# + vr - The VR of the data element
# + valueLength - The invalid value length
# + maxLength - The allowed maximum value length
# + return - The constructed invalid value length error message
isolated function constructInvalidValueLengthErrorMsg(Vr vr, int valueLength, int maxLength) returns string
    => string `Invalid value length for VR ${vr}. Value exceeds the allowed maximum length: ${maxLength}.`;

# Constructs an invalid value format error message.
#
# + vr - The VR of the data element
# + value - The invalid value
# + return - The constructed invalid value format error message
isolated function constructInvalidValueFormatErrorMsg(Vr vr, string value) returns string {
    string? expectedFormat = getExpectedValueFormat(vr);
    if expectedFormat is string {
        return string `Invalid value format for VR ${vr}. Value must follow the following format: ${expectedFormat}.`;
    }
    return string `Invalid value format for VR ${vr}`;
}
