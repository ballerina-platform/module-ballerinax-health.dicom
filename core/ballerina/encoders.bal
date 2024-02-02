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

# Encodes a DICOM dataset.
#
# + dataset - The dataset to be encoded
# + transferSyntax - The transfer syntax to be used for the encoding 
# + encodeSorted - A boolean flag indicating whether to sort the dataset before encoding
# + return - The encoded dataset, or an `EncodingError` if the encoding fails
isolated function encodeDataset(Dataset dataset, TransferSyntax transferSyntax,
        boolean encodeSorted) returns byte[]|EncodingError {
    do {
        Dataset processingDataset = encodeSorted ? getSortedDataset(dataset) : dataset;
        byte[] datasetBytes = [];

        foreach DataElement dataElement in processingDataset {
            byte[] dataElementBytes = check encodeDataElement(dataElement, transferSyntax);
            datasetBytes.push(...dataElementBytes);
        }

        return datasetBytes;
    } on fail error e {
        return error EncodingError(string `Data set encoding failed: ${dataset.toString()}`, e);
    }
}

# Encodes a DICOM data element.
#
# + dataElement - The data element to be encoded
# + transferSyntax - The transfer syntax to be used for the encoding
# + return - The encoded data element, or an `EncodingError` if the encoding fails
isolated function encodeDataElement(DataElement dataElement,
        TransferSyntax transferSyntax) returns byte[]|EncodingError {
    do {
        byte[] dataElementBytes = [];

        // Determine the byte order
        ByteOrder byteOrder = getByteOrder(transferSyntax);

        // Encode Tag
        byte[] tagBytes = check encodeTag(dataElement.tag, byteOrder);
        dataElementBytes.push(...tagBytes);

        // Get VR and validate
        // Even if the transfer syntax is implicit, the VR is required to validate the value and its length
        Vr? vr = getDataElementVr(dataElement);
        if vr == () {
            fail error EncodingError("Could not determine the VR of the data element");
        }

        // Encode VR
        // Only encode VR if transfer syntax is explicit
        if isExplicitTransferSyntax(transferSyntax) {
            byte[] vrBytes = encodeVr(vr);
            dataElementBytes.push(...vrBytes);
        }

        // Value
        byte[] valueBytes = check encodeValue(vr, dataElement.value, byteOrder);

        // Value length
        byte[] vlBytes = check encodeVl(dataElement.tag, vr, valueBytes.length(), byteOrder);

        // Encode value length and value
        dataElementBytes.push(...vlBytes);
        dataElementBytes.push(...valueBytes);

        return dataElementBytes;
    } on fail error e {
        return error EncodingError(string `Data element encoding failed: ${dataElement.toString()}`, e);
    }
}

# Retrieves the VR of a data element. 
# If the VR is missing in the data element, attempts to fetch it from DICOM dictionaries.
#
# + dataElement - The data element
# + return - The `Vr` of the data element if found, or `()` if not found
isolated function getDataElementVr(DataElement dataElement) returns Vr? {
    if dataElement.vr != () {
        return dataElement.vr;
    }
    // Get the VR from TagInfo
    TagInfo? tagInfo = getTagInfo(dataElement.tag);
    return tagInfo is TagInfo ? tagInfo.vr : ();
}

# Encodes a DICOM tag.
#
# + tag - The tag to be encoded
# + byteOrder - The byte order to be used for encoding
# + return - The encoded tag, or an `EncodingError` if the encoding fails
isolated function encodeTag(Tag tag, ByteOrder byteOrder) returns byte[]|EncodingError {
    do {
        byte[] tagBytes = [];
        // Group number
        byte[] groupBytes = check encodeGroup(tag, byteOrder);
        tagBytes.push(...groupBytes);
        // Element number
        byte[] elementBytes = check encodeElement(tag, byteOrder);
        tagBytes.push(...elementBytes);
        return tagBytes;
    } on fail error e {
        return error EncodingError(string `Tag encoding failed: ${tag.toString()}`, e);
    }
}

# Encodes the group number of a tag.
#
# + tag - The tag
# + byteOrder - The byte order to be used for encoding
# + return - The encoded group number, or an `EncodingError` if the encoding fails
isolated function encodeGroup(Tag tag, ByteOrder byteOrder) returns byte[]|EncodingError {
    byte[]|error groupBytes = intToBytes(tag.group, byteOrder);
    if groupBytes is error {
        return error EncodingError(string `Failed to encode group number: ${tag.group}`, groupBytes);
    }
    return resizeNumericBytes(groupBytes, byteOrder, 2);
}

# Encodes the element number of a tag.
#
# + tag - The tag
# + byteOrder - The byte order to be used for encoding
# + return - The encoded element number, or an `EncodingError` if the encoding fails
isolated function encodeElement(Tag tag, ByteOrder byteOrder) returns byte[]|EncodingError {
    byte[]|error elementBytes = intToBytes(tag.element, byteOrder);
    if elementBytes is error {
        return error EncodingError(string `Failed to encode element number: ${tag.element}`, elementBytes);
    }
    return resizeNumericBytes(elementBytes, byteOrder, 2);
}

# Encodes a VR.
#
# + vr - The VR to be encoded
# + return - The encoded VR
isolated function encodeVr(Vr vr) returns byte[] => vr.toBytes();

