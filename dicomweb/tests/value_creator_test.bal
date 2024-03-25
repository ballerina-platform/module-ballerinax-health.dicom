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

@test:Config {groups: ["value_creator"]}
function createSequenceValueValidDataset() {
    // Sample ReferencedImageSequence data element
    dicom:DataElement sequenceDataElement = {
        tag: {group: 0x0008, element: 0x1140},
        vr: dicom:SQ,
        vl: -1,
        value: table [ // Sequence value
            {
                tag: {group: 0xFFFE, element: 0xE000},
                length: -1,
                valueDataset: table [
                    {
                        tag: {group: 0x0008, element: 0x1150},
                        vr: dicom:UI,
                        vl: 28,
                        value: "1.2.840.10008.5.1.4.1.1.12.1"
                    },
                    {
                        tag: {group: 0x0008, element: 0x1155},
                        vr: dicom:UI,
                        vl: 46,
                        value: "1.3.12.2.1107.5.4.3.284980.19951129.170916.11"
                    }
                ]
            }
        ]
    };

    ModelObject[]|Error sequenceValue = createSequenceValue(sequenceDataElement);
    if sequenceValue is Error {
        test:assertFail("Could not create sequence value");
    }

    test:assertEquals(sequenceValue, EXPECTED_SEQUENCE_VALUE);
}

@test:Config {groups: ["value_creator"]}
function createPersonNameValueInvalidDataElement() {
    dicom:DataElement invalidPatientNameDataElement = {
        tag: {group: 0x0010, element: 0x0010},
        vl: 4,
        value: 1234
    };
    PersonNameValue|Error personNameValue = createPersonNameValue(invalidPatientNameDataElement);
    test:assertTrue(personNameValue is Error);
}
