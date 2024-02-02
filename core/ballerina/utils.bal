# Checks if the provided DICOM transfer syntax is an explicit VR type.
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
    string? repeatingTagStr = getRepeatingTagsMapKey(tag);
    if repeatingTagStr is string {
        return true;
    }
    // TODO: Implement private tag checking
    return false;
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

# Checks if the given `Tag` is a private DICOM tag.
#
# + tag - The `Tag` to be checked
# + return - `true` if the Tag is a private tag, or else `false`
public isolated function isPrivateTag(Tag tag) returns boolean => tag.group % 2 != 0;

# Checks if the given `Tag` is a private creator tag.
#
# + tag - The `Tag` to be checked
# + return - `true` if the provided Tag is a private creator tag, otherwise `false`
public isolated function isPrivateCreatorTag(Tag tag) returns boolean {
    // Based off of Section 7.8.1 in Part 5
    if isPrivateTag(tag) {
        return 0x0010 <= tag.element && tag.element <= 0x0FF;
    }
    return false;
}

# Checks if the given `Tag` is a file meta information tag.
#
# + tag - The `Tag` to be checked
# + return - `true` if the provided `Tag` is a file meta information tag, otherwise `false`
public isolated function isFileMetaInfoTag(Tag tag) returns boolean {
    // File meta information elements have a group number of 2
    // Section 7.1 in Part 10
    return tag.group == 2;
}

# Checks if the given `Tag` is a pixel data tag.
#
# + tag - The `Tag` to be checked
# + return - `true` if the provided `Tag` is a pixel data tag, otherwise `false`
public isolated function isPixelDataTag(Tag tag) returns boolean => PIXEL_DATA_TAGS.indexOf(tag) != ();

# Converts a `Tag` to its string representation.
#
# + tag - The `Tag` to convert
# + return - The string representation of the given `Tag`
public isolated function tagToStr(Tag tag) returns string
    => tag.group.toHexString().padZero(4).toUpperAscii() + tag.element.toHexString().padZero(4).toUpperAscii();

# Converts a tag string into a `Tag`.
#
# + tagStr - The tag string to convert
# + return - The `Tag` if the tag string is valid, or an `Error`
public isolated function strToTag(string tagStr) returns Tag|Error {
    do {
        if tagStr.length() != 8 {
            return error("Tag string must have a length of 8");
        }
        int:Unsigned16 group = check int:fromHexString(tagStr.substring(0, 4)).ensureType();
        int:Unsigned16 element = check int:fromHexString(tagStr.substring(4)).ensureType();
        return {group: group, element: element};
    } on fail error e {
        return error Error(string `Invalid tag string: ${tagStr}`, e);
    }
}

# Converts a `Tag` to its integer representation.
#
# + tag - `Tag` to convert
# + return - The integer representation of the given Tag, or an `Error`
public isolated function tagToInt(Tag tag) returns int|Error {
    int|error tagInt = int:fromHexString(tagToStr(tag));
    if tagInt is int {
        return tagInt;
    }
    return error Error(string `Tag to int conversion failed`, tagInt);
}

# Retrieves a data element from a DICOM dataset using its keyword.
#
# + dataset - The DICOM dataset to search in
# + tagKeyword - The keyword of the data element to find
# + return - The `DataElement` with matching keyword if found, otherwise `()`
public isolated function getDataElementFromKeyword(Dataset dataset, string tagKeyword) returns DataElement? {
    Tag? tag = getTagFromKeyword(tagKeyword);
    if tag == () {
        return;
    }
    if dataset.hasKey(tag) {
        return dataset.get(tag);
    }
    return;
}

# Retrieves the DICOM Tag associated with a data element keyword.
#
# + tagKeyword - The keyword of the data element to search for
# + return - The `Tag` associated with the keyword if found, otherwise `()`
public isolated function getTagFromKeyword(string tagKeyword) returns Tag? {
    foreach [string, json] [key, value] in standardTagsMap.entries() {
        if value.keyword == tagKeyword {
            Tag|error tag = strToTag(key);
            if tag is Tag {
                return tag;
            }
        }
    }
    return;
}

# Retrieves the `TagInfo` associated with a standard DICOM tag.
#
# + tag - The `Tag` to retrieve the `TagInfo` of
# + return - The `TagInfo` if found, otherwise `()`
public isolated function getStandardTagInfo(Tag tag) returns TagInfo? {
    TagInfo|error? tagInfo = ();
    string tagStr = tagToStr(tag);
    if standardTagsMap.hasKey(tagStr) {
        tagInfo = standardTagsMap.get(tagStr).cloneWithType();
    }
    if tagInfo is TagInfo {
        return tagInfo;
    }
    return;
}

