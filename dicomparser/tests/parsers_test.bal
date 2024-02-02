import ballerina/test;
import ballerinax/health.dicom;

@test:Config {groups: ["parsers"]}
function parseTagLittleEndianTest() {
    dicom:Tag tag = {group: 0x0010, element: 0x0010};
    byte[] tagBytesLittle = [0x10, 0x00, 0x10, 0x00];

    dicom:Tag|dicom:ParsingError parsedTag = parseTag(tagBytesLittle, dicom:LITTLE_ENDIAN);
    test:assertEquals(parsedTag, tag);
}

@test:Config {groups: ["parsers"]}
function parseTagBigEndianTest() {
    dicom:Tag tag = {group: 0x0010, element: 0x0010};
    byte[] tagBytesBig = [0x00, 0x10, 0x00, 0x10];

    dicom:Tag|dicom:ParsingError parsedTag = parseTag(tagBytesBig, dicom:BIG_ENDIAN);
    test:assertEquals(parsedTag, tag);
}

@test:Config {groups: ["parsers"]}
function parseTagInvalidTest() {
    byte[] invalidTagBytes = [0x10, 0x00];
    dicom:Tag|dicom:ParsingError parsedTag = parseTag(invalidTagBytes, dicom:BIG_ENDIAN);
    test:assertTrue(parsedTag is dicom:ParsingError, "Parsing invalid tag bytes must result in a parsing error");
}

@test:Config {groups: ["parsers"]}
function parseVrValidTest() {
    byte[] validVrBytes = [80, 78]; // PN - valid VR
    dicom:Vr|dicom:ParsingError parsedVr = parseVr(validVrBytes);
    test:assertEquals(parsedVr, dicom:PN);
}

@test:Config {groups: ["parsers"]}
function parseVrInvalidTest() {
    byte[] invalidVrBytes = [0x41, 0x42, 0x43]; // ABC - not a valid VR
    dicom:Vr|dicom:ParsingError parsedVr = parseVr(invalidVrBytes);
    test:assertTrue(parsedVr is dicom:ParsingError, "Parsing invalid VR bytes must result in a parsing error");
}

@test:Config {groups: ["parsers"]}
function parseVlLittleEndianTest() {
    int vl = 2;
    byte[] vlBytesLittle = [0x02, 0x00];
    int|dicom:ParsingError parsedVl = parseVl(vlBytesLittle, dicom:LITTLE_ENDIAN);
    test:assertEquals(parsedVl, vl);
}

@test:Config {groups: ["parsers"]}
function parseVlBigEndianTest() {
    int vl = 2;
    byte[] vlBytesBig = [0x00, 0x02];
    int|dicom:ParsingError parsedVl = parseVl(vlBytesBig, dicom:BIG_ENDIAN);
    test:assertEquals(parsedVl, vl);
}

@test:Config {groups: ["parsers"]}
function parseValueStringTypeTest() {
    dicom:DataElementValue stringValue = "BALDICOM";
    byte[] stringValueBytes = [66, 65, 76, 68, 73, 67, 79, 77];
    dicom:DataElementValue|dicom:ParsingError parsedValue = parseValue(dicom:AE, stringValueBytes, dicom:LITTLE_ENDIAN);
    test:assertEquals(parsedValue, stringValue);
}

@test:Config {groups: ["parsers"]}
function parseValueFloatTypeLittleEndianTest() {
    dicom:DataElementValue floatValue = 0.5;
    byte[] floatValueBytesLittle = [0, 0, 0, 63];
    dicom:DataElementValue|dicom:ParsingError parsedValue = parseValue(dicom:FL, floatValueBytesLittle, dicom:LITTLE_ENDIAN);
    test:assertEquals(parsedValue, floatValue);
}

@test:Config {groups: ["parsers"]}
function parseValueFloatTypeBigEndianTest() {
    dicom:DataElementValue floatValue = 0.5;
    byte[] floatValueBytesBig = [63, 0, 0, 0];
    dicom:DataElementValue|dicom:ParsingError parsedValue = parseValue(dicom:FL, floatValueBytesBig, dicom:BIG_ENDIAN);
    test:assertEquals(parsedValue, floatValue);
}

@test:Config {groups: ["parsers"]}
function parseValueIntTypeLittleEndianTest() {
    dicom:DataElementValue intValue = 150;
    byte[] intValueBytesLittle = [150, 0, 0, 0];
    dicom:DataElementValue|dicom:ParsingError parsedValue = parseValue(dicom:UL, intValueBytesLittle, dicom:LITTLE_ENDIAN);
    test:assertEquals(parsedValue, intValue);
}

@test:Config {groups: ["parsers"]}
function parseValueIntTypeBigEndianTest() {
    dicom:DataElementValue intValue = 150;
    byte[] intValueBytesBig = [0, 0, 0, 150];
    dicom:DataElementValue|dicom:ParsingError parsedValue = parseValue(dicom:UL, intValueBytesBig, dicom:BIG_ENDIAN);
    test:assertEquals(parsedValue, intValue);
}

@test:Config {groups: ["parsers"]}
function parseValueBytesTypeTest() {
    byte[] byteValueBytes = [0, 1];
    dicom:DataElementValue|dicom:ParsingError parsedValue = parseValue(dicom:OB, byteValueBytes, dicom:LITTLE_ENDIAN);
    test:assertEquals(parsedValue, byteValueBytes);
}
