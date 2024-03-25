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