# Retrieves the `TagInfo` associated with a repeating DICOM tag.
#
# + tag - The `Tag` to retrieve the `TagInfo` of
# + return - The `TagInfo` if found, otherwise `()`
public isolated function getRepeatingTagInfo(Tag tag) returns TagInfo? {
    TagInfo|error? tagInfo = ();
    int|error tagInt = tagToInt(tag);
    if tagInt is int {
        string? maskX = maskMatch(tagInt);
        if maskX is string {
            tagInfo = repeatingTagsMap.get(maskX).cloneWithType();
        }
    }
    if tagInfo is TagInfo {
        return tagInfo;
    }
    return;
}

# Retrieves the `TagInfo` associated with a private DICOM tag.
#
# + tag - The `Tag` to retrieve the `TagInfo` of
# + privateCreatorID - The private creator identifier associated with the tag
# + return - The `TagInfo` if found, otherwise `()`
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

    if tagInfo is error {
        return;
    }

    return tagInfo;
}

# Validates a DICOM entity (`Tag`, `DataElement`, or `Dataset`).
#
# + entity - The DICOM entity to validate (`Tag`, `DataElement`, or `Dataset`)
# + transferSyntax - The transfer syntax of the entity
# + return - A `DicomValidationError` if the validation fails.
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

# Encodes a DICOM entity (`Tag`, `DataElement`, or `Dataset`) to a bytes.
#
# + entity - The DICOM entity to encode (`Tag`, `DataElement`, or `Dataset`)
# + transferSyntax - The transfer syntax for the encoded byte representation
# + encodeSorted - Indicates whether the dataset should be sorted in ascending order before encoding. 
#                  This is an optional parameter.
# + validateBeforeEncoding - Whether to validate the entity before encoding. This is an optional parameter.
# + return - A `byte[]` containing the encoded DICOM entity, or an `EncodingError` if the encoding fails
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

# Resizes a byte array containing numeric data to a specified length, respecting the byte order.
#
# + byteArray - The byte array containing numeric data
# + byteOrder - The byte order used in the byte array
# + newLength - The desired new length of the byte array
# + return - A new `byte[]` with the resized numeric data
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
# + return - The `VR` type if a valid string representation, otherwise an `Error`
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
# + bytes - The byte array containing the integer data
# + byteOrder - The byte order used in the byte array
# + return - An `int` if the conversion is successful, or an `Error` if the conversion fails.
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
# + return - A `float` if the conversion is successful, or an `Error` if the conversion fails.
public isolated function bytesToFloat(byte[] bytes, ByteOrder byteOrder) returns float|Error {
    float|error 'float = trap javaBytesToFloat(bytes, byteOrder);
    if 'float is float {
        return 'float;
    }
    return error Error("Bytes to float conversion failed", 'float);
}

# Converts an integer value to a byte array representation.
#
# + n - The integer value to be converted
# + byteOrder - The desired byte order for the byte array
# + return - A `byte[]` containing the encoded integer, or an `Error` if the conversion fails
public isolated function intToBytes(int n, ByteOrder byteOrder) returns byte[]|Error {
    byte[]|error intBytes = trap javaIntToBytes(n, byteOrder);
    if intBytes is byte[] {
        return intBytes;
    }
    return error Error("Int to bytes conversion failed", intBytes);
}

# Converts a float value to a byte array representation.
#
# + n - The float value to be converted
# + byteOrder - The desired byte order for the byte array
# + return - A `byte[]` containing the encoded float, or an `Error` if the conversion fails
public isolated function floatToBytes(float n, ByteOrder byteOrder) returns byte[]|Error {
    byte[]|error floatBytes = trap javaFloatToBytes(n, byteOrder);
    if floatBytes is byte[] {
        return floatBytes;
    }
    return error Error("Float to bytes conversion failed", floatBytes);
}

public isolated function isStringVr(Vr vr) returns boolean => STR_VRs.indexOf(vr) != ();

public isolated function isBytesVr(Vr vr) returns boolean => BYTES_VRs.indexOf(vr) != ();

public isolated function isIntVr(Vr vr) returns boolean => INT_VRs.indexOf(vr) != ();

public isolated function isFloatVr(Vr vr) returns boolean => FLOAT_VRs.indexOf(vr) != ();

isolated function maskMatch(int tagInt) returns string? {
    foreach var key in repeatingTagsMasks.keys() {
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

isolated function getRepeatingTagsMapKey(Tag tag) returns string? {
    int|error tagInt = tagToInt(tag);
    if tagInt is int {
        string? maskX = maskMatch(tagInt);
        if maskX is string {
            return maskX;
        }
    }
    return;
}

isolated function truncateNumericBytes(byte[] array, ByteOrder byteOrder, int newLength) returns byte[] {
    int 'start = byteOrder is BIG_ENDIAN ? array.length() - newLength : 0;
    return array.slice('start, 'start + newLength);
}

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
