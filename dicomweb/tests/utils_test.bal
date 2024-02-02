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
import ballerinax/health.dicom;

string[] ieLevelStudyAttributes = [];
string[] ieLevelSeriesAttributes = [];
string[] ieLevelInstanceAttributes = [];

@test:BeforeGroups {value: ["attribute_matching"]}
function beforeAttributeMatchingGroup() {
    ieLevelStudyAttributes = from dicom:Tag tag in SEARCH_IE_LEVELS.get(STUDY)
        select dicom:tagToStr(tag);

    ieLevelSeriesAttributes = from dicom:Tag tag in SEARCH_IE_LEVELS.get(SERIES)
        select dicom:tagToStr(tag);

    ieLevelInstanceAttributes = from dicom:Tag tag in SEARCH_IE_LEVELS.get(INSTANCE)
        select dicom:tagToStr(tag);
};

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeValidSearchAllStudiesAttributesTest() {
    // Valid Match attributes for Search transaction's 'All Studies' resource
    string[] searchAllStudiesMatchAttributes = [...ieLevelStudyAttributes];
    foreach string matchAttribute in searchAllStudiesMatchAttributes {
        test:assertTrue(isValidResourceMatchAttribute(matchAttribute, SEARCH_ALL_STUDIES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeInvalidSearchAllStudiesAttributesTest() {
    // Invalid Match attributes for Search transaction's 'All Studies' resource
    string[] searchAllStudiesMatchAttributes = [...ieLevelSeriesAttributes];
    foreach string matchAttribute in searchAllStudiesMatchAttributes {
        test:assertFalse(isValidResourceMatchAttribute(matchAttribute, SEARCH_ALL_STUDIES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeValidSearchStudySeriesAttributesTest() {
    // Valid Match attributes for Search transaction's 'Study's Series' resource
    string[] searchStudySeriesMatchAttributes = [...ieLevelSeriesAttributes];
    foreach string matchAttribute in searchStudySeriesMatchAttributes {
        test:assertTrue(isValidResourceMatchAttribute(matchAttribute, SEARCH_STUDY_SERIES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeInvalidSearchStudySeriesAttributesTest() {
    // Invalid Match attributes for Search transaction's 'Study's Series' resource
    string[] searchStudySeriesMatchAttributes = [...ieLevelStudyAttributes];
    foreach string matchAttribute in searchStudySeriesMatchAttributes {
        test:assertFalse(isValidResourceMatchAttribute(matchAttribute, SEARCH_STUDY_SERIES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeValidSearchStudyInstancesAttributesTest() {
    // Valid match attributes for Search transaction's 'Study's Instances' resource
    string[] searchStudyInstancesMatchAttributes = [...ieLevelSeriesAttributes, ...ieLevelInstanceAttributes];
    foreach string matchAttribute in searchStudyInstancesMatchAttributes {
        test:assertTrue(isValidResourceMatchAttribute(matchAttribute, SEARCH_STUDY_INSTANCES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeInvalidSearchStudyInstancesAttributesTest() {
    // Invalid match attributes for Search transaction's 'Study's Instances' resource
    string[] searchStudyInstancesMatchAttributes = [...ieLevelStudyAttributes];
    foreach string matchAttribute in searchStudyInstancesMatchAttributes {
        test:assertFalse(isValidResourceMatchAttribute(matchAttribute, SEARCH_STUDY_INSTANCES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeValidSearchAllSeriesAttributesTest() {
    // Valid match attributes for Search transaction's 'All Series' resource
    string[] searchAllSeriesMatchAttributes = [...ieLevelStudyAttributes, ...ieLevelSeriesAttributes];
    foreach string matchAttribute in searchAllSeriesMatchAttributes {
        test:assertTrue(isValidResourceMatchAttribute(matchAttribute, SEARCH_ALL_SERIES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeInvalidSearchAllSeriesAttributesTest() {
    // Invalid match attributes for Search transaction's 'All Series' resource
    string[] searchAllSeriesMatchAttributes = [...ieLevelInstanceAttributes];
    foreach string matchAttribute in searchAllSeriesMatchAttributes {
        test:assertFalse(isValidResourceMatchAttribute(matchAttribute, SEARCH_ALL_SERIES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeValidSearchStudySeriesInstancesAttributesTest() {
    // Valid match attributes for Search transaction's 'Study Series' Instances' resource
    string[] searchStudySeriesInstancesMatchAttributes = [...ieLevelInstanceAttributes];
    foreach string matchAttribute in searchStudySeriesInstancesMatchAttributes {
        test:assertTrue(isValidResourceMatchAttribute(matchAttribute, SEARCH_STUDY_SERIES_INSTANCES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeInvalidSearchStudySeriesInstancesAttributesTest() {
    // Invalid match attributes for Search transaction's 'Study Series' Instances' resource
    string[] searchStudySeriesInstancesMatchAttributes = [...ieLevelSeriesAttributes];
    foreach string matchAttribute in searchStudySeriesInstancesMatchAttributes {
        test:assertFalse(isValidResourceMatchAttribute(matchAttribute, SEARCH_STUDY_SERIES_INSTANCES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeValidSearchAllInstancesAttributesTest() {
    // Valid match attributes for Search transaction's 'All Instances' resource
    string[] searchAllInstancesMatchAttributes = [
        ...ieLevelStudyAttributes,
        ...ieLevelSeriesAttributes,
        ...ieLevelInstanceAttributes
    ];
    foreach string matchAttribute in searchAllInstancesMatchAttributes {
        test:assertTrue(isValidResourceMatchAttribute(matchAttribute, SEARCH_ALL_INSTANCES));
    }
}

@test:Config {groups: ["utils", "attribute_matching"]}
function isValidResourceMatchAttributeInvalidMatchAttributesTest() {
    // Invalid DICOMweb attributes
    string[] invalidMatchAttributes = ["12345", "Hello", "123abcd", "@#$@%@#%"];
    foreach string matchAttribute in invalidMatchAttributes {
        test:assertFalse(isValidResourceMatchAttribute(matchAttribute, SEARCH_ALL_SERIES));
    }
}

@test:Config {groups: ["utils"]}
function createInternalDicomwebErrorTest() {
    Error internalError = createInternalDicomwebError("Sample internal error", PROCESSING_ERROR);
    test:assertTrue(internalError is ProcessingError);
    test:assertTrue(internalError.detail().internalError);
}

@test:Config {groups: ["utils"]}
function createDicomwebErrorTest() {
    // Validation error
    Error validationError = createDicomwebError("Sample validation error", VALIDATION_ERROR);
    test:assertTrue(validationError is ValidationError);
    // Processing error
    Error processingError = createDicomwebError("Sample processing error", PROCESSING_ERROR);
    test:assertTrue(processingError is ProcessingError);
}

@test:Config {groups: ["utils"]}
function constructStatusReportTest() {
    string message = "An error occurred while processing the request";
    string diagnostic = "Bad request";
    Error dicomwebError = createDicomwebError(message, VALIDATION_ERROR, diagnostic);
    string uri = "dicomweb/studies";

    StatusReport statusReport = constructStatusReport(dicomwebError, uri);
    StatusReportErrorDetails errorDetails = statusReport.errorDetails;

    test:assertEquals(statusReport.uri, uri);
    test:assertEquals(errorDetails.message, message);
    test:assertEquals(errorDetails.diagnostic, diagnostic);
}
