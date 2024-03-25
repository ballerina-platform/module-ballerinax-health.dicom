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

# Transforms a record into a Dataset.
#
# + 'record - The record to be transformed 
# + transferSyntax - The transfer syntax to be used during the transformation
# + validateDataElements - A boolean flag indicating whether to validate data elements during the transformation
# + return - The transformed `Dataset` if the transformation is successful, or an `Error` otherwise 
public isolated function recordToDataset(record {} 'record, TransferSyntax transferSyntax,
        boolean validateDataElements = true) returns Dataset|Error {
    do {
        Dataset dataset = table [];

        foreach [string, anydata] [keyword, value] in 'record.entries() {
            // Get tag
            Tag? tag = getTagFromKeyword(keyword);
            if tag == () {
                fail error Error(string `Failed to get the tag for the keyword: ${keyword}`);
            }

            if isPrivateTag(tag) {
                fail error Error(string `Private data elements are not supported in record format, `
                        + string `please use the 'Dataset' type instead`);
            }

            // Get tag information
            TagInfo? tagInfo = getTagInfo(tag);
            if tagInfo == () {
                fail error Error(string `Failed to get tag information of the tag: ${tagToStr(tag)}`);
            }

            // Construct data element
            DataElement dataElement = {
                tag: tag,
                value: check value.ensureType(DataElementValue)
            };

            // Include VR if an explicit transfer syntax
            if isExplicitTransferSyntax(transferSyntax) {
                dataElement.vr = tagInfo.vr;
            }

            // Validate constructed data element
            if validateDataElements {
                check validate(dataElement, transferSyntax);
            }

            dataset.add(dataElement);
        }

        return dataset;
    } on fail error e {
        return error Error("An error occurred transforming the record to a dataset", e);
    }
}

# Sorts a DICOM dataset based on the tag numbers in ascending order.
#
# + dataset - The dataset to be sorted
# + return - A new sorted dataset
public isolated function getSortedDataset(Dataset dataset) returns Dataset {
    return <Dataset>from DataElement dataElement in dataset
        order by dataElement.tag.group ascending, dataElement.tag.element ascending
        select dataElement;
}

# Checks if a DICOM transfer syntax is an explicit type.
#
# + transferSyntax - The DICOM transfer syntax to be evaluated
# + return - `true` if the transfer syntax is explicit, otherwise `false`
public isolated function isExplicitTransferSyntax(TransferSyntax transferSyntax) returns boolean
    => transferSyntax is EXPLICIT_VR_BIG_ENDIAN || transferSyntax is EXPLICIT_VR_LITTLE_ENDIAN;

# Checks if a tag string represents a valid DICOM tag.
#
# + tagStr - The tag string to be validated
# + return - `true` if the provided tag string is a valid DICOM tag, otherwise `false`
public isolated function isValidTagStr(string tagStr) returns boolean {
    if tagStr.length() != 8 {
        return false;
    }
    Tag|error tag = strToTag(tagStr);
    if tag is error {
        return false;
    }
    return isValidTag(tag);
}

# Checks if a Tag is a valid DICOM tag.
#
# + tag - The Tag to be validated
# + return - `true` if the provided Tag is a valid DICOM tag, otherwise `false`
public isolated function isValidTag(Tag tag) returns boolean {
    // Check if a standard tag
    string tagStr = tagToStr(tag);
    if standardTagsMap.hasKey(tagStr) {
        return true;
    }
    // Check if a repeating tag
    return getRepeatingTagsMapKey(tag) is string ? true : false;
}

# Checks if a string is a valid DICOM data element keyword.
#
# + keyword - The string to be validated
# + return - `true` if the provided string is a valid DICOM keyword, otherwise `false`
public isolated function isValidKeyword(string keyword) returns boolean {
    foreach json de in standardTagsMap {
        if de.keyword == keyword {
            return true;
        }
    }
    return false;
}

# Checks if a tag is a command tag.
#
# + tag - The tag to be checked
# + return - `true` if the tag is a command tag, or else `false`
public isolated function isCommandTag(Tag tag) returns boolean => tag.group == 0x0000;

# Checks if a tag is a private tag.
#
# + tag - The tag to be checked
# + return - `true` if the Tag is a private tag, or else `false`
public isolated function isPrivateTag(Tag tag) returns boolean => tag.group % 2 != 0;

