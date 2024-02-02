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

@test:Config {groups: ["utils"]}
function parseFileParseTest() {
    dicom:File|dicom:Dataset|dicom:ParsingError parsedFile = parse("./tests/resources/sample_1.DCM",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
    test:assertEquals(parsedFile, EXPECTED_NO_PIXEL_DATA_PARSED_FILE);
}

@test:Config {groups: ["utils"]}
function parseDatasetParseTest() {
    byte[] datasetExplicitLittleEndianBytes = [
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
    dicom:File|dicom:Dataset|dicom:ParsingError parsedDataset = parse(datasetExplicitLittleEndianBytes,
            dicom:EXPLICIT_VR_LITTLE_ENDIAN);
    test:assertEquals(parsedDataset, EXPECTED_PARSED_DATASET);
}
