isolated function encodeDataset(Dataset dataset, TransferSyntax transferSyntax,
        boolean encodeSorted) returns byte[]|EncodingError {
    Dataset encodingDataset = dataset;
    do {
        byte[] datasetBytes = [];

        if encodeSorted {
            Dataset sortedDataset = getSortedDataset(dataset);
            encodingDataset = sortedDataset;
        }

        foreach DataElement dataElement in encodingDataset {
            byte[] dataElementBytes = check encodeDataElement(dataElement, transferSyntax);
            datasetBytes.push(...dataElementBytes);
        }

        return datasetBytes;
    } on fail error e {
        return error EncodingError(string `Data set encoding failed: ${dataset.toString()}`, e);
    }
}

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
        byte[] vlBytes = check encodeVl(vr, valueBytes.length(), byteOrder);

        // Encode value length and value
        dataElementBytes.push(...vlBytes);
        dataElementBytes.push(...valueBytes);

        return dataElementBytes;
    } on fail error e {
        return error EncodingError(string `Data element encoding failed: ${dataElement.toString()}`, e);
    }
}

isolated function getDataElementVr(DataElement dataElement) returns Vr? {
    Vr? vr = dataElement.vr;
    if vr == () {
        // Get the VR from TagInfo
        // TODO: Add private data element support
        TagInfo? tagInfo = getStandardTagInfo(dataElement.tag) ?: getRepeatingTagInfo(dataElement.tag);
        if tagInfo is TagInfo {
            vr = tagInfo.vr;
        }
    }
    return vr;
}

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

isolated function encodeGroup(Tag tag, ByteOrder byteOrder) returns byte[]|EncodingError {
    byte[]|error groupBytes = intToBytes(tag.group, byteOrder);
    if groupBytes is error {
        return error EncodingError(string `Failed to encode group number: ${tag.group}`, groupBytes);
    }
    return resizeNumericBytes(groupBytes, byteOrder, 2);
}

isolated function encodeElement(Tag tag, ByteOrder byteOrder) returns byte[]|EncodingError {
    byte[]|error elementBytes = intToBytes(tag.element, byteOrder);
    if elementBytes is error {
        return error EncodingError(string `Failed to encode element number: ${tag.element}`, elementBytes);
    }
    return resizeNumericBytes(elementBytes, byteOrder, 2);
}

isolated function encodeVr(Vr vr) returns byte[] => vr.toBytes();

isolated function encodeVl(Vr vr, int vl, ByteOrder byteOrder) returns byte[]|EncodingError {
    byte[] vlBytes = [];
    // Undefined lengths may be used for Data Elements having the VR SQ and UN
    // TODO: For OW or OB Undefined Length may be used depending on the negotiated Transfer Syntax
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
    int requiredVlBytesLength = getRequiredVlBytesLength(vr);
    return resizeNumericBytes(vlBytes, byteOrder, requiredVlBytesLength);
}

isolated function encodeValue(Vr vr, DataElementValue value, ByteOrder byteOrder) returns byte[]|EncodingError {
    do {
        // Encode value
        byte[] valueBytes = check valueToBytes(value, byteOrder);
        // Resize to achieve an even length
        return check resizeToEvenLengthValueBytes(vr, valueBytes, byteOrder);
    } on fail error e {
        return error EncodingError(string `Value encoding failed: ${value.toString()}`, e);
    }
}

isolated function valueToBytes(DataElementValue value, ByteOrder byteOrder) returns byte[]|EncodingError {
    // TODO: Add missing types support
    do {
        if value is byte[] {
            return value;
        } else if value is string {
            return value.toBytes();
        } else if value is int {
            return check intToBytes(value, byteOrder);
        } else if value is float {
            return check floatToBytes(value, byteOrder);
        } else {
            return error EncodingError("Unsupported value type for conversion to bytes");
        }
    } on fail error e {
        return error EncodingError("Value to bytes conversion failed", e);
    }
}

isolated function resizeToEvenLengthValueBytes(Vr vr, byte[] value,
        ByteOrder byteOrder) returns byte[]|EncodingError {
    if FIXED_LENGTH_VALUE_BYTES.hasKey(vr) {
        return resizeFixedLengthValueBytes(vr, value, byteOrder);
    } else if VARIABLE_LENGTH_VALUE_BYTES.hasKey(vr) {
        return resizeVariableLengthValueBytes(vr, value, byteOrder);
    }
    return error EncodingError("Unsupported value for resizing to even length");
}

isolated function resizeFixedLengthValueBytes(Vr vr, byte[] value,
        ByteOrder byteOrder) returns byte[]|EncodingError {
    int requiredLength = FIXED_LENGTH_VALUE_BYTES.get(vr);
    return value.length() == requiredLength ? value : check resizeValueBytes(vr, value, requiredLength, byteOrder);
}

isolated function resizeVariableLengthValueBytes(Vr vr, byte[] value,
        ByteOrder byteOrder) returns byte[]|EncodingError {
    int requiredLength = getNearestUpperPowerOf2(value.length());
    return value.length() == requiredLength ? value : check resizeValueBytes(vr, value, requiredLength, byteOrder);
}

isolated function resizeValueBytes(Vr vr, byte[] value, int newLength,
        ByteOrder byteOrder) returns byte[]|EncodingError {
    if STR_VRs.indexOf(vr) != () {
        return padStringValueBytes(value, newLength);
    } else if INT_VRs.indexOf(vr) != () || FLOAT_VRs.indexOf(vr) != () {
        return resizeNumericBytes(value, byteOrder, newLength);
    }
    return error EncodingError("Unsupported value type for resizing");
}

isolated function padStringValueBytes(byte[] value, int newLength) returns byte[] {
    // VRs constructed of character strings, except in the case of the VR UI, shall be padded 
    // with SPACE characters (20H, in the Default Character Repertoire) when necessary to achieve even length.
    // Section 6.2 in Part 5
    int paddingLength = newLength - value.length();
    byte[] paddingSpaceBytes = constructSpaceBytes(paddingLength);
    return [...value, ...paddingSpaceBytes];
}

isolated function constructSpaceBytes(int length) returns byte[] {
    byte[] spaceBytes = [];
    while spaceBytes.length() < length {
        spaceBytes.push(SPACE_BYTE);
    }
    return spaceBytes;
}

isolated function padNumericValueBytes(byte[] value, int newLength, ByteOrder byteOrder) returns byte[]
    => padNumericBytes(value, byteOrder, newLength);

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

isolated function getRequiredVlBytesLength(Vr vr) returns int {
    // From Table 7.1-1, Table 7.1-2, and Table 7.1-3
    if EXPLICIT_LENGTH_16_VRs.indexOf(vr) != () {
        return 2;
    }
    return 4; // Explicit VR 32, Implicit VR or Undefined length
}

isolated function getSortedDataset(Dataset dataset) returns Dataset {
    return <Dataset>from DataElement dataElement in dataset
        order by dataElement.tag.group ascending, dataElement.tag.element ascending
        select dataElement;
}