# Checks if a tag is a private creator tag.
#
# + tag - The tag to be checked
# + return - `true` if the provided Tag is a private creator tag, otherwise `false`
public isolated function isPrivateCreatorTag(Tag tag) returns boolean {
    // Based off of Section 7.8.1 in Part 5
    if isPrivateTag(tag) {
        return 0x0010 <= tag.element && tag.element <= 0x0FF;
    }
    return false;
}

# Checks if a tag is a file meta information tag.
#
# + tag - The tag to be checked
# + return - `true` if the provided tag is a file meta information tag, otherwise `false`
public isolated function isFileMetaInfoTag(Tag tag) returns boolean {
    // File meta information elements have a group number of 2
    // Section 7.1 in Part 10
    return tag.group == 2;
}

# Checks if a tag is a pixel data tag.
#
# + tag - The tag to be checked
# + return - `true` if the provided tag is a pixel data tag, otherwise `false`
public isolated function isPixelDataTag(Tag tag) returns boolean => PIXEL_DATA_TAGS.indexOf(tag) != ();

# Converts a tag to its string representation.
#
# + tag - The tag to be converted
# + return - The string representation of the given tag
public isolated function tagToStr(Tag tag) returns string
    => tag.group.toHexString().padZero(4).toUpperAscii() + tag.element.toHexString().padZero(4).toUpperAscii();

# Converts a tag string into a tag.
#
# + tagStr - The tag string to be converted
# + return - The tag if the conversion is successful, or an `Error` if the conversion fails
public isolated function strToTag(string tagStr) returns Tag|Error {
    do {
        if tagStr.length() != 8 {
            return error("Tag string must have a length of 8");
        }
        int:Unsigned16 group = check int:fromHexString(tagStr.substring(0, 4)).ensureType();
        int:Unsigned16 element = check int:fromHexString(tagStr.substring(4)).ensureType();
        return {group, element};
    } on fail error e {
        return error Error(string `Invalid tag string: ${tagStr}`, e);
    }
}

# Converts a tag to its integer representation.
#
# + tag - The tag to be converted
# + return - The integer representation of the given tag, or an `Error` if the conversion fails
public isolated function tagToInt(Tag tag) returns int|Error {
    int|error tagInt = int:fromHexString(tagToStr(tag));
    if tagInt is int {
        return tagInt;
    }
    return error Error(string `Tag to int conversion failed`, tagInt);
}

# Retrieves a data element from a dataset using its keyword.
#
# + dataset - The dataset to be searched
# + tagKeyword - The keyword of the data element to find
# + return - The data element with matching keyword if found, otherwise `()`
public isolated function getDataElementFromKeyword(Dataset dataset, string tagKeyword) returns DataElement? {
    Tag? tag = getTagFromKeyword(tagKeyword);
    if tag == () {
        return;
    }
    return dataset.hasKey(tag) ? dataset.get(tag) : ();
}

# Retrieves the tag from the keyword.
#
# + tagKeyword - The keyword of the data element to search for
# + return - The tag associated with the keyword if found, otherwise `()`
public isolated function getTagFromKeyword(string tagKeyword) returns Tag? {
    // TODO: Add tag from keyword support for repeating and known private tags
    // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1536
    foreach [string, json] [key, value] in standardTagsMap.entries() {
        if value.keyword == tagKeyword {
            Tag|error tag = strToTag(key);
            return tag is Tag ? tag : ();
        }
    }
    return;
}

# Retrieves the tag information of a tag.
#
# + tag - The tag
# + return - The `TagInfo` if tag information is found, otherwise `()`
public isolated function getTagInfo(Tag tag) returns TagInfo? {
    // Could be a standard or a repeating tag
    TagInfo? tagInfo = getStandardTagInfo(tag);
    return tagInfo is TagInfo ? tagInfo : getRepeatingTagInfo(tag);
}

# Retrieves DICOM standard tag information.
#
# + tag - The tag
# + return - The `TagInfo` if tag information is found, otherwise `()`
isolated function getStandardTagInfo(Tag tag) returns TagInfo? {
    TagInfo|error? tagInfo = ();
    string tagStr = tagToStr(tag);
    if standardTagsMap.hasKey(tagStr) {
        tagInfo = standardTagsMap.get(tagStr).cloneWithType();
    }
    return tagInfo is TagInfo ? tagInfo : ();
}

