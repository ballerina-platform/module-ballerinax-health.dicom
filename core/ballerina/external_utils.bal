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

import ballerina/jballerina.java;

# Converts an integer bytes representation to its integer value.
#
# + bytes - The integer byte array
# + byteOrder - The byte order of the array
# + return - The converted integer value
isolated function javaBytesToInt(byte[] bytes, ByteOrder byteOrder) returns int = @java:Method {
    name: "bytesToInt",
    'class: "io.ballerinax.health.dicom.ByteUtils"
} external;

# Converts a float bytes representation to its float value.
# 
# + bytes - The float byte array
# + byteOrder - The byte order of the array
# + return - The converted float value
isolated function javaBytesToFloat(byte[] bytes, ByteOrder byteOrder) returns float = @java:Method {
    name: "bytesToFloat",
    'class: "io.ballerinax.health.dicom.ByteUtils"
} external;

# Converts an integer value to its bytes representation.
#
# + n - The integer value to be converted
# + byteOrder - The byte order to be used for the conversion
# + return - The bytes representation of the integer value
isolated function javaIntToBytes(int n, ByteOrder byteOrder) returns byte[] = @java:Method {
    name: "intToBytes",
    'class: "io.ballerinax.health.dicom.ByteUtils"
} external;

# Converts a float value to its bytes representation.
#
# + n - The float value to be converted
# + byteOrder - The byte order to be used for the conversion
# + return - The bytes representation of the float value
isolated function javaFloatToBytes(float n, ByteOrder byteOrder) returns byte[] = @java:Method {
    name: "floatToBytes",
    'class: "io.ballerinax.health.dicom.ByteUtils"
} external;
