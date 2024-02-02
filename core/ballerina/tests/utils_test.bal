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

import ballerina/test;

@test:Config {groups: ["utils"]}
function recordToDatasetValidRecordTest() {
    record {} datasetRecord = {
        "StudyDate": "19900220",
        "PatientAge": "030Y",
        "SamplesPerPixel": 1
    };
    Dataset dataset = table [
        {"tag": {"group": 8, "element": 32}, "vr": "DA", "value": "19900220"},
        {"tag": {"group": 16, "element": 4112}, "vr": "AS", "value": "030Y"},
        {"tag": {"group": 40, "element": 2}, "vr": "US", "value": 1}
    ];
    test:assertEquals(recordToDataset(datasetRecord, EXPLICIT_VR_LITTLE_ENDIAN), dataset);
}

@test:Config {groups: ["utils"]}
function recordToDatasetInvalidRecordTest() {
    record {} datasetRecord = {
        "StudyDate": "19900220",
        "PatientAge": 20, // Invalid PatientAge data type
        "SamplesPerPixel": 1
    };
    test:assertTrue(recordToDataset(datasetRecord, EXPLICIT_VR_LITTLE_ENDIAN) is Error);
}

@test:Config {groups: ["utils"]}
function isExplicitTransferSyntaxExplicitTest() {
    test:assertTrue(isExplicitTransferSyntax(EXPLICIT_VR_BIG_ENDIAN));
    test:assertTrue(isExplicitTransferSyntax(EXPLICIT_VR_LITTLE_ENDIAN));
}

@test:Config {groups: ["utils"]}
function isExplicitTransferSyntaxImplicitTest() {
    test:assertFalse(isExplicitTransferSyntax(IMPLICIT_VR_LITTLE_ENDIAN));
}

@test:Config {groups: ["utils"]}
function isValidTagStrValidTest() {
    test:assertTrue(isValidTagStr("00100010"));
    test:assertTrue(isValidTagStr("0020000D"));
}

@test:Config {groups: ["utils"]}
function isValidTagStrInvalidTest() {
    test:assertFalse(isValidTagStr("12345678"));
    test:assertFalse(isValidTagStr("ABCDEFGH"));
    test:assertFalse(isValidTagStr(""));
}

@test:Config {groups: ["utils"]}
function isValidTagStandardTagTest() {
    Tag standardTag = {group: 0x0010, element: 0x0010};
    test:assertTrue(isValidTag(standardTag));
}

@test:Config {groups: ["utils"]}
function isValidTagRepeatingTagTest() {
    Tag repeatingTag = {group: 0x6000, element: 0x0010};
    test:assertTrue(isValidTag(repeatingTag));
}

@test:Config {groups: ["utils"]}
function isValidTagInvalidTagTest() {
    Tag invalidTag = {group: 0xFFFF, element: 0xFFFF};
    test:assertFalse(isValidTag(invalidTag));
}

@test:Config {groups: ["utils"]}
function isValidKeywordValidKeywordTest() {
    test:assertTrue(isValidKeyword("PatientName"));
    test:assertTrue(isValidKeyword("StudyDate"));
    test:assertTrue(isValidKeyword("SeriesTime"));
}

@test:Config {groups: ["utils"]}
function isValidKeywordInvalidKeywordTest() {
    test:assertFalse(isValidKeyword("InvalidKeyword"));
    test:assertFalse(isValidKeyword("NotAKeyword"));
    test:assertFalse(isValidKeyword("12345678"));
}

@test:Config {groups: ["utils"]}
function isPrivateTagPrivateTest() {
    Tag privateTag = {group: 0x0009, element: 0x1002};
    test:assertTrue(isPrivateTag(privateTag));
}

@test:Config {groups: ["utils"]}
function isPrivateTagNonPrivateTest() {
    Tag nonPrivateTag = {group: 0x0010, element: 0x0010};
    test:assertFalse(isPrivateTag(nonPrivateTag));
}

@test:Config {groups: ["utils"]}
function isPrivateCreatorTagValidPrivateCreatorTagsTest() {
    // Valid private creator tags
    Tag[] privateCreatorTags = [
        {group: 0x0009, element: 0x0010},
        {group: 0x0019, element: 0x0010},
        {group: 0x0029, element: 0x0010},
        {group: 0x0037, element: 0x0010}
    ];
    foreach Tag tag in privateCreatorTags {
        test:assertTrue(isPrivateCreatorTag(tag));
    }
}