# Encodes a VL.
#
# + tag - The tag of the data element
# + vr - The VR of the data element 
# + vl - The VL to encode
# + byteOrder - The byte order to be used for encoding
# + return - The encoded VL, or an `EncodingError` if the encoding fails
isolated function encodeVl(Tag tag, Vr vr, int vl, ByteOrder byteOrder) returns byte[]|EncodingError {
    byte[] vlBytes = [];
    // Undefined lengths may be used for Data Elements having the VR SQ and UN
    if vr == SQ || vr == UN {
        vlBytes = UNDEFINED_VL_BYTES;
    } else {
        // Encode value length
        byte[]|error intBytes = intToBytes(vl, byteOrder);
        if intBytes is error {
            return error EncodingError("VL encoding failed", intBytes);
        }
        vlBytes = intBytes;
    }
    int requiredVlBytesLength = getRequiredVlBytesLength(tag, vr);
    return resizeNumericBytes(vlBytes, byteOrder, requiredVlBytesLength);
}

# Encodes a data element value.
# The encoded value is also properly resized to achieve an even length.
#
# + vr - The VR of the data element  
# + value - The data element value to be encoded
# + byteOrder - The byte order to be used for the encoding
# + return - The encoded value, or an `EncodingError` if the encoding fails
isolated function encodeValue(Vr vr, DataElementValue value, ByteOrder byteOrder) returns byte[]|EncodingError {
    do {
        // Encode value
        byte[] valueBytes = check valueToBytes(value, byteOrder);
        // Resize to achieve an even length if not an empty value
        return valueBytes.length() == 0 ? valueBytes : resizeToEvenLengthValueBytes(vr, valueBytes, byteOrder);
    } on fail error e {
        return error EncodingError(string `Value encoding failed: ${value.toString()}`, e);
    }
}

# Converts a data element value to its bytes format.
#
# + value - The data element value to be converted 
# + byteOrder - The byte order to be used for the conversion
# + return - The converted value, or an `EncodingError` if the conversion fails
isolated function valueToBytes(DataElementValue value, ByteOrder byteOrder) returns byte[]|EncodingError {
    // TODO: Add 'SequenceItem' value to bytes encoding support
    // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1534
    do {
        if value is byte[] {
            return value;
        } else if value is string {
            return value.toBytes();
        } else if value is int {
            return check intToBytes(value, byteOrder);
        } else if value is float {
            return check floatToBytes(value, byteOrder);
        } else if value is Tag {
            return check encodeTag(value, byteOrder);
        } else if value == () { // Empty value
            return [];
        } else {
            return error EncodingError("Unsupported value type for conversion to bytes");
        }
    } on fail error e {
        return error EncodingError("Value to bytes conversion failed", e);
    }
}

# Resizes an encoded data element value to an even length.
#
# + vr - The VR of the data element
# + value - The encoded data element value to be resized
# + byteOrder - The byte order of the encoded value
# + return - The resized value, or an `EncodingError` if the resizing fails
isolated function resizeToEvenLengthValueBytes(Vr vr, byte[] value,
        ByteOrder byteOrder) returns byte[]|EncodingError {
    // Here we assume that the value length has been validated prior to this point, 
    // therefore, no validation is performed here
    if FIXED_LENGTH_VALUE_BYTES.hasKey(vr) {
        int requiredLength = FIXED_LENGTH_VALUE_BYTES.get(vr);
        return value.length() == requiredLength ? value : check resizeValueBytes(vr, value, requiredLength, byteOrder);
    } else if VARIABLE_LENGTH_VALUE_BYTES.hasKey(vr) {
        int requiredLength = getNearestUpperPowerOf2(value.length());
        return value.length() == requiredLength ? value : check resizeValueBytes(vr, value, requiredLength, byteOrder);
    }
    return error EncodingError("Unsupported value for resizing to even length");
}

# Resizes an encoded data element value depending on the encoded value type.
#
# + vr - The VR of the data element
# + value - The encoded value to be resized
# + newLength - The new desired length of the value
# + byteOrder - The byte order of the encoded value
# + return - The resized value, or an `EncodingError` if the resizing fails
isolated function resizeValueBytes(Vr vr, byte[] value, int newLength,
        ByteOrder byteOrder) returns byte[]|EncodingError {
    if STR_VRs.indexOf(vr) != () {
        return padStringValueBytes(vr, value, newLength);
    } else if INT_VRs.indexOf(vr) != () || FLOAT_VRs.indexOf(vr) != () {
        return resizeNumericBytes(value, byteOrder, newLength);
    }
    return error EncodingError("Unsupported value type for resizing");
}

# Pads an encoded string value.
#
# + vr - The VR of the encoded string value
# + value - The encoded string value to be resized
# + newLength - The desired new length for the encoded value
# + return - The padded encoded string value
isolated function padStringValueBytes(Vr vr, byte[] value, int newLength) returns byte[] {
    // VRs constructed of character strings, except in the case of the VR UI, shall be padded 
    // with SPACE characters (20H, in the Default Character Repertoire) when necessary to achieve even length.
    // Values with a VR of UI shall be padded with a single trailing NULL (00H)
    // Based off of Section 6.2 in Part 5
    if vr == UI {
        return [...value, NULL_BYTE];
    }
    int paddingLength = newLength - value.length();
    byte[] paddingSpaceBytes = constructSpaceBytes(paddingLength);
    return [...value, ...paddingSpaceBytes];
}

# Retrieves the required number of value length (VL) bytes length.
#
# + tag - The data element tag
# + vr - The data element VR
# + return - The required value length bytes length length
isolated function getRequiredVlBytesLength(Tag tag, Vr vr) returns int {
    // From Table 7.1-1, Table 7.1-2, and Table 7.1-3
    if isCommandTag(tag) {
        return 4;
    } else if EXPLICIT_LENGTH_16_VRs.indexOf(vr) != () {
        return 2;
    }
    return 4; // Explicit VR 32, Implicit VR or Undefined length
}