# Retrieves DICOM repeating tag information.
#
# + tag - The tag
# + return - The `TagInfo` if tag information is found, otherwise `()`
isolated function getRepeatingTagInfo(Tag tag) returns TagInfo? {
    TagInfo|error? tagInfo = ();
    int|error tagInt = tagToInt(tag);
    if tagInt is error {
        return;
    }
    string? maskX = maskMatch(tagInt);
    if maskX is string {
        tagInfo = repeatingTagsMap.get(maskX).cloneWithType();
    }
    return tagInfo is TagInfo ? tagInfo : ();
}

# Retrieves the tag information of a private DICOM tag.
#
# + tag - The private tag
# + privateCreatorID - The private creator identifier of the tag
# + return - The `TagInfo` if tag information is found, otherwise `()`
public isolated function getPrivateTagInfo(Tag tag, string privateCreatorID) returns TagInfo? {
    TagInfo|error? tagInfo = ();

    map<json>|error privateDict = trap privateTagsMap.get(privateCreatorID).ensureType();
    if privateDict is error { // No matching private dictionary
        return;
    }

    string tagStr = tagToStr(tag);
    string group = tagStr.substring(0, 4);
    string element = tagStr.substring(4);

    // Keys to match against in the private dictionary
    string[] keys = [
        tagStr,
        string `${group}xx${element.substring(2)}`,
        string `${group.substring(0, 2)}xxxx${element.substring(2)}`
    ];

    // Keys available in the private dictionary
    string[] availableKeys = [];

    foreach var key in keys {
        if privateDict.hasKey(key) {
            availableKeys.push(key);
        }
    }

    // If matching keys are available, retrieve the corresponding tag information
    if availableKeys.length() > 0 {
        tagInfo = privateDict.get(availableKeys[0]).cloneWithType();
    }

    return tagInfo is error ? () : tagInfo;
}

# Validates a DICOM entity (tag, data element, or dataset).
#
# + entity - The DICOM entity to be validated
# + transferSyntax - The transfer syntax of the entity
# + return - A `ValidationError` if the validation fails
public isolated function validate(Tag|DataElement|Dataset entity,
        TransferSyntax transferSyntax) returns ValidationError? {
    if entity is Dataset {
        check validateDataset(entity, transferSyntax);
    } else if entity is DataElement {
        check validateDataElement(entity, transferSyntax);
    } else { // Tag
        check validateTag(entity);
    }
}

# Encodes a DICOM entity (tag, data element, or dataset) to a bytes.
#
# + entity - The DICOM entity to be encoded
# + transferSyntax - The transfer syntax to be used for the encoding
# + encodeSorted - A boolean flag indicating whether the dataset should be sorted in ascending order before encoding. 
# This is an optional parameter.
# + validateBeforeEncoding - A boolean flag indicating whether to validate the entity before encoding. 
# This is an optional parameter.
# + return - The encoded DICOM entity, or an `EncodingError` if the encoding fails
public isolated function toBytes(Tag|DataElement|Dataset entity, TransferSyntax transferSyntax,
        boolean encodeSorted = false, boolean validateBeforeEncoding = true)
        returns byte[]|EncodingError {
    do {
        // Validate the entity before encoding
        if validateBeforeEncoding {
            check validate(entity, transferSyntax);
        }
        if entity is Tag {
            return check encodeTag(entity, getByteOrder(transferSyntax));
        } else if entity is DataElement {
            return check encodeDataElement(entity, transferSyntax);
        } else { // Dataset
            return check encodeDataset(entity, transferSyntax, encodeSorted);
        }
    } on fail error e {
        return error EncodingError("Entity encoding failed", e);
    }
}

# Resizes a numeric byte array to a specified length respecting the byte order.
#
# + byteArray - The byte array to be resized
# + byteOrder - The byte order used in the byte array
# + newLength - The desired new length of the byte array
# + return - A new resized byte array
public isolated function resizeNumericBytes(byte[] byteArray, ByteOrder byteOrder, int newLength) returns byte[] {
    if byteArray.length() == newLength {
        return byteArray;
    } else if (byteArray.length() < newLength) {
        return padNumericBytes(byteArray, byteOrder, newLength);
    } else {
        return truncateNumericBytes(byteArray, byteOrder, newLength);
    }
}