@test:Config {groups: ["utils"]}
function isPrivateCreatorTagInvalidPrivateCreatorTagsTest() {
    Tag[] invalidPrivateCreatorTags = [
        {group: 0x0002, element: 0x0000},
        {group: 0x0010, element: 0x0010},
        {group: 0x0009, element: 0x1002},
        {group: 0x0029, element: 0x1000}
    ];
    foreach Tag tag in invalidPrivateCreatorTags {
        test:assertFalse(isPrivateCreatorTag(tag));
    }
}

@test:Config {groups: ["utils"]}
function isFileMetaInfoTagValidFileMetaInfoTagsTest() {
    Tag[] fileMetaInfoTags = [
        {group: 0x0002, element: 0x0000},
        {group: 0x0002, element: 0x0001},
        {group: 0x0002, element: 0x0002},
        {group: 0x0002, element: 0x0003},
        {group: 0x0002, element: 0x0010},
        {group: 0x0002, element: 0x0012},
        {group: 0x0002, element: 0x0013},
        {group: 0x0002, element: 0x0016},
        {group: 0x0002, element: 0x0017},
        {group: 0x0002, element: 0x0018},
        {group: 0x0002, element: 0x0026},
        {group: 0x0002, element: 0x0027},
        {group: 0x0002, element: 0x0028},
        {group: 0x0002, element: 0x0100},
        {group: 0x0002, element: 0x0102}
    ];
    foreach Tag tag in fileMetaInfoTags {
        test:assertTrue(isFileMetaInfoTag(tag));
    }
}

@test:Config {groups: ["utils"]}
function isFileMetaInfoTagInvalidFileMetaInfoTagsTest() {
    Tag[] invalidFileMetaInfoTags = [
        {group: 0x0005, element: 0x0000},
        {group: 0x0010, element: 0x0010},
        {group: 0x0009, element: 0x1002},
        {group: 0x0029, element: 0x1000}
    ];
    foreach Tag tag in invalidFileMetaInfoTags {
        test:assertFalse(isFileMetaInfoTag(tag));
    }
}

@test:Config {groups: ["utils"]}
function getTagFromKeywordValidStandardKeywordsTest() {
    // Valid keywords and their tags
    map<Tag> tagsAndKeywords = {
        "PatientName": {group: 0x0010, element: 0x0010},
        "StudyDate": {group: 0x0008, element: 0x0020},
        "FrameTime": {group: 0x0018, element: 0x1063}
    };
    foreach [string, Tag] [keyword, tag] in tagsAndKeywords.entries() {
        test:assertEquals(getTagFromKeyword(keyword), tag);
    }
}

@test:Config {groups: ["utils"]}
function getTagFromKeywordInvalidStandardKeywordsTest() {
    string[] invalidKeywords = ["NotAProperKeyword", "AmorFati", "ArchBTW"];
    foreach string keyword in invalidKeywords {
        test:assertEquals(getTagFromKeyword(keyword), ());
    }
}

@test:Config {groups: ["utils"]}
function getDataElementFromKeywordExistingKeywordTest() {
    Dataset dataset = table [
        {tag: {group: 0x0010, element: 0x0010}, vr: PN, value: "JOHN DOE"}, // PatientName
        {tag: {group: 0x0010, element: 0x0020}, vr: LO, value: "333-292-73-8"} // PatientID
    ];
    DataElement? patientIdDataElement = getDataElementFromKeyword(dataset, "PatientID");
    test:assertEquals(patientIdDataElement, dataset.get({group: 0x0010, element: 0x0020}));
}

@test:Config {groups: ["utils"]}
function getDataElementFromKeywordNonExistingKeywordTest() {
    Dataset dataset = table [
        {tag: {group: 0x0010, element: 0x0010}, vr: PN, value: "JOHN DOE"} // PatientName
    ];
    DataElement? patientIdDataElement = getDataElementFromKeyword(dataset, "PatientID");
    test:assertEquals(patientIdDataElement, ());
}

