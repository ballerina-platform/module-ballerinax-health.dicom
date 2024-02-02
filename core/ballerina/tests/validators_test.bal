import ballerina/test;

@test:Config {groups: ["validators"]}
function validateTagStandardTagTest() {
    Tag standardTag = {group: 0x0010, element: 0x0010};
    ValidationError? standardTagValidationRes = validateTag(standardTag);
    test:assertTrue(standardTagValidationRes == (), "Validating standard tags must not result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateTagRepeatingTagTest() {
    Tag repeatingTag = {group: 0x6000, element: 0x0010};
    ValidationError? repeatingTagValidationRes = validateTag(repeatingTag);
    test:assertTrue(repeatingTagValidationRes == (), "Validating repeating tags must not result in a validation error");
}

// TODO: Add test cases for private tags

@test:Config {groups: ["validators"]}
function validateTagInvalidTagTest() {
    Tag invalidTag = {group: 0xFFFF, element: 0xFFFF};
    ValidationError? invalidTagValidationRes = validateTag(invalidTag);
    test:assertTrue(invalidTagValidationRes is ValidationError,
            "Validating invalid tags must result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateVrValidVrTest() {
    Tag patientNameTag = {group: 0x0010, element: 0x0010};

    TagInfo? patientNameTagInfo = getStandardTagInfo(patientNameTag);
    if patientNameTagInfo == () {
        test:assertFail(string `Could not get the tag info of the tag: ${patientNameTag.toString()}`);
    }

    DataElement validVrDataElement = {
        tag: patientNameTag,
        vr: PN, // Valid VR for the PatientName tag
        value: "JOHN"
    };

    ValidationError? validVrValidationRes = validateVr(validVrDataElement, patientNameTagInfo);
    test:assertTrue(validVrValidationRes == (),
            "Validating VR of data elements with a valid VR must not result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateVrInvalidVrTest() {
    Tag patientNameTag = {group: 0x0010, element: 0x0010};

    TagInfo? patientNameTagInfo = getStandardTagInfo(patientNameTag);
    if patientNameTagInfo == () {
        test:assertFail(string `Could not get the tag info of the tag: ${patientNameTag.toString()}`);
    }

    DataElement invalidVrDataElement = {
        tag: patientNameTag,
        vr: DS, // Invalid VR for the PatientName tag
        value: "JOHN"
    };

    ValidationError? invalidVrValidationRes = validateVr(invalidVrDataElement, patientNameTagInfo);
    test:assertTrue(invalidVrValidationRes is ValidationError,
            "Validating VR of data elements with an invalid VR must result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateVrMissingVrTest() {
    Tag patientNameTag = {group: 0x0010, element: 0x0010};

    TagInfo? patientNameTagInfo = getStandardTagInfo(patientNameTag);
    if patientNameTagInfo == () {
        test:assertFail(string `Could not get the tag info of the tag: ${patientNameTag.toString()}`);
    }

    DataElement missingVrDataElement = {
        tag: patientNameTag,
        value: "JOHN"
    };

    ValidationError? missingVrValidationRes = validateVr(missingVrDataElement, patientNameTagInfo);
    test:assertTrue(missingVrValidationRes is ValidationError,
            "Validating VR of data elements with a missing VR must result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateValueValidValueTest() {
    ValidationError? validValueValidationRes = validateValue(DS, "26", BIG_ENDIAN);
    test:assertTrue(validValueValidationRes == (), "Validating a valid VR value must not result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateValueInvalidValueTest() {
    // AS VR value must follow the format: nnnD, nnnW, nnnM, or nnnY; 
    ValidationError? invalidValueValidationRes = validateValue(AS, "0036W", BIG_ENDIAN);
    test:assertTrue(invalidValueValidationRes is ValidationError,
            "Validating an invalid VR value must result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateDataElementValidTest() {
    DataElement validDataElement = {
        tag: {group: 0x0008, element: 0x0020}, // Valid tag
        vr: DA, // Valid tag VR
        value: "19970815" // Valid tag value type/length/format
    };
    ValidationError? validDataElementValidationRes = validateDataElement(validDataElement, EXPLICIT_VR_BIG_ENDIAN);
    test:assertTrue(validDataElementValidationRes == (),
            "Validating a valid data element must not result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateDataElementInvalidTagTest() {
    DataElement invalidTagDataElement = {
        tag: {group: 0xffff, element: 0xffff}, // Invalid tag
        vr: PN,
        value: "JOHN"
    };
    ValidationError? invalidTagDataElementValidationRes = validateDataElement(invalidTagDataElement,
            EXPLICIT_VR_BIG_ENDIAN);
    test:assertTrue(invalidTagDataElementValidationRes is ValidationError,
            "Validating a data element with an invalid tag must result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateDataElementInvalidVrTest() {
    DataElement invalidVrDataElement = {
        tag: {group: 0x010, element: 0x0010},
        vr: DS, // Invalid VR for the tag
        value: "JOHN"
    };
    ValidationError? invalidVrDataElementValidationRes = validateDataElement(invalidVrDataElement,
            EXPLICIT_VR_BIG_ENDIAN);
    test:assertTrue(invalidVrDataElementValidationRes is ValidationError,
            "Validating a data element with an invalid VR must result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateDataElementInvalidValueTypeTest() {
    DataElement invalidValueTypeDataElement = {
        tag: {group: 0x010, element: 0x0010},
        vr: PN,
        value: 15 // Invalid value type for VR PN
    };
    ValidationError? invalidValueTypeDataElementValidationRes = validateDataElement(invalidValueTypeDataElement,
            EXPLICIT_VR_BIG_ENDIAN);
    test:assertTrue(invalidValueTypeDataElementValidationRes is ValidationError,
            "Validating a data element with an invalid value type must result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateDataElementInvalidValueLength() {
    DataElement invalidValueLengthDataElement = {
        tag: {group: 0x0002, element: 0x0016},
        vr: AE,
        value: "CCCCCCCCCCCCCCCCC" // Invalid length, max allowed length is 16 for VR AE
    };
    ValidationError? invalidValueLengthDataElementRes = validateDataElement(invalidValueLengthDataElement,
            EXPLICIT_VR_BIG_ENDIAN);
    test:assertTrue(invalidValueLengthDataElementRes is ValidationError,
            "Validating a data element with an invalid value length must result in a validation error");
}

@test:Config {groups: ["validators"]}
function validateDataElementInvalidValueFormat() {
    DataElement invalidValueFormatDataElement = {
        tag: {group: 0x0010, element: 0x0030},
        vr: DA,
        value: "195807tf" // Invalid value format for VR DA, must be in format: YYYYMMDD, all numeric strings
    };
    ValidationError? invalidValueFormatDataElementRes = validateDataElement(invalidValueFormatDataElement,
            EXPLICIT_VR_BIG_ENDIAN);
    test:assertTrue(invalidValueFormatDataElementRes is ValidationError,
            "Validating a data element with an invalid value format must result in a validation error");
}
