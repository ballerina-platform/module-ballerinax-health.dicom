import ballerina/lang.regexp;

isolated function validateDataset(Dataset dataset, TransferSyntax transferSyntax) returns ValidationError? {
    do {
        foreach DataElement dataElement in dataset {
            check validateDataElement(dataElement, transferSyntax);
        }
    } on fail error e {
        return error ValidationError(string `Data set validation failed`, e);
    }
}

isolated function validateDataElement(DataElement dataElement,
        TransferSyntax transferSyntax) returns ValidationError? {
    do {
        if isPrivateTag(dataElement.tag) {
            fail error ValidationError("Private data element validation is not supported");
        }

        // Validate tag
        check validateTag(dataElement.tag);

        // Get tag information from DICOM dictionaries
        TagInfo? tagInfo = getStandardTagInfo(dataElement.tag) ?: getRepeatingTagInfo(dataElement.tag);
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
        check validateValue(vr, dataElement.value, getByteOrder(transferSyntax));
    } on fail error e {
        return error ValidationError(string `Data element validation failed: ${dataElement.toString()}`, e);
    }
}

isolated function validateTag(Tag tag) returns ValidationError? {
    if !isValidTag(tag) {
        return error ValidationError(string `Tag validation failed: ${tagToStr(tag)}`,
                error ValidationError("Invalid tag"));
    }
}

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

isolated function validateValueFormat(Vr vr, string value) returns ValidationError? {
    do {
        ValueFormatValidator? validator = getFormatValidator(vr);
        if validator == () {
            fail error ValidationError(string `Value format validation is not supported for the VR ${vr}`);
        }
        if validator is ValueFormatValidatorRegex {
            regexp:RegExp r = check regexp:fromString(validator);
            if !value.matches(r) {
                fail error ValidationError(constructInvalidValueFormatErrorMsg(vr, value));
            }
        } else { // Validator is a function
            check validator(vr, value);
        }
    } on fail error e {
        return error ValidationError("Value format validation failed", e);
    }
}

isolated function getValueLength(Vr vr, DataElementValue value, ByteOrder byteOrder) returns int? {
    byte[]|EncodingError valueBytes = encodeValue(vr, value, byteOrder);
    return valueBytes is byte[] ? valueBytes.length() : ();
}

isolated function getCharsetValidator(Vr vr) returns string?
    => VALUE_CHARSET_VALIDATORS.hasKey(vr) ? VALUE_CHARSET_VALIDATORS.get(vr) : ();

isolated function getFormatValidator(Vr vr) returns ValueFormatValidator?
    => VALUE_FORMAT_VALIDATORS.hasKey(vr) ? VALUE_FORMAT_VALIDATORS.get(vr) : ();

isolated function getExpectedValueFormat(Vr vr) returns string?
    => VALUE_VALID_FORMATS.hasKey(vr) ? VALUE_VALID_FORMATS.get(vr) : ();

isolated function constructInvalidValueTypeErrorMsg(Vr vr, DataElementValue value, string expectedType) returns string
    => string `Invalid value type for VR ${vr}. Value must be of '${expectedType}' type.`;

isolated function constructInvalidValueLengthErrorMsg(Vr vr, int valueLength, int maxLength) returns string
    => string `Invalid value length for VR ${vr}. Value exceeds the allowed maximum length: ${maxLength}.`;

isolated function constructInvalidValueFormatErrorMsg(Vr vr, string value) returns string {
    string? expectedFormat = getExpectedValueFormat(vr);
    if expectedFormat is string {
        return string `Invalid value format for VR ${vr}. Value must follow the following format: ${expectedFormat}.`;
    }
    return string `Invalid value format for VR ${vr}`;
}
