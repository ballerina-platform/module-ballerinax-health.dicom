import ballerina/test;

@test:Config {groups: ["encoders"]}
function encodeGroupBigEndianTest() {
    Tag patientNameTag = {group: 0x0010, element: 0x0010};
    byte[] patientNameGroupBytesBig = [0, 16];

    byte[]|EncodingError encodedPatientNameGroupBig = encodeGroup(patientNameTag, BIG_ENDIAN);
    test:assertEquals(encodedPatientNameGroupBig, patientNameGroupBytesBig);
}

@test:Config {groups: ["encoders"]}
function encodeGroupLittleEndianTest() {
    Tag patientNameTag = {group: 0x0010, element: 0x0010};
    byte[] patientNameGroupBytesLittle = [16, 0];

    byte[]|EncodingError encodedPatientNameGroupLittle = encodeGroup(patientNameTag, LITTLE_ENDIAN);
    test:assertEquals(encodedPatientNameGroupLittle, patientNameGroupBytesLittle);
}

@test:Config {groups: ["encoders"]}
function encodeElementBigEndianTest() {
    Tag patientNameTag = {group: 0x0010, element: 0x0010};
    byte[] patientNameElementBytesBig = [0, 16];

    byte[]|EncodingError encodedPatientNameElementBig = encodeElement(patientNameTag, BIG_ENDIAN);
    test:assertEquals(encodedPatientNameElementBig, patientNameElementBytesBig);
}

@test:Config {groups: ["encoders"]}
function encodeElementLittleEndianTest() {
    Tag patientNameTag = {group: 0x0010, element: 0x0010};
    byte[] patientNameElementBytesLittle = [16, 0];

    byte[]|EncodingError encodedPatientNameElementLittle = encodeElement(patientNameTag, LITTLE_ENDIAN);
    test:assertEquals(encodedPatientNameElementLittle, patientNameElementBytesLittle);
}

@test:Config {groups: ["encoders"]}
function encodeTagBigEndianTest() {
    Tag patientNameTag = {group: 0x0010, element: 0x0010};
    byte[] patientNameTagBytesBig = [0, 16, 0, 16];

    byte[]|EncodingError encodedPatientNameTagBig = encodeTag(patientNameTag, BIG_ENDIAN);
    test:assertEquals(encodedPatientNameTagBig, patientNameTagBytesBig);
}

@test:Config {groups: ["encoders"]}
function encodeTagLittleEndianTest() {
    Tag patientNameTag = {group: 0x0010, element: 0x0010};
    byte[] patientNameTagBytesBig = [16, 0, 16, 0];

    byte[]|EncodingError encodedPatientNameTagLittle = encodeTag(patientNameTag, LITTLE_ENDIAN);
    test:assertEquals(encodedPatientNameTagLittle, patientNameTagBytesBig);
}

@test:Config {groups: ["encoders"]}
function encodeVlUndefinedLengthTest() {
    // SQ VR length is undefined
    byte[]|EncodingError encodedVlSq = encodeVl(SQ, -1, BIG_ENDIAN);
    test:assertEquals(encodedVlSq, UNDEFINED_VL_BYTES);
}

@test:Config {groups: ["encoders"]}
function encodeVlBigEndianTest() {
    int vl = 4;
    final byte[] vlBytesBig = [0, 4];

    byte[]|EncodingError encodedVlBig = encodeVl(AS, vl, BIG_ENDIAN);
    test:assertEquals(encodedVlBig, vlBytesBig);
}

@test:Config {groups: ["encoders"]}
function encodeVlLittleEndianTest() {
    int vl = 4;
    final byte[] vlBytesLittle = [4, 0];

    byte[]|EncodingError encodedVlLittle = encodeVl(AS, vl, LITTLE_ENDIAN);
    test:assertEquals(encodedVlLittle, vlBytesLittle);
}

@test:Config {groups: ["encoders"]}
function encodeStringTypeValueTest() {
    DataElementValue stringValue = "JOHN";
    byte[] stringValueBytes = [74, 79, 72, 78];

    byte[]|EncodingError encodedStringValue = encodeValue(PN, stringValue, BIG_ENDIAN);
    test:assertEquals(encodedStringValue, stringValueBytes);
}

@test:Config {groups: ["encoders"]}
function encodeFloatTypeValueBigEndianTest() {
    DataElementValue floatValue = 0.5;
    byte[] floatValueBytesBig = [63, 0, 0, 0];

    byte[]|EncodingError encodedFloatValueBig = encodeValue(FL, floatValue, BIG_ENDIAN);
    test:assertEquals(encodedFloatValueBig, floatValueBytesBig);
}

@test:Config {groups: ["encoders"]}
function encodeFloatTypeValueLittleEndianTest() {
    DataElementValue floatValue = 0.5;
    byte[] floatValueBytesLittle = [0, 0, 0, 63];

    byte[]|EncodingError encodedFloatValueLittle = encodeValue(FL, floatValue, LITTLE_ENDIAN);
    test:assertEquals(encodedFloatValueLittle, floatValueBytesLittle);
}

// TODO: Add tests for other value types

@test:Config {groups: ["encoders"]}
function encodeDataElementImplicitLittleEndianTest() {
    DataElement dataElement = {
        tag: {group: 0x010, element: 0x010},
        value: "JOHN"
    };
    byte[] dataElementBytesImplicitLittle = [16, 0, 16, 0, 4, 0, 74, 79, 72, 78];

    byte[]|EncodingError encodedDataElementImplicitLittle = encodeDataElement(dataElement, IMPLICIT_VR_LITTLE_ENDIAN);
    test:assertEquals(encodedDataElementImplicitLittle, dataElementBytesImplicitLittle);
}

@test:Config {groups: ["encoders"]}
function encodeDataElementExplicitBigEndianTest() {
    DataElement dataElement = {
        tag: {group: 0x010, element: 0x010},
        vr: PN,
        value: "JOHN"
    };
    byte[] dataElementBytesExplicitBig = [0, 16, 0, 16, 80, 78, 0, 4, 74, 79, 72, 78];

    byte[]|EncodingError encodedDataElementExplicitBig = encodeDataElement(dataElement, EXPLICIT_VR_BIG_ENDIAN);
    test:assertEquals(encodedDataElementExplicitBig, dataElementBytesExplicitBig);
}

@test:Config {groups: ["encoders"]}
function encodeDataElementExplicitLittleEndianTest() {
    DataElement dataElement = {
        tag: {group: 0x010, element: 0x010},
        vr: PN,
        value: "JOHN"
    };
    byte[] dataElementBytesExplicitLittle = [16, 0, 16, 0, 80, 78, 4, 0, 74, 79, 72, 78];

    byte[]|EncodingError encodedDataElementExplicitLittle = encodeDataElement(dataElement, EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertEquals(encodedDataElementExplicitLittle, dataElementBytesExplicitLittle);
}
