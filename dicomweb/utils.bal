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

import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerinax/health.dicom;

# Checks if a DICOM dataset matches a set of provided match parameters.
#
# + dataset - The DICOM dataset to be evaluated
# + matchParams - A map containing match parameters and their expected values for matching
# + return - `true` if match parameters are present in the dataset and their values match the expected values, otherwise `false`
public isolated function isMatchParamsMatching(dicom:Dataset dataset,
        MatchParameterMap matchParams) returns boolean {
    // Check if dataset contains these attributes and matching values
    foreach [string, MatchParameterValue] [attribute, value] in matchParams.entries() {
        if !isAttributeMatching(dataset, attribute, value) {
            return false;
        }
    }
    return true;
}

# Checks if a DICOM dataset contains a specific attribute with a matching value.
#
# + dataset - The DICOM dataset to be analysed
# + attribute - The DICOMweb attribute name to be checked
# + attributeValue - The expected value of the attribute for matching
# + return - `true` if the dataset contains the specified attribute with the matching value, otherwise `false`
public isolated function isAttributeMatching(dicom:Dataset dataset, string attribute,
        MatchParameterValue attributeValue) returns boolean {
    // Check if a matching attribute and attribute value exists in the dataset
    dicom:DataElement? attributeDataElement = getDataElementFromAttribute(dataset, attribute);
    if attributeDataElement is dicom:DataElement {
        return attributeDataElement.value == attributeValue;
    }
    return false;
}

# Checks whether a given string represents a valid DICOMweb attribute.
#
# + attribute - The string to be validated as a DICOMweb attribute
# + return - `true` if the string is a valid DICOMweb attribute, otherwise `false`
public isolated function isValidAttribute(string attribute) returns boolean
    => dicom:isValidTagStr(attribute) || dicom:isValidKeyword(attribute);

# Retrieves the DICOM tag from a DICOMweb attribute.
#
# + attribute - The DICOMweb attribute
# + return - The corresponding `dicom:Tag` if found, otherwise `()`
public isolated function getTagFromAttribute(string attribute) returns dicom:Tag? {
    if !isValidAttribute(attribute) {
        return;
    }
    // Assume attribute is a tag
    dicom:Tag|error? tag = dicom:strToTag(attribute);
    if tag is error { // Attribute is a keyword
        tag = dicom:getTagFromKeyword(attribute);
    }
    return tag is dicom:Tag ? tag : ();
}

# Checks if a match attribute is a valid resource match attribute.
#
# + matchAttribute - Match attribute to be checked
# + resourceType - Resource type
# + return - true if a valid resource match attribute, false otherwise
public isolated function isValidResourceMatchAttribute(string matchAttribute, ResourceType resourceType) returns boolean {
    if !isValidAttribute(matchAttribute) {
        return false;
    }

    // Assume attribute is a tag str
    dicom:Tag|error? tag = dicom:strToTag(matchAttribute);
    if tag is error { // Keyword
        tag = dicom:getTagFromKeyword(matchAttribute);
    }

    // At this point tag should be a valid dicom:Tag as it is a valid attribute

    // Get resource specific required attributes
    dicom:Tag[]? requiredMatchingAttributes = getResourceRequiredMatchingAttributes(resourceType);

    if tag !is dicom:Tag || requiredMatchingAttributes == () {
        return false;
    }

    return requiredMatchingAttributes.indexOf(tag) != ();
}

# Retrieves the `dicom:DataElement` corresponding to a specific attribute.
#
# + dataset - The DICOM dataset to be searched
# + attribute - The DICOMweb attribute
# + return - The corresponding `dicom:DataElement` if found, otherwise `()`
public isolated function getDataElementFromAttribute(dicom:Dataset dataset, string attribute) returns dicom:DataElement? {
    dicom:DataElement|error? dataElement = ();
    dicom:Tag? tag = getTagFromAttribute(attribute);
    if tag is dicom:Tag {
        dataElement = trap dataset.get(tag);
    }
    return dataElement is dicom:DataElement ? dataElement : ();
}

# Retrieve the necessary IE level match attributes for a given resource type.
#
# + resourceType - The DICOMweb resource type
# + return - A `dicom:Tag[]` if matching required attributes are found, otherwise `()`
public isolated function getResourceRequiredMatchingAttributes(ResourceType resourceType) returns dicom:Tag[]? {
    match resourceType {
        SEARCH_ALL_STUDIES => {
            return SEARCH_IE_LEVELS.get(STUDY);
        }
        SEARCH_STUDY_SERIES => {
            return SEARCH_IE_LEVELS.get(SERIES);
        }
        SEARCH_STUDY_INSTANCES => {
            return [
                ...SEARCH_IE_LEVELS.get(SERIES),
                ...SEARCH_IE_LEVELS.get(INSTANCE)
            ];
        }
        SEARCH_ALL_SERIES => {
            return [
                ...SEARCH_IE_LEVELS.get(STUDY),
                ...SEARCH_IE_LEVELS.get(SERIES)
            ];
        }
        SEARCH_STUDY_SERIES_INSTANCES => {
            return SEARCH_IE_LEVELS.get(INSTANCE);
        }
        SEARCH_ALL_INSTANCES => {
            return [
                ...SEARCH_IE_LEVELS.get(STUDY),
                ...SEARCH_IE_LEVELS.get(SERIES),
                ...SEARCH_IE_LEVELS.get(INSTANCE)
            ];
        }
    }
    return;
}