@test:Config {groups: ["utils"]}
function getTagInfoValidStandardTagTest() {
    Tag patientNameTag = {group: 0x0010, element: 0x0010};
    TagInfo patientNameTagInfo = {
        "vr": "PN",
        "vm": "1",
        "name": "Patient's Name",
        "retired": "",
        "keyword": "PatientName"
    };
    test:assertEquals(getTagInfo(patientNameTag), patientNameTagInfo);
}

@test:Config {groups: ["utils"]}
function getTagInfoValidRepeatingTagTest() {
    Tag curveDimensionsTag = {group: 0x5000, element: 0x0005};
    TagInfo curveDimensionsTagInfo = {
        "vr": "US",
        "vm": "1",
        "name": "Curve Dimensions",
        "retired": "Retired",
        "keyword": "CurveDimensions"
    };
    test:assertEquals(getTagInfo(curveDimensionsTag), curveDimensionsTagInfo);
}

@test:Config {groups: ["utils"]}
function getTagInfoInvalidTagTest() {
    Tag invalidTag = {group: 0xffff, element: 0x0010};
    test:assertEquals(getTagInfo(invalidTag), ());
}

@test:Config {groups: ["utils"]}
function getPrivateTagInfoTest() {
    Tag privateDataElementTag = {group: 0x0019, element: 0x1030}; // MaximumFrameSize
    TagInfo privateDataElementTagIno = {
        "vr": "UL",
        "vm": "1",
        "name": "Maximum Frame Size",
        "retired": "",
        "keyword": "MaximumFrameSize"
    };
    string privateCreator = "CARDIO-D.R. 1.0";
    TagInfo? privateTagInfo = getPrivateTagInfo(privateDataElementTag, privateCreator);
    test:assertEquals(privateTagInfo, privateDataElementTagIno);
}

