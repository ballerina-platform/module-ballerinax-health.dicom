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
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomweb;

// Query param pre-processors

# Default preprocessor for the "includefield" query parameter.
#
# + paramValue - The raw "includefield" parameter value
# + return - The preprocessed `dicomweb:IncludeFieldParameterValue`, or a `dicomweb:ValidationError` if pre-processing
# fails.
public isolated function includeFieldQueryParamPreProcessor(string[] paramValue)
        returns dicomweb:IncludeFieldParameterValue|dicomweb:ValidationError {
    // Includefield param value is either a list of attributes, or the single keyword "all"
    // Based off of Section 8.3.4.3 in Part 18
    dicomweb:IncludeFieldParameterValue processedValue;
    string[] keywords = [];
    dicom:Tag[] tags = [];

    foreach string val in paramValue {
        if val == "" {
            continue;
        } else if val == "all" {
            processedValue = val;
            return processedValue;
        } else if dicom:isValidTagStr(val) {
            dicom:Tag|error tag = dicom:strToTag(val);
            // Can safely ignore the error case here as `dicom:isValidTagStr()` uses `dicom:strToTag()`,
            // i.e., the tag will always be a `dicom:Tag`
            if tag is dicom:Tag {
                tags.push(tag);
            }
        } else if dicom:isValidKeyword(val) {
            keywords.push(val);
        } else {
            string message = string `Invalid value for 'includefield' query parameter: ${val}`;
            string diagnostic = string `Valid values for 'includefield' query parameter: ` +
                string `comma-separated list of attributes, 'all'`;
            return <dicomweb:ValidationError>dicomweb:createDicomwebError(message, dicomweb:VALIDATION_ERROR,
                diagnostic, httpStatusCode = http:STATUS_BAD_REQUEST);
        }
    }

    processedValue = tags.length() == 0 ? keywords : tags;
    
    return processedValue;
}

# Default preprocessor for the "limit" query parameter.
#
# + paramValue - The raw "limit" parameter value
# + return - The preprocessed `dicomweb:LimitParameterValue`, or a `dicomweb:ValidationError` if pre-processing
# fails.
public isolated function limitQueryParamPreProcessor(string[] paramValue)
        returns dicomweb:LimitParameterValue|dicomweb:ValidationError {
    // Limit parameter specifies the maximum number of matches the origin server shall return in a single response
    // Limit parameter value is an unsigned integer
    // Based off of Section 8.3.4.4 in Part 18
    do {
        if paramValue.length() != 1 {
            fail error("Invalid number of 'limit' parameter values");
        }
        // Construct int from string
        int|error 'limit = int:fromString(paramValue[0]);
        if 'limit is error {
            fail error("'limit' parameter value must be an integer");
        }
        if 'limit < 0 {
            fail error("'limit' parameter value must be an unsigned integer");
        }
        return 'limit;
    } on fail error e {
        string message = string `Invalid value for 'limit' query parameter: ${joinWithComma(...paramValue)}`;
        string diagnostic = string `${e.message()}. ` +
                string `Valid value for 'limit' query parameter: an unsigned integer (uint)`;
        return <dicomweb:ValidationError>dicomweb:createDicomwebError(message, dicomweb:VALIDATION_ERROR,
                diagnostic, e, http:STATUS_BAD_REQUEST);
    }
}

# Default preprocessor for the "offset" query parameter.
#
# + paramValue - The raw "offset" parameter value
# + return - The preprocessed `dicomweb:OffsetParameterValue`, or a `dicomweb:ValidationError` if pre-processing
# fails.
public isolated function offsetQueryParamPreProcessor(string[] paramValue)
        returns dicomweb:OffsetParameterValue|dicomweb:ValidationError {
    // Offset parameter specifies the maximum number of matches the origin server shall return in a single response
    // Offset parameter value is an unsigned integer
    // Based off of Section 8.3.4.4 in Part 18
    do {
        if paramValue.length() != 1 {
            fail error("Invalid number of offset parameter values");
        }
        // Construct int from string
        int|error offset = int:fromString(paramValue[0]);
        if offset is error {
            fail error("Offset parameter value must be an integer");
        }
        if offset < 0 {
            fail error("Offset parameter must be an unsigned integer");
        }
        return offset;
    } on fail error e {
        string message = string `Invalid value for 'offset' query parameter: ${joinWithComma(...paramValue)}`;
        string diagnostic = string `${e.message()}. ` +
                string `Valid value for 'offset' query parameter: an unsigned integer (uint)`;
        return <dicomweb:ValidationError>dicomweb:createDicomwebError(message, dicomweb:VALIDATION_ERROR,
                diagnostic, e, http:STATUS_BAD_REQUEST);
    }
}

// Query param post processors

# Default post processor for the "limit" query parameter.
#
# + response - The HTTP response of the resource
# + 'limit - The preprocessed "limit" parameter value
# + return - A `dicomweb:Error` if post processing fails, or `()` otherwise
public isolated function limitQueryParamPostProcessor(http:Response response,
        dicomweb:QueryParameterValue 'limit) returns dicomweb:Error? {
    // Don't have to validate the query parameter value as it's already validated in the preprocessor
    json|error responsePayload = response.getJsonPayload();
    if responsePayload is json[] && 'limit is int {
        if responsePayload.length() > 'limit {
            responsePayload.setLength('limit);
        }
    }
}

# Default post processor for the "offset" query parameter.
#
# + response - The HTTP response of the resource
# + offset - The preprocessed "offset" parameter value
# + return - A `dicomweb:Error` if post processing fails, or `()` otherwise
public isolated function offsetQueryParamPostProcessor(http:Response response,
        dicomweb:QueryParameterValue offset) returns dicomweb:Error? {
    // Don't have to validate the query parameter value as it's already validated in the preprocessor
    json|error responsePayload = response.getJsonPayload();
    if responsePayload is json[] && offset is int {
        json[]|error offsetResponse = trap responsePayload.slice(offset);
        if offsetResponse is json[] {
            response.setPayload(offsetResponse);
        }
    }
}

# Applies a post processor of a query parameter to an HTTP response.
#
# + response - The HTTP response to be post processed
# + paramConfig - The query parameter configuration that holds the post processor
# + paramValue - The query parameter value
# + return - A `dicomweb:Error` if the post processing result in an error
isolated function postProcessQueryParam(http:Response response, QueryParamConfig paramConfig,
        dicomweb:QueryParameterValue paramValue) returns dicomweb:Error? {
    if !paramConfig.active {
        return;
    }
    QueryParamPostProcessor? postProcessor = paramConfig.postProcessor;
    if postProcessor == () {
        return;
    }
    return postProcessor(response, paramValue);
}
