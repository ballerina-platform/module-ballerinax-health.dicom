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

# Represents a DICOMweb related error.
public type Error distinct error<ErrorDetails>;

# Represents a DICOMweb processing related error.
public type ProcessingError distinct Error;

# Represents a DICOMweb validation related error.
public type ValidationError distinct Error;

# DICOMweb error details.
#
# + httpStatusCode - The HTTP status code associated with the error
# + internalError - Boolean flag to indicate if the error is an internal error
# + uuid - The unique identifier of the error  
# + diagnostic - Diagnostic information about the error. This is an optional parameter.
public type ErrorDetails record {
    int httpStatusCode;
    boolean internalError;
    string uuid;
    string? diagnostic;
};

# Represents a DICOMweb status report.
#
# + errorDetails - Specific details about the error
# + uri - The resource path of the request
public type StatusReport record {
    StatusReportErrorDetails errorDetails;
    string uri;
};

# DICOMweb status report error details.
#
# + message - The message describing the error 
# + diagnostic - Diagnostic information about the error. This is an optional parameter.
# + trackingId - The unique identifier of the error
public type StatusReportErrorDetails record {
    string message;
    string diagnostic?;
    string trackingId;
};

# DICOMweb error types
public enum ErrorType {
    PROCESSING_ERROR,
    VALIDATION_ERROR
}
