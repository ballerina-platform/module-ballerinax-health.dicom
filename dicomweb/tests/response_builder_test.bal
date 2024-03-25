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
import ballerinax/health.dicom.dicomparser;

dicom:Dataset[] & readonly testDatasets = [];

@test:BeforeGroups {value: ["response_builder"]}
function beforeResponseBuilderGroup() {
    string[] sampleFiles = ["sample_1.DCM", "sample_2.DCM"];
    dicom:Dataset[] datasets = [];

    // Parse samples files
    foreach string sampleFile in sampleFiles {
        dicom:File|dicom:ParsingError parsedFile = dicomparser:parseFile(string `./tests/resources/${sampleFile}`,
                dicom:EXPLICIT_VR_LITTLE_ENDIAN);
        if parsedFile is dicom:ParsingError {
            test:assertFail(string `Could not parse sample file: ${sampleFile}`);
        }
        datasets.push(parsedFile.dataset);
    }

    testDatasets = datasets.cloneReadOnly();
}

@test:Config {groups: ["response_builder"]}
function generateResponseSearchAllStudies() {
    Response|Error generatedResponse = generateResponse(testDatasets, SEARCH_ALL_STUDIES);
    if generatedResponse is Error {
        test:assertFail("Could not generate the DICOMweb response");
    }
    test:assertEquals(generatedResponse, EXPECTED_SEARCH_ALL_STUDIES_RESPONSE);
}

@test:Config {groups: ["response_builder"]}
function generateResponseSearchAllSeries() {
    Response|Error generatedResponse = generateResponse(testDatasets, SEARCH_ALL_SERIES);
    if generatedResponse is Error {
        test:assertFail("Could not generate the DICOMweb response");
    }
    test:assertEquals(generatedResponse, EXPECTED_SEARCH_ALL_SERIES_RESPONSE);
}

@test:Config {groups: ["response_builder"]}
function generateResponseSearchAllInstances() {
    Response|Error generatedResponse = generateResponse(testDatasets, SEARCH_ALL_INSTANCES);
    if generatedResponse is Error {
        test:assertFail("Could not generate the DICOMweb response");
    }
    test:assertEquals(generatedResponse, EXPECTED_SEARCH_ALL_INSTANCES_RESPONSE);
}

@test:Config {groups: ["response_builder"]}
function generateResponseSearchAllStudiesWithValidMatchValuesTest() {
    // Valid match query parameters
    QueryParameterMap queryParams = {
        [MATCH] : {
            "PatientSex": "M"
        }
    };
    Response|Error generatedResponse = generateResponse(testDatasets, SEARCH_ALL_STUDIES, queryParams);
    if generatedResponse is Error {
        test:assertFail("Could not generate the DICOMweb response");
    }
    test:assertEquals(generatedResponse, EXPECTED_SEARCH_ALL_STUDIES_MATCH_RESPONSE);
}

@test:Config {groups: ["response_builder"]}
function generateResponseSearchAllStudiesWithValidIncludeFieldKeywordsTest() {
    // Valid 'includefield' query parameter keyword values
    QueryParameterMap queryParams = {
        [INCLUDEFIELD] : ["Modality", "SeriesNumber"]
    };
    Response|Error generatedResponse = generateResponse(testDatasets, SEARCH_ALL_STUDIES, queryParams);
    if generatedResponse is Error {
        test:assertFail("Could not generate the DICOMweb response");
    }
    test:assertEquals(generatedResponse, EXPECTED_SEARCH_ALL_STUDIES_INCLUDEFIELD_RESPONSE);
}

@test:Config {groups: ["response_builder"]}
function generateResponseSearchAllStudiesValidIncludeFieldTagsTest() {
    // Valid 'includefield' query parameter tag values
    dicom:Tag modalityTag = {group: 0x0008, element: 0x0060};
    dicom:Tag seriesNumberTag = {group: 0x0020, element: 0x0011};

    QueryParameterMap queryParams = {
        [INCLUDEFIELD] : [modalityTag, seriesNumberTag]
    };

    Response|Error generatedResponse = generateResponse(testDatasets, SEARCH_ALL_STUDIES, queryParams);
    if generatedResponse is Error {
        test:assertFail("Could not generate the DICOMweb response");
    }

    test:assertEquals(generatedResponse, EXPECTED_SEARCH_ALL_STUDIES_INCLUDEFIELD_RESPONSE);
}
