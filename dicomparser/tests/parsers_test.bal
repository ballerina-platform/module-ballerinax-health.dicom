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
import ballerinax/health.dicom as dicom;

@test:Config {groups: ["parsers"]}
function parseSequenceValueInvalidValueTest() {
    // Invalid sequence value with an invalid item tag
    byte[] invalidSequenceValue = [
        8,
        0,
        80,
        17,
        255,
        255,
        255,
        255,
        8,
        0,
        80,
        17,
        85,
        73,
        28,
        0,
        49,
        46,
        50,
        46,
        56,
        52,
        48,
        46,
        49,
        48,
        48,
        48,
        56,
        46,
        53,
        46,
        49,
        46,
        52,
        46,
        49,
        46,
        49,
        46,
        49,
        50,
        46,
        49
    ];
    dicom:SequenceValue|dicom:ParsingError parsedSequenceValue = parseSequenceValue(invalidSequenceValue,
            dicom:EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertTrue(parsedSequenceValue is dicom:ParsingError);

    // Invalid sequence value with an invalid VR for the first data element inside the first item
    byte[] invalidSequenceValue1 = [
        254,
        255,
        0,
        224,
        255,
        255,
        255,
        255,
        85,
        73,
        85,
        73,
        0,
        0,
        28,
        0,
        49,
        46,
        50,
        46,
        56,
        52,
        48,
        46,
        49,
        48,
        48,
        48,
        56,
        46,
        53,
        46,
        49,
        46,
        52,
        46,
        49,
        46,
        49,
        46,
        49,
        50,
        46,
        49
    ];
    dicom:SequenceValue|dicom:ParsingError parsedSequenceValue1 = parseSequenceValue(invalidSequenceValue1,
            dicom:EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertTrue(parsedSequenceValue1 is dicom:ParsingError);
}

@test:Config {groups: ["parsers"]}
function parseFileValidTest() {
    dicom:File|dicom:ParsingError parsedFile = parseFile("./tests/resources/sample_1.DCM",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
    if parsedFile is dicom:File {
        // Asserting some patient data based on EXPECTED_NO_PIXEL_DATA_PARSED_FILE
        string|dicom:Error patientName = dicom:getString(parsedFile.dataset, dicom:TAG_PATIENT_NAME);
        if patientName is string {
            test:assertEquals(patientName, "Rubo DEMO");
        } else {
            test:assertFail("Patient Name element not found.");
        }
        string|dicom:Error patientId = dicom:getString(parsedFile.dataset, dicom:TAG_PATIENT_ID);
        if patientId is string {
            test:assertEquals(patientId, "556342B");
        } else {
            test:assertFail("Patient ID element not found.");
        }
    } else {
        test:assertFail("Parsing failed for sample_1.DCM with ignorePixelData=true: " + parsedFile.message());
    }
}

@test:Config {groups: ["parsers"]}
function parseFileWithPixelDataTest() {
    dicom:File|dicom:ParsingError parsedFile = parseFile("./tests/resources/sample_1.DCM",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN);
    if parsedFile is dicom:File {
        // Pixel Data Tag is (7FE0, 0010) -> (32736, 16) in decimal
        dicom:DataElement? pixelDataElement = dicom:getDataElement(parsedFile.dataset, dicom:TAG_PIXEL_DATA);
        if pixelDataElement is dicom:DataElement {
            test:assertTrue(pixelDataElement.value is byte[]);
        } else {
            test:assertFail("Pixel Data element not found.");
        }
    } else {
        test:assertFail("Parsing failed for sample_1.DCM: " + parsedFile.message());
    }
}

@test:Config {groups: ["parsers"]}
function parseFileMetaOnlyTest() {
    dicom:File|dicom:ParsingError parsedFile = parseFile("./tests/resources/sample_1.DCM",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, metaElementsOnly = true);
    if parsedFile is dicom:File {
        // Meta information elements are in group 2
        test:assertEquals(parsedFile.dataset.length(), 6);
        foreach dicom:DataElement de in parsedFile.dataset {
            test:assertEquals(de.tag.group, 2);
        }
    } else {
        test:assertFail("Parsing failed for sample_1.DCM with metaElementsOnly=true: " + parsedFile.message());
    }
}

@test:Config {groups: ["parsers"]}
function parsePatientInfoSampleTest() {
    dicom:File|dicom:ParsingError parsedFile = parseFile("./tests/resources/sample_patient_info.dcm",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
    if parsedFile is dicom:File {
        test:assertTrue(parsedFile.dataset.length() > 0);

        // Assert Patient Name (raw PN string)
        string|dicom:Error patientName = dicom:getString(parsedFile.dataset, dicom:TAG_PATIENT_NAME);
        if patientName is string {
            test:assertEquals(patientName, "Overlay^Test");

            // Parse the PN VR string into structured components
            dicom:PersonName pn = dicom:parsePersonName(patientName);
            test:assertEquals(pn.familyName, "Overlay");
            test:assertEquals(pn.givenName, "Test");
        } else {
            test:assertFail("Patient Name element not found.");
        }
    } else {
        test:assertFail("Parsing failed for sample_patient_info.dcm with ignorePixelData=true: " + parsedFile.message());
    }
}

@test:Config {groups: ["parsers"]}
function parseMultiValueFloatTagTest() {
    dicom:File|dicom:ParsingError parsedFile = parseFile("./tests/resources/sample_patient_info.dcm",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
    if parsedFile is dicom:File {
        // ImagePositionPatient (0020,0032) is a DS VR with VM=3 (3 floats separated by \)
        float[]|dicom:Error position = dicom:getFloatArray(parsedFile.dataset, dicom:TAG_IMAGE_POSITION_PATIENT);
        if position is float[] {
            // The image position patient should have 3 coordinates
            test:assertEquals(position.length(), 3);
        }
        // Also test string array extraction against ImageType (0008,0008) which is CS with VM>1  
        string[]|dicom:Error imageType = dicom:getStringArray(parsedFile.dataset, dicom:TAG_IMAGE_TYPE);
        if imageType is string[] {
            test:assertTrue(imageType.length() > 0);
        }
    } else {
        test:assertFail("Parsing failed for sample_patient_info.dcm: " + parsedFile.message());
    }
}

@test:Config {groups: ["parsers"]}
function parseDateAndTimeTagsTest() {
    dicom:File|dicom:ParsingError parsedFile = parseFile("./tests/resources/sample_patient_info.dcm",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
    if parsedFile is dicom:File {
        // Test DA VR: StudyDate (0008,0020)
        string|dicom:Error studyDateStr = dicom:getString(parsedFile.dataset, dicom:TAG_STUDY_DATE);
        if studyDateStr is string {
            dicom:DicomDate|dicom:Error studyDate = dicom:parseDate(studyDateStr);
            if studyDate is dicom:DicomDate {
                // Year must be positive and month/day within valid range
                test:assertTrue(studyDate.year > 0);
                test:assertTrue(studyDate.month >= 1 && studyDate.month <= 12);
                test:assertTrue(studyDate.day >= 1 && studyDate.day <= 31);
            }
        }

        // Also verify parseDate works correctly with a known value
        dicom:DicomDate|dicom:Error testDate = dicom:parseDate("20010103");
        if testDate is dicom:DicomDate {
            test:assertEquals(testDate.year, 2001);
            test:assertEquals(testDate.month, 1);
            test:assertEquals(testDate.day, 3);
        } else {
            test:assertFail("Failed to parse known valid DA string");
        }

        // Also verify parseTime works with known values
        dicom:DicomTime|dicom:Error testTime = dicom:parseTime("142130.500");
        if testTime is dicom:DicomTime {
            test:assertEquals(testTime.hours, 14);
            test:assertEquals(testTime.minutes, 21);
            test:assertEquals(testTime.seconds, 30);
            test:assertEquals(testTime.fractional, 500);
        } else {
            test:assertFail("Failed to parse known valid TM string");
        }
    } else {
        test:assertFail("Parsing failed for sample_patient_info.dcm: " + parsedFile.message());
    }
}
