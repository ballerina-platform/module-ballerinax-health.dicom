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

import ballerina/io;
import ballerinax/health.dicom;

# Reads the preamble from a DICOM file.
#
# + fileByteChannel - The byte channel containing the DICOM file data
# + return - A `byte[]` containing the preamble data, or a `dicom:Error` if the reading fails
public isolated function readPreamble(io:ReadableByteChannel fileByteChannel) returns byte[]|dicom:Error {
    // First 128 bytes of the file is the preamble
    // From Section 7.1 in Part 10
    do {
        byte[] preamble = check fileByteChannel.read(128);
        if preamble.length() != 128 {
            fail error dicom:Error(string `Invalid preamble length: Expected 128 bytes, Found ${preamble.length()} bytes`);
        }
        return preamble;
    } on fail error e {
        return error dicom:Error("Error reading preamble", e);
    }
}

# Checks if a file is a valid DICOM file
#
# + fileByteChannel - The byte channel containing the DICOM file data 
# + preambleRead - A flag indicating whether the preamble has already been read
# + return - `true` if the file is a valid DICOM file, `false` otherwise
public isolated function isValidFile(io:ReadableByteChannel fileByteChannel,
        boolean preambleRead = false) returns boolean {
    // DICOM prefix is the 4 bytes after the preamble
    // Based off of Section 7.1 in Part 10
    // If the preamble has not been read yet, attempt to read it now
    if !preambleRead {
        byte[]|error preamble = readPreamble(fileByteChannel);
        if preamble is error {
            return false;
        }
    }
    byte[]|io:Error prefix = fileByteChannel.read(4);
    return prefix is byte[] && prefix == DICOM_PREFIX;
}

# Checks if a given transfer syntax is supported.
#
# + transferSyntax - The transfer syntax to be checked
# + return - `true` if the transfer syntax is supported, `false` otherwise
isolated function isSupportedTransferSyntax(dicom:TransferSyntax transferSyntax) returns boolean
        => SUPPORTED_TRANSFER_SYNTAXES.indexOf(transferSyntax) != ();
