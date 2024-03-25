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

const EXPECTED_SEARCH_ALL_STUDIES_RESPONSE = [
    {
        "00080020": {"vr": "DA", "Value": ["19941013"]},
        "00080030": {"vr": "TM", "Value": ["141917"]},
        "00080050": {"vr": "SH"},
        "00080090": {"vr": "PN"},
        "00100010": {"vr": "PN", "Value": {"Alphabetic": "Rubo DEMO"}},
        "00100020": {"vr": "LO", "Value": ["556342B"]},
        "00100030": {"vr": "DA", "Value": ["19951025"]},
        "00100040": {"vr": "CS", "Value": ["M"]},
        "0020000D": {"vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6"]},
        "00200010": {"vr": "SH"}
    },
    {
        "00080020": {"vr": "DA", "Value": ["19930325"]},
        "00080030": {"vr": "TM", "Value": ["135731"]},
        "00080050": {"vr": "SH"},
        "00080090": {"vr": "PN"},
        "00100010": {"vr": "PN", "Value": {"Alphabetic": "Rubo DEMO"}},
        "00100020": {"vr": "LO", "Value": ["322-292-73-6"]},
        "00100030": {"vr": "DA", "Value": ["19580719"]},
        "00100040": {"vr": "CS", "Value": ["F"]},
        "0020000D": {"vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.16"]},
        "00200010": {"vr": "SH"}
    }
];

const EXPECTED_SEARCH_ALL_SERIES_RESPONSE = [
    {
        "00080060": {"vr": "CS", "Value": ["XA"]},
        "0020000E": {"vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.8"]},
        "00200011": {"vr": "IS", "Value": ["1"]}
    },
    {
        "00080060": {"vr": "CS", "Value": ["XA"]},
        "0020000E": {"vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.17"]},
        "00200011": {"vr": "IS", "Value": ["1"]}
    }
];

const EXPECTED_SEARCH_ALL_INSTANCES_RESPONSE = [
    {
        "00080016": {"vr": "UI", "Value": ["1.2.840.10008.5.1.4.1.1.12.1"]},
        "00080018": {"vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.321890.19960124.162922.29"]},
        "00200013": {"vr": "IS"},
        "00280008": {"vr": "IS", "Value": ["96"]},
        "00280010": {"vr": "US", "Value": [512]},
        "00280011": {"vr": "US", "Value": [512]},
        "00280100": {"vr": "US", "Value": [8]}
    },
    {
        "00080016": {"vr": "UI", "Value": ["1.2.840.10008.5.1.4.1.1.12.1"]},
        "00080018": {"vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.284980.19951129.170916.9"]},
        "00200013": {"vr": "IS"},
        "00280008": {"vr": "IS", "Value": ["17"]},
        "00280010": {"vr": "US", "Value": [512]},
        "00280011": {"vr": "US", "Value": [512]},
        "00280100": {"vr": "US", "Value": [8]}
    }
];

const EXPECTED_SEARCH_ALL_STUDIES_MATCH_RESPONSE = [
    {
        "00080020": {"vr": "DA", "Value": ["19941013"]},
        "00080030": {"vr": "TM", "Value": ["141917"]},
        "00080050": {"vr": "SH"},
        "00080090": {"vr": "PN"},
        "00100010": {"vr": "PN", "Value": {"Alphabetic": "Rubo DEMO"}},
        "00100020": {"vr": "LO", "Value": ["556342B"]},
        "00100030": {"vr": "DA", "Value": ["19951025"]},
        "00100040": {"vr": "CS", "Value": ["M"]},
        "0020000D": {"vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6"]},
        "00200010": {"vr": "SH"}
    }
];

const EXPECTED_SEARCH_ALL_STUDIES_INCLUDEFIELD_RESPONSE = [
    {
        "00080020": {"vr": "DA", "Value": ["19941013"]},
        "00080030": {"vr": "TM", "Value": ["141917"]},
        "00080050": {"vr": "SH"},
        "00080060": {"vr": "CS", "Value": ["XA"]},
        "00080090": {"vr": "PN"},
        "00100010": {"vr": "PN", "Value": {"Alphabetic": "Rubo DEMO"}},
        "00100020": {"vr": "LO", "Value": ["556342B"]},
        "00100030": {"vr": "DA", "Value": ["19951025"]},
        "00100040": {"vr": "CS", "Value": ["M"]},
        "0020000D": {"vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6"]},
        "00200010": {"vr": "SH"},
        "00200011": {"vr": "IS", "Value": ["1"]}
    },
    {
        "00080020": {"vr": "DA", "Value": ["19930325"]},
        "00080030": {"vr": "TM", "Value": ["135731"]},
        "00080050": {"vr": "SH"},
        "00080060": {"vr": "CS", "Value": ["XA"]},
        "00080090": {"vr": "PN"},
        "00100010": {"vr": "PN", "Value": {"Alphabetic": "Rubo DEMO"}},
        "00100020": {"vr": "LO", "Value": ["322-292-73-6"]},
        "00100030": {"vr": "DA", "Value": ["19580719"]},
        "00100040": {"vr": "CS", "Value": ["F"]},
        "0020000D": {"vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.16"]},
        "00200010": {"vr": "SH"},
        "00200011": {"vr": "IS", "Value": ["1"]}
    }
];

const EXPECTED_SEQUENCE_VALUE = [
    {
        "00081150": {"vr": "UI", "Value": ["1.2.840.10008.5.1.4.1.1.12.1"]},
        "00081155": {"vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.284980.19951129.170916.11"]}
    }
];