# Retrieves resource specific attributes to be included in the response.
#
# + resourceType - The DICOMweb resource type
# + return - A `dicom:Tag[]` if matching attributes are found, otherwise `()`
public isolated function getResourceResponseAttributes(ResourceType resourceType) returns dicom:Tag[]? {
    match resourceType {
        SEARCH_ALL_STUDIES => {
            return SEARCH_RESPONSE_ATTRIBUTES.get(STUDY);
        }
        SEARCH_ALL_SERIES|SEARCH_STUDY_SERIES => {
            return SEARCH_RESPONSE_ATTRIBUTES.get(SERIES);
        }
        SEARCH_ALL_INSTANCES|SEARCH_STUDY_INSTANCES|SEARCH_STUDY_SERIES_INSTANCES => {
            return SEARCH_RESPONSE_ATTRIBUTES.get(INSTANCE);
        }
    }
    return;
}

# Creates an internal DICOMweb error.
#
# + message - The error message
# + errorType - The error type. This is an optional parameter.
# + diagnostic - The error diagnostic information. This is an optional parameter.
# + cause - The error cause. This is an optional parameter.
# + return - The created internal DICOMweb `Error`
public isolated function createInternalDicomwebError(string message, ErrorType? errorType = (),
        string? diagnostic = (), error? cause = ()) returns Error {
    return createTypedError(message, errorType, diagnostic, cause, internalError = true);
}

# Creates a DICOMweb error.
#
# + message - The error message
# + errorType - The error type. This is an optional parameter.
# + diagnostic - The error diagnostic information. This is an optional parameter.
# + cause - The error cause. This is an optional parameter. 
# + httpStatusCode - (default: 500) The HTTP status code. This is an optional parameter.
# + return - The created DICOMweb 'Error'
public isolated function createDicomwebError(string message, ErrorType? errorType = (), string? diagnostic = (),
        error? cause = (), int httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR) returns Error {
    return createTypedError(message, errorType, diagnostic, cause, httpStatusCode, internalError = false);
}

isolated function createTypedError(string message, ErrorType? errorType = (), string? diagnostic = (),
        error? cause = (), int httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR, boolean internalError = false,
        string uuid = uuid:createType1AsString()) returns Error {
    match errorType {
        PROCESSING_ERROR => {
            return error ProcessingError(message, cause, diagnostic = diagnostic, httpStatusCode = httpStatusCode,
                    internalError = true, uuid = uuid);
        }
        VALIDATION_ERROR => {
            return error ValidationError(message, cause, diagnostic = diagnostic, httpStatusCode = httpStatusCode,
                    internalError = internalError, uuid = uuid);
        }
        _ => {
            return error Error(message, cause, diagnostic = diagnostic, httpStatusCode = httpStatusCode,
                    internalError = internalError, uuid = uuid);
        }
    }
}

# Constructs a DICOMweb status report from an `error`.
#
# + err - The error to be used to construct the status report
# + uri - The URI to be included in the status report
# + logError - (default: true) Boolean flag indicating whether to log the error
# (only when it's an internal DICOMweb `Error`, or when it's not a DICOMweb 'Error'). This is an optional parameter.
# + return - The constructed `StatusReport`
public isolated function constructStatusReport(error err, string uri, boolean logError = true) returns StatusReport {
    string errorUuid;
    if err is Error {
        if !err.detail().internalError {
            return errorToStatusReport(err, uri);
        }
        // Internal error
        errorUuid = err.detail().uuid;
        if logError {
            string message = string `${errorUuid}: ${err.message()}`;
            log:printError(message, err, err.stackTrace());
        }
    } else { // Non-DICOMweb error
        errorUuid = uuid:createType1AsString();
        if logError {
            string message = string `${errorUuid}: ${err.message()}`;
            log:printError(message, err, err.stackTrace());
        }
    }
    // Status report error details
    StatusReportErrorDetails errorDetails = {
        message: err.message(),
        trackingId: errorUuid
    };
    return {
        errorDetails: errorDetails,
        uri: uri
    };
}

# Constructs a DICOMweb status report from an `Error`.
#
# + err - The error to be used to construct the status report
# + uri - The URI to be included in the status report
# + return - The constructed `StatusReport`
isolated function errorToStatusReport(Error err, string uri) returns StatusReport {
    ErrorDetails & readonly errorDetails = err.detail();
    StatusReportErrorDetails statusReportErrorDetails = {
        message: err.message(),
        diagnostic: errorDetails.diagnostic,
        trackingId: errorDetails.uuid
    };
    return {
        errorDetails: statusReportErrorDetails,
        uri: uri
    };
}