@test:Config {groups: ["utils"]}
function validateValidDatasetTest() {
    Dataset dataset = table [
        {tag: {group: 0x0008, element: 0x0020}, vr: DA, value: "19970815"}, // StudyDate
        {tag: {group: 0x0010, element: 0x1010}, vr: AS, value: "020Y"}, // PatientAge
        {tag: {group: 0x0028, element: 0x0002}, vr: US, value: 1} // SamplesPerPixel
    ];
    ValidationError? validationRes = validate(dataset, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertEquals(validationRes, ());
}

@test:Config {groups: ["utils"]}
function validateInvalidDatasetTest() {
    Dataset invalidDataset = table [
        {tag: {group: 0x0008, element: 0x0020}, vr: DA, value: 19970815}, // Invalid StudyDate value type
        {tag: {group: 0x0010, element: 0x1010}, vr: AS, value: "020Y"}, // PatientAge
        {tag: {group: 0x0028, element: 0x0002}, vr: US, value: 1} // SamplesPerPixel
    ];
    ValidationError? validationRes = validate(invalidDataset, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertTrue(validationRes is ValidationError);
}

@test:Config {groups: ["utils"]}
function validateValidDataElementTest() {
    DataElement dataElement = {
        tag: {group: 0x0008, element: 0x0020},
        vr: DA,
        value: "19970815"
    };
    ValidationError? validationRes = validate(dataElement, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertEquals(validationRes, ());
}

@test:Config {groups: ["utils"]}
function validateInvalidDataElementInvalidValueFormatTest() {
    DataElement invalidDataElement = {
        tag: {group: 0x0008, element: 0x0020},
        vr: DA,
        value: "15081997" // Invalid value format for VR DA
    };
    ValidationError? validationRes = validate(invalidDataElement, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertTrue(validationRes is ValidationError);
}

@test:Config {groups: ["utils"]}
function validateInvalidDataElementInvalidValueCharsetTest() {
    DataElement invalidDataElement = {
        tag: {group: 0x0008, element: 0x0020},
        vr: DA,
        value: "ABCDEFGH" // Invalid value charset for VR DA
    };
    ValidationError? validationRes = validate(invalidDataElement, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertTrue(validationRes is ValidationError);
}

@test:Config {groups: ["utils"]}
function validateInvalidDataElementInvalidValueLengthVariableTest() {
    DataElement invalidDataElement = {
        tag: {group: 0x0002, element: 0x0016},
        vr: AE,
        value: "CCCCCCCCCCCCCCCCC" // Invalid length, max allowed value length is 16 for VR AE
    };
    ValidationError? validationRes = validate(invalidDataElement, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertTrue(validationRes is ValidationError);
}

@test:Config {groups: ["utils"]}
function validateInvalidDataElementInvalidValueLengthFixedTest() {
    DataElement invalidDataElement = {
        tag: {group: 0x0008, element: 0x0020},
        vr: DA,
        value: "1997081534355" // Invalid value length, max allowed value length is 8 for VR DA
    };
    ValidationError? validationRes = validate(invalidDataElement, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertTrue(validationRes is ValidationError);
}

@test:Config {groups: ["utils"]}
function validateValidTagTest() {
    Tag tag = {group: 0x0008, element: 0x0020}; // StudyDate
    ValidationError? validationRes = validate(tag, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertEquals(validationRes, ());
}

@test:Config {groups: ["utils"]}
function validateInvalidTagTest() {
    Tag invalidTag = {group: 0xFFFF, element: 0xFFFF};
    ValidationError? validationRes = validate(invalidTag, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertTrue(validationRes is ValidationError);
}

@test:Config {groups: ["utils"]}
function toBytesValidTagExplicitLittleTest() {
    Tag tag = {group: 0x0008, element: 0x0020}; // StudyDate
    byte[] explicitLittleTagBytes = [8, 0, 32, 0];
    byte[]|EncodingError bytes = toBytes(tag, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertEquals(bytes, explicitLittleTagBytes);
}

@test:Config {groups: ["utils"]}
function toBytesValidTagExplicitBigTest() {
    Tag tag = {group: 0x0008, element: 0x0020}; // StudyDate
    byte[] explicitBigTagBytes = [0, 8, 0, 32];
    byte[]|EncodingError bytes = toBytes(tag, EXPLICIT_VR_BIG_ENDIAN);
    test:assertEquals(bytes, explicitBigTagBytes);
}

@test:Config {groups: ["utils"]}
function toBytesInvalidTagTest() {
    Tag invalidTag = {group: 0x0000, element: 0xFFFF};
    byte[]|EncodingError bytes = toBytes(invalidTag, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertTrue(bytes is EncodingError);
}

@test:Config {groups: ["utils"]}
function toBytesValidDataElementExplicitLittleTest() {
    // StudyDate Data Element
    DataElement dataElement = {
        tag: {group: 0x0008, element: 0x0020},
        vr: DA,
        value: "19970815"
    };
    byte[] explicitLittleDataElementBytes = [8, 0, 32, 0, 68, 65, 8, 0, 49, 57, 57, 55, 48, 56, 49, 53];
    byte[]|EncodingError bytes = toBytes(dataElement, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertEquals(bytes, explicitLittleDataElementBytes);
}

@test:Config {groups: ["utils"]}
function toBytesValidDataElementExplicitBigTest() {
    // StudyDate Data Element
    DataElement dataElement = {
        tag: {group: 0x0008, element: 0x0020},
        vr: DA,
        value: "19970815"
    };
    byte[] explicitBigDataElementBytes = [0, 8, 0, 32, 68, 65, 0, 8, 49, 57, 57, 55, 48, 56, 49, 53];
    byte[]|EncodingError bytes = toBytes(dataElement, EXPLICIT_VR_BIG_ENDIAN);
    test:assertEquals(bytes, explicitBigDataElementBytes);
}

@test:Config {groups: ["utils"]}
function toBytesValidDataElementImplicitLittleTest() {
    // StudyDate Data Element
    DataElement dataElement = {
        tag: {group: 0x0008, element: 0x0020},
        value: "19970815"
    };
    byte[] implicitLittleDataElementBytes = [8, 0, 32, 0, 8, 0, 49, 57, 57, 55, 48, 56, 49, 53];
    byte[]|EncodingError bytes = toBytes(dataElement, IMPLICIT_VR_LITTLE_ENDIAN);
    test:assertEquals(bytes, implicitLittleDataElementBytes);
}

@test:Config {groups: ["utils"]}
function toBytesValidDatasetTest() {
    Dataset dataset = table [
        {tag: {group: 0x0010, element: 0x1010}, vr: AS, value: "020Y"}, // PatientAge
        {tag: {group: 0x0028, element: 0x0002}, vr: US, value: 1}, // SamplesPerPixel
        {tag: {group: 0x0008, element: 0x0020}, vr: DA, value: "19970815"} // StudyDate
    ];
    byte[] explicitLittleDatasetBytes = [
        16,
        0,
        16,
        16,
        65,
        83,
        4,
        0,
        48,
        50,
        48,
        89,
        40,
        0,
        2,
        0,
        85,
        83,
        2,
        0,
        1,
        0,
        8,
        0,
        32,
        0,
        68,
        65,
        8,
        0,
        49,
        57,
        57,
        55,
        48,
        56,
        49,
        53
    ];
    byte[]|EncodingError bytes = toBytes(dataset, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertEquals(bytes, explicitLittleDatasetBytes);
}

@test:Config {groups: ["utils"]}
function toBytesValidDatasetSortedTest() {
    Dataset dataset = table [
        {tag: {group: 0x0010, element: 0x1010}, vr: AS, value: "020Y"}, // PatientAge
        {tag: {group: 0x0028, element: 0x0002}, vr: US, value: 1}, // SamplesPerPixel
        {tag: {group: 0x0008, element: 0x0020}, vr: DA, value: "19970815"} // StudyDate
    ];
    byte[] explicitLittleDatasetBytes = [
        8,
        0,
        32,
        0,
        68,
        65,
        8,
        0,
        49,
        57,
        57,
        55,
        48,
        56,
        49,
        53,
        16,
        0,
        16,
        16,
        65,
        83,
        4,
        0,
        48,
        50,
        48,
        89,
        40,
        0,
        2,
        0,
        85,
        83,
        2,
        0,
        1,
        0
    ];
    byte[]|EncodingError bytes = toBytes(dataset, EXPLICIT_VR_LITTLE_ENDIAN, encodeSorted = true);
    test:assertEquals(bytes, explicitLittleDatasetBytes);
}

@test:Config {groups: ["utils"]}
function bytesToIntLittleEndianTest() {
    int expectedInt = 2428;
    byte[] expectedIntLittleEndianBytes = [124, 9, 0, 0];
    int|Error actualInt = bytesToInt(expectedIntLittleEndianBytes, LITTLE_ENDIAN);
    test:assertEquals(actualInt, expectedInt);
}

@test:Config {groups: ["utils"]}
function bytesToIntBigEndianTest() {
    int expectedInt = 2428;
    byte[] expectedIntBigEndianBytes = [0, 0, 9, 124];
    int|Error actualInt = bytesToInt(expectedIntBigEndianBytes, BIG_ENDIAN);
    test:assertEquals(actualInt, expectedInt);
}

@test:Config {groups: ["utils"]}
function bytesToFloatLittleEndianTest() {
    float expectedFloat = 3.1415;
    byte[] expectedFloatLittleEndianBytes = [86, 14, 73, 64];
    float|Error actualFloat = bytesToFloat(expectedFloatLittleEndianBytes, LITTLE_ENDIAN);
    if actualFloat is Error {
        test:assertFail("Converting valid float bytes to float must not result in an error");
    }
    test:assertEquals(actualFloat.round(4), expectedFloat); // Have to round and test
}

@test:Config {groups: ["utils"]}
function bytesToFloatBigEndianTest() {
    float expectedFloat = 3.1415;
    byte[] expectedFloatBigEndianBytes = [64, 73, 14, 86];
    float|Error actualFloat = bytesToFloat(expectedFloatBigEndianBytes, BIG_ENDIAN);
    if actualFloat is Error {
        test:assertFail("Converting valid float bytes to float must not result in an error");
    }
    test:assertEquals(actualFloat.round(4), expectedFloat); // Have to round and test
}

@test:Config {groups: ["utils"]}
function floatToBytesLittleEndianTest() {
    float 'float = 3.1415;
    byte[] expectedLittleEndianBytes = [86, 14, 73, 64];
    byte[]|Error actualBytes = floatToBytes('float, LITTLE_ENDIAN);
    test:assertEquals(actualBytes, expectedLittleEndianBytes);
}

@test:Config {groups: ["utils"]}
function floatToBytesBigEndianTest() {
    float 'float = 3.1415;
    byte[] expectedBigEndianBytes = [64, 73, 14, 86];
    byte[]|Error actualBytes = floatToBytes('float, BIG_ENDIAN);
    test:assertEquals(actualBytes, expectedBigEndianBytes);
}
