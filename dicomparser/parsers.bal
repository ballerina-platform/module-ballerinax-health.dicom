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

import ballerina/io;
import ballerina/log;
import ballerinax/health.dicom;

# Parses a DICOM source.
#
# + 'source - The DICOM source to be parsed. It can be either a DICOM file, or an encoded DICOM dataset.
# + transferSyntax - The transfer syntax of the source
# + metaElementsOnly - A flag indicating whether to stop parsing after reading the file meta information 
# + ignorePixelData - A flag indicating whether to skip reading the pixel data
# + return - A `dicom:File` if the source is a DICOM file, a `dicom:Dataset` if the source is an encoded dataset, 
# or a `dicom:ParsingError` if parsing fails
public isolated function parse(string|byte[] 'source, dicom:TransferSyntax transferSyntax,
        boolean metaElementsOnly = false, boolean ignorePixelData = false)
        returns dicom:File|dicom:Dataset|dicom:ParsingError {
    do {
        if 'source is string { // File path
            return check parseFile('source, transferSyntax, metaElementsOnly, ignorePixelData);
        } else { // Encoded dataset
            return check parseDataset(check io:createReadableChannel('source), transferSyntax,
                    metaElementsOnly, ignorePixelData);
        }
    } on fail error e {
        return error dicom:ParsingError("Parsing failed", e);
    }
}

# Parses a DICOM File.
#
# + filePath - The path of the DICOM file to be parsed
# + transferSyntax - The transfer syntax of the DICOM file
# + metaElementsOnly - A flag indicating whether to stop parsing after reading the file meta information
# + ignorePixelData - A flag indicating whether to skip loading the pixel data during parsing
# + return - The parsed `dicom:File`, or a `dicom:ParsingError` if the parsing fails.
public isolated function parseFile(string filePath, dicom:TransferSyntax transferSyntax,
        boolean metaElementsOnly = false, boolean ignorePixelData = false) returns dicom:File|dicom:ParsingError {
    do {
        if !isSupportedTransferSyntax(transferSyntax) {
            fail error dicom:ParsingError(string `Unsupported transfer syntax: ${transferSyntax}`);
        }

        // Open a readable byte channel to the file
        io:ReadableByteChannel fileByteChannel = check io:openReadableFile(filePath);

        // Read preamble
        byte[] preamble = check readPreamble(fileByteChannel);

        // Check if a valid DICOM file
        if !isValidFile(fileByteChannel, true) {
            fail error dicom:ParsingError("Not a valid DICOM file");
        }

        // Parse dataset
        // After reading the preamble and prefix validation, the remaining bytes in the channel contains the dataset
        dicom:Dataset dataset = check parseDataset(fileByteChannel, transferSyntax, metaElementsOnly, ignorePixelData);

        return {preamble, dataset};
    } on fail error e {
        return error dicom:ParsingError(string `File parsing failed: ${filePath}`, e);
    }
}

# Parses a DICOM Data Set.
#
# + 'source - The source of the dataset to be parsed
# + transferSyntax - The transfer syntax of the DICOM dataset 
# + metaElementsOnly - A flag indicating whether to stop parsing after reading the file meta information
# + ignorePixelData - A flag indicating whether to skip loading the pixel data during parsing
# + return - The parsed `dicom:Dataset`, or a `dicom:ParsingError` if the parsing fails.
public isolated function parseDataset(byte[]|io:ReadableByteChannel 'source, dicom:TransferSyntax transferSyntax,
        boolean metaElementsOnly = false, boolean ignorePixelData = false) returns dicom:Dataset|dicom:ParsingError {
    do {
        if !isSupportedTransferSyntax(transferSyntax) {
            fail error dicom:ParsingError(string `Unsupported transfer syntax: ${transferSyntax}`);
        }

        io:ReadableByteChannel datasetByteChannel;

        if 'source is byte[] {
            datasetByteChannel = check io:createReadableChannel('source);
        } else { // io:ReadableByteChannel
            datasetByteChannel = 'source;
        }

        // DICOM dataset
        dicom:Dataset dataset = table [];

        dicom:ByteOrder byteOrder = dicom:getByteOrder(transferSyntax);

        // Keep track of the most recent private creator ID in order to read the private data blocks
        string privateCreatorId = "";

        while true {
            // Read 8 bytes at a time:
            // - For Explicit VR with a 32-bit length, this covers: tag + VR
            // - For Explicit VR with a 16-bit length, this covers: tag + VR + VL
            // - For Implicit VR, this covers: tag + VL
            // Based off of Table 7.1-1, 7.1-2 and 7.1-3 in Part 5
            byte[]|io:Error bytesRead = datasetByteChannel.read(8);

            if bytesRead is io:Error {
                fail error dicom:ParsingError("Failed to read bytes", bytesRead);
            }

            // End of dataset channel check
            if bytesRead.length() < 8 {
                return dataset;
            }

            // Byte channel to source read bytes
            io:ReadableByteChannel bytesReadByteChannel = check io:createReadableChannel(bytesRead);

            // Tag
            dicom:Tag tag = check parseTag(check bytesReadByteChannel.read(4), byteOrder);

            // Check if an item delimitation tag
            // This means currently parsing an item value data set of a sequence (SQ)
            // and marks the end of an item of the sequence
            if tag == dicom:ITEM_DELIMITER_TAG {
                return dataset;
            }

            // Check stop condition metaElementsOnly
            // Parse only the file meta information elements
            // From Section 7.1 in Part 10
            if metaElementsOnly && !dicom:isFileMetaInfoTag(tag) {
                return dataset;
            }

            // Check stop condition ignorePixelData
            if ignorePixelData && dicom:isPixelDataTag(tag) {
                return dataset;
            }

            // VR
            dicom:Vr vr = check parseVr(check bytesReadByteChannel.read(2));

            // VL
            int vl = check parseVl(check bytesReadByteChannel.read(2), byteOrder);
            // Check if the VR is an explicit VR with a 32-bit length
            if dicom:EXPLICIT_LENGTH_32_VRs.indexOf(vr) != () {
                vl = check parseVl(check datasetByteChannel.read(4), byteOrder);
            }

            // Value
            dicom:DataElementValue value;

            // Check if a sequence
            if vr == dicom:SQ {
                // TODO: Add support for explicit length SQ data element parsing
                // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1524
                value = check parseSequenceValue(datasetByteChannel, transferSyntax);
            } else {
                // If a PixelData tag, the value length is undefined, therefore read everything that's left in the byte
                // channel
                // byte[] valueBytes = dicom:isPixelDataTag(tag) ? check datasetByteChannel.readAll() : 
                byte[] valueBytes;
                if dicom:isPixelDataTag(tag) {
                    valueBytes = check datasetByteChannel.readAll();
                } else {
                    valueBytes = vl == 0 ? [] : check datasetByteChannel.read(vl);
                }
                value = check parseValue(vr, valueBytes, byteOrder);
            }

            // Get tag information from the dictionaries
            boolean isPrivate = dicom:isPrivateTag(tag);
            boolean isPrivateCreator = dicom:isPrivateCreatorTag(tag);

            dicom:TagInfo? matchingTagInfo = ();

            if isPrivateCreator {
                matchingTagInfo = {...PRIVATE_CREATOR_TAG_INFO};
                privateCreatorId = check value.ensureType();
            } else if isPrivate {
                matchingTagInfo = dicom:getPrivateTagInfo(tag, privateCreatorId);
            } else { // Standard or Repeating
                matchingTagInfo = dicom:getTagInfo(tag);
            }

            // If a matching TagInfo is not found, use an empty TagInfo
            dicom:TagInfo tagInfo = matchingTagInfo ?: {...EMPTY_TAG_INFO};

            // Check if there's a VR mismatch between the parsed VR and the VR from dicom dictionaries
            // Use the parsed VR in case of a mismatch as tag dictionaries could be outdated
            if !dicom:isPrivateCreatorTag(tag) && vr != tagInfo.vr {
                log:printWarn(string `VR mismatch for tag: ${dicom:tagToStr(tag)}. ` +
                        string `Using parsed VR instead of the one in the dictionary.`,
                        parsedVr = vr, dictVr = tagInfo.vr);
                tagInfo.vr = vr;
            }

            // Construct data element
            dicom:DataElement de = {
                tag: tag,
                vr: tagInfo.vr,
                vl: vl,
                value: value
            };

            // Add data element to dataset
            dataset.put(de);
        }
    } on fail error e {
        return error dicom:ParsingError("Data set parsing failed", e);
    }
}

# Parses a DICOM Tag.
#
# + tagBytes - The byte array containing the encoded DICOM Tag 
# + byteOrder - The byte order used in the byte array
# + return - The parsed `dicom:Tag`, or a `dicom:ParsingError` if the parsing fails.
public isolated function parseTag(byte[] tagBytes, dicom:ByteOrder byteOrder) returns dicom:Tag|dicom:ParsingError {
    do {
        // Tag must 4 bytes in length
        if tagBytes.length() != 4 {
            fail error dicom:ParsingError("Tag bytes must be of length 4");
        }
        int:Unsigned16 group = check dicom:bytesToInt(tagBytes.slice(0, 2), byteOrder).ensureType();
        int:Unsigned16 element = check dicom:bytesToInt(tagBytes.slice(2), byteOrder).ensureType();
        return {group, element};
    } on fail error e {
        return error dicom:ParsingError(string `Tag parsing failed: ${tagBytes.toString()}`, e);
    }
}

# Parses a DICOM Value Representation (VR).
#
# + vrBytes - The byte array containing the encoded VR
# + return - The respective `dicom:VR`, or a `dicom:ParsingError` if the parsing fails.
public isolated function parseVr(byte[] vrBytes) returns dicom:Vr|dicom:ParsingError {
    do {
        // VR must be 2 bytes in length
        if vrBytes.length() != 2 {
            fail error("VR bytes must be of length 2");
        }
        return check string:fromBytes(vrBytes).ensureType();
    } on fail error e {
        return error dicom:ParsingError(string `VR parsing failed: ${vrBytes.toString()}`, e);
    }
}

# Parses a DICOM Value Length (VL).
#
# + vlBytes - The byte array containing the encoded VL
# + byteOrder - The byte order used in the byte array
# + return - The `int` representation of the VL, or a `dicom:ParsingError` if the parsing fails.
public isolated function parseVl(byte[] vlBytes, dicom:ByteOrder byteOrder) returns int|dicom:ParsingError {
    do {
        // VL must be either 2 or 4 bytes in length
        if vlBytes.length() != 2 && vlBytes.length() != 4 {
            fail error("VL bytes must be of length 2 or 4");
        }
        return check dicom:bytesToInt(vlBytes, byteOrder);
    } on fail error e {
        return error dicom:ParsingError(string `VL parsing failed: ${vlBytes.toString()}`, e);
    }
}

# Parses a DICOM data element value.
#
# + vr - The Value Representation (VR) of the data element
# + valueBytes - The byte array containing the encoded data element value
# + byteOrder - The byte order used in the byte array
# + return - A `dicom:DataElementValue` if the parsing is successful, or a `dicom:ParsingError` if the parsing fails
public isolated function parseValue(dicom:Vr vr, byte[] valueBytes,
        dicom:ByteOrder byteOrder) returns dicom:DataElementValue|dicom:ParsingError {
    // TODO: Add proper parsing support for multi-valued data elements
    // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1544
    do {
        // Value parsing logic is based off of Table 6.2-1 in Part 5
        dicom:DataElementValue value = ();

        if valueBytes.length() == 0 { // Empty value
            return value;
        }

        // If the VR value has a fixed length, and that value length is not respected, log a warning
        // In this case, use raw value bytes without parsing
        // NOTE: This VL discrepancy maybe due to data element having multiple values, therefore, should
        // be revisited when multi-valued data element parsing support is added
        if dicom:FIXED_LENGTH_VALUE_BYTES.hasKey(vr) &&
                    (dicom:FIXED_LENGTH_VALUE_BYTES.get(vr) != valueBytes.length()) {
            log:printWarn(string `Mismatch in value length for VR ${vr}:` +
            string ` expected: ${dicom:FIXED_LENGTH_VALUE_BYTES.get(vr)}, found: ${valueBytes.length()}. ` +
            string `Using raw bytes as value, parsed value may not be accurate.`, value = valueBytes);
            value = valueBytes;
            return value;
        }

        if vr == dicom:AT {
            // AT is an ordered pair of 16-bit unsigned integers that is the value of a data element tag
            value = check parseTag(valueBytes, byteOrder);
        } else if dicom:isBytesVr(vr) {
            value = valueBytes;
        } else if dicom:isFloatVr(vr) {
            value = check dicom:bytesToFloat(valueBytes, byteOrder);
        } else if dicom:isIntVr(vr) {
            value = check dicom:bytesToInt(valueBytes, byteOrder);
        } else if dicom:isStringVr(vr) {
            value = check string:fromBytes(valueBytes);
        }

        // If the value is of string type
        // Remove leading and trailing spaces
        if value is string {
            value = value.trim();
        }

        return value;
    } on fail error e {
        return error dicom:ParsingError(string `Value parsing failed: ${valueBytes.toString()}`, e);
    }
}

# Parses a DICOM sequence value.
#
# + 'source - The source of the sequence value to be parsed
# + transferSyntax - The transfer syntax of the sequence data
# + return - A `dicom:SequenceValue` if the parsing is successful, or a `dicom:ParsingError` if the parsing fails
public isolated function parseSequenceValue(byte[]|io:ReadableByteChannel 'source,
        dicom:TransferSyntax transferSyntax) returns dicom:SequenceValue|dicom:ParsingError {
    // TODO: Add support for explicit length item parsing.
    // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1543
    do {
        if !isSupportedTransferSyntax(transferSyntax) {
            fail error(string `Unsupported transfer syntax: ${transferSyntax}`);
        }

        io:ReadableByteChannel sequenceByteChannel;

        if 'source is byte[] {
            sequenceByteChannel = check io:createReadableChannel('source);
        } else { // io:ReadableByteChannel
            sequenceByteChannel = 'source;
        }

        // Sequence parsing logic is based off of Section 7.5 in Part 5
        // Sequence data element value (items) dataset
        dicom:SequenceValue sequence = table [];
        dicom:ByteOrder byteOrder = dicom:getByteOrder(transferSyntax);

        while true {
            // Item tag
            byte[]|io:Error itemTagBytes = sequenceByteChannel.read(4);
            if itemTagBytes is io:Error {
                fail error dicom:ParsingError("Failed to read item tag", itemTagBytes);
            }
            dicom:Tag itemTag = check parseTag(itemTagBytes, byteOrder);

            // Item length
            byte[]|io:Error itemLengthBytes = sequenceByteChannel.read(4);
            if itemLengthBytes is io:Error {
                fail error dicom:ParsingError("Failed to read item length", itemLengthBytes);
            }
            int itemLength = check parseVl(itemLengthBytes, byteOrder);
            
            // IMPORTANT: THE FOLLOWING CHECKS MUST COME AFTER READING THE ITEM LENGTH, OTHERWISE BYTE READING 
            // POSITION WILL BE MISALIGNED, RESULTING IN INCORRECT PARSING FROM THIS POINT FORWARD
            // Check if a sequence delimitation item
            // This marks the end of a sequence of undefined length
            if itemTag == dicom:SEQUENCE_DELIMITER_TAG {
                return sequence;
            } else if itemTag != dicom:ITEM_TAG { // Tag must be an item tag or a sequence delimiter tag
                fail error dicom:ParsingError(string `Invalid item tag: ${dicom:tagToStr(itemTag)}`);
            }

            // Read item value Dataset
            dicom:Dataset itemValueDataset = check parseDataset(sequenceByteChannel, transferSyntax);

            dicom:SequenceItem sequenceItem = {tag: itemTag, length: itemLength, valueDataset: itemValueDataset};
            sequence.put(sequenceItem);
        }
    } on fail error e {
        return error dicom:ParsingError("Sequence value parsing failed", e);
    }
}