# Converts a string representation of a VR to its corresponding VR type.
#
# + vrStr - The string representation of the VR to be converted
# + return - The `Vr` type if a valid string representation, otherwise an `Error`
public isolated function strToVr(string vrStr) returns Vr|Error {
    Vr|error vr = vrStr.ensureType(Vr);
    if vr is Vr {
        return vr;
    }
    return error Error(string `Invalid VR string: ${vrStr}`);
}

# Retrieves the byte order associated with a DICOM transfer syntax.
#
# + transferSyntax - The DICOM transfer syntax
# + return - The corresponding `ByteOrder`
public isolated function getByteOrder(TransferSyntax transferSyntax) returns ByteOrder {
    match transferSyntax {
        IMPLICIT_VR_LITTLE_ENDIAN|EXPLICIT_VR_LITTLE_ENDIAN => {
            return LITTLE_ENDIAN;
        }
        _ => {
            return BIG_ENDIAN;
        }
    }
}

# Converts a byte array representing an integer to an integer value.
#
# + bytes - The byte array containing the integer bytes
# + byteOrder - The byte order used in the byte array
# + return - The integer value if the conversion is successful, or an `Error` if the conversion fails.
public isolated function bytesToInt(byte[] bytes, ByteOrder byteOrder) returns int|Error {
    int|error 'int = trap javaBytesToInt(bytes, byteOrder);
    if 'int is int {
        return 'int;
    }
    return error Error("Bytes to int conversion failed", 'int);
}

# Converts a byte array representing a float to a float value.
#
# + bytes - The byte array containing the float data
# + byteOrder - The byte order used in the byte array
# + return - The float value if the conversion is successful, or an `Error` if the conversion fails.
public isolated function bytesToFloat(byte[] bytes, ByteOrder byteOrder) returns float|Error {
    float|error 'float = trap javaBytesToFloat(bytes, byteOrder);
    if 'float is float {
        return 'float;
    }
    return error Error("Bytes to float conversion failed", 'float);
}

# Converts an integer value to its bytes representation.
#
# + n - The integer value to be converted
# + byteOrder - The byte order to be used for the conversion
# + return - A `byte[]` containing the encoded integer, or an `Error` if the conversion fails
public isolated function intToBytes(int n, ByteOrder byteOrder) returns byte[]|Error {
    byte[]|error intBytes = trap javaIntToBytes(n, byteOrder);
    if intBytes is byte[] {
        return intBytes;
    }
    return error Error("Int to bytes conversion failed", intBytes);
}

# Converts a float value to its bytes representation.
#
# + n - The float value to be converted
# + byteOrder - The byte order to be used for the conversion
# + return - A `byte[]` containing the encoded float, or an `Error` if the conversion fails
public isolated function floatToBytes(float n, ByteOrder byteOrder) returns byte[]|Error {
    byte[]|error floatBytes = trap javaFloatToBytes(n, byteOrder);
    if floatBytes is byte[] {
        return floatBytes;
    }
    return error Error("Float to bytes conversion failed", floatBytes);
}

# Checks if a VR is a string type VR.
#
# + vr - The VR to be checked
# + return - `true` if the VR is a string type VR, otherwise `false`
public isolated function isStringVr(Vr vr) returns boolean => STR_VRs.indexOf(vr) != ();

# Checks if a VR is a bytes type VR.
#
# + vr - The VR to be checked
# + return - `true` if the VR is a bytes type VR, otherwise `false`
public isolated function isBytesVr(Vr vr) returns boolean => BYTES_VRs.indexOf(vr) != ();

# Checks if a VR is an integer type VR.
#
# + vr - The VR to be checked
# + return - `true` if the VR is an integer type VR, otherwise `false`
public isolated function isIntVr(Vr vr) returns boolean => INT_VRs.indexOf(vr) != ();

# Checks if a VR is a float type VR.
#
# + vr - The VR to be checked
# + return - `true` if the VR is a float type VR, otherwise `false`
public isolated function isFloatVr(Vr vr) returns boolean => FLOAT_VRs.indexOf(vr) != ();

