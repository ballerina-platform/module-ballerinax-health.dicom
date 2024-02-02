import ballerina/test;

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

// TODO: Add test cases for private tags 

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