# Retrieves repeaters tag mask for a tag using tag integer.
#
# + tagInt - The tag int to be checked
# + return - The tag mask if the tag is in the repeaters tags dictionary, otherwise `()`
isolated function maskMatch(int tagInt) returns string? {
    foreach string key in repeatingTagsMasks.keys() {
        int[] masks = repeatingTagsMasks.get(key);
        int mask1 = masks[0];
        int mask2 = masks[1];
        // mask1 is XOR'd to see that all non-"x" bits
        // are identical (XOR'd result = 0 if identical)
        if ((tagInt ^ mask1) & mask2) == 0 {
            return key;
        }
    }
    return;
}

# Retrieves the repeating tag mask for a tag.
# This function serves as a convenience wrapper for the `maskMatch()` function.
#
# + tag - The tag to be checked
# + return - The tag mask if the tag is in the repeaters tags dictionary, otherwise `()`
isolated function getRepeatingTagsMapKey(Tag tag) returns string? {
    int|error tagInt = tagToInt(tag);
    if tagInt is error {
        return;
    }
    return maskMatch(tagInt);
}

# Truncates a numeric byte array to a specified length, respecting the byte order.
#
# + array - The byte array to be truncated
# + byteOrder - The byte order of the array
# + newLength - The desired length for the truncated array
# + return - A new byte array truncated to the specified length
isolated function truncateNumericBytes(byte[] array, ByteOrder byteOrder, int newLength) returns byte[] {
    if array.length() == newLength {
        return array;
    }
    int 'start = byteOrder is BIG_ENDIAN ? array.length() - newLength : 0;
    return array.slice('start, 'start + newLength);
}

# Extends a numeric byte array to a specified length, respecting the byte order.
#
# + array - The byte array to be extended
# + byteOrder - The byte order of the array
# + newLength - The desired length for the extended array
# + return - The extended byte array to the specified length
isolated function padNumericBytes(byte[] array, ByteOrder byteOrder, int newLength) returns byte[] {
    if array.length() == newLength {
        return array;
    }
    byte[] resizedArray = [...array];
    while resizedArray.length() < newLength {
        if byteOrder is BIG_ENDIAN {
            resizedArray.unshift(0x00);
        } else {
            resizedArray.push(0x00);
        }
    }
    return resizedArray;
}

# Calculates the encoded value length (VL) of a data element value.
#
# + vr - The VR of the data element  
# + value - The value of the data element 
# + byteOrder - The byte order of the data element value
# + return - The value length if if the calculation is successful, otherwise `()`
isolated function getValueLength(Vr vr, DataElementValue value, ByteOrder byteOrder) returns int? {
    byte[]|EncodingError valueBytes = encodeValue(vr, value, byteOrder);
    return valueBytes is byte[] ? valueBytes.length() : ();
}

# Retrieves the character set validator for a VR.
#
# + vr - The VR
# + return - The value character set validator if found, otherwise `()`
isolated function getCharsetValidator(Vr vr) returns string?
    => VALUE_CHARSET_VALIDATORS.hasKey(vr) ? VALUE_CHARSET_VALIDATORS.get(vr) : ();

# Retrieves the value format validator for a VR.
#
# + vr - The VR
# + return - The `ValueFormatValidator` if found, otherwise `()`
isolated function getFormatValidator(Vr vr) returns ValueFormatValidator?
    => VALUE_FORMAT_VALIDATORS.hasKey(vr) ? VALUE_FORMAT_VALIDATORS.get(vr) : ();

# Retrieves the expected value format for a VR.
#
# + vr - The VR
# + return - The expected value format if found, otherwise `()`
isolated function getExpectedValueFormat(Vr vr) returns string?
    => VALUE_VALID_FORMATS.hasKey(vr) ? VALUE_VALID_FORMATS.get(vr) : ();

# Calculates the nearest upper power of 2 to the given number.
#
# + n - The number
# + return - The nearest upper power of 2
isolated function getNearestUpperPowerOf2(int n) returns int {
    if n <= 0 {
        return 1;
    } else if n <= 2 {
        return 2;
    }
    float f = <float>n;
    float power = float:ceiling(float:log10(f) / float:log10(2));
    return <int>float:pow(2, power);
}

# Constructs an array of space (20H) bytes.
#
# + length - The length of the space bytes array
# + return - The constructed space bytes
isolated function constructSpaceBytes(int length) returns byte[] {
    byte[] spaceBytes = [];
    while spaceBytes.length() < length {
        spaceBytes.push(SPACE_BYTE);
    }
    return spaceBytes;
}
