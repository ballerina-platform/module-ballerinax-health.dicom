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
import ballerinax/health.dicom.dicomweb;

# DICOM preprocessor implementation.
public isolated class DicomPreprocessor {
    final ApiConfig apiConfig;
    final map<QueryParamConfig> & readonly queryParamConfigMap;

    # Initializes a new instance of the `DicomPreprocessor`.
    #
    # + apiConfig - The API configuration.
    public isolated function init(ApiConfig apiConfig) {
        self.apiConfig = apiConfig;
        // Construct query param config map
        map<QueryParamConfig> queryParamConfigs = {};
        foreach QueryParamConfig paramConfig in apiConfig.queryParameters {
            queryParamConfigs[paramConfig.name] = paramConfig;
        }
        self.queryParamConfigMap = queryParamConfigs.cloneReadOnly();
    }

    # Processes a DICOMweb search transaction resource.
    #
    # + httpRequest - The HTTP request
    # + httpContext - The HTTP context
    # + searchResourceType - The type of the search resource
    # + return - A `dicomweb:Error` if an error occurred during processing, or `()` otherwise
    public isolated function processSearchResource(http:Request httpRequest, http:RequestContext httpContext,
            dicomweb:ResourceType searchResourceType) returns dicomweb:Error? {
        log:printDebug("Preprocessing search resource");
        // Validate HTTP headers
        dicomweb:RequestMimeHeaders requestHeaders = check validateRequestHeaders(httpRequest);

        // Process query parameters
        dicomweb:QueryParameterMap processedQueryParams
            = check processQueryParams(httpRequest.getQueryParams(), searchResourceType, self.queryParamConfigMap);

        // Create HTTP request
        HttpRequest & readonly request = createHttpRequestRecord(httpRequest, ());

        // Create DICOM request
        DicomRequest dicomRequest
            = new (requestHeaders.acceptType, processedQueryParams.cloneReadOnly(), searchResourceType);

        // Create DICOM context
        DicomContext dicomContext = new (dicomRequest, request);

        // Set DICOM context inside HTTP context
        setDicomContext(dicomContext, httpContext);
    }

    # Processes a DICOMweb retrieve transaction resource.
    #
    # + httpRequest - The HTTP request
    # + httpContext - The HTTP context
    # + searchResourceType - The type of the retrieve resource
    # + return - A `dicomweb:Error` if an error occurred during processing, otherwise `()`
    public isolated function processRetrieveResource(http:Request httpRequest, http:RequestContext httpContext,
            dicomweb:ResourceType searchResourceType) returns dicomweb:Error? {
        // TODO: Implement
        // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1537
    }

    # Processes a DICOMweb store transaction resource.
    #
    # + httpRequest - The HTTP request
    # + httpContext - The HTTP context
    # + searchResourceType - The type of the store resource
    # + return - A `dicomweb:Error` if an error occurred during processing, otherwise `()`
    public isolated function processStoreResource(http:Request httpRequest, http:RequestContext httpContext,
            dicomweb:ResourceType searchResourceType) returns dicomweb:Error? {
        // TODO: Implement
        // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1538
    }
}

# Validates HTTP request headers.
#
# + httpRequest - The HTTP request
# + return - A `dicomweb:RequestMimeHeaders` if the validation is successful, 
# or a `dicomweb:Error` if the validation fails
isolated function validateRequestHeaders(http:Request httpRequest) returns dicomweb:RequestMimeHeaders|dicomweb:Error {
    dicomweb:RequestMimeHeaders requestMimeHeaders = {};
    // TODO: Validate content type
    // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1539

    // Validate Accept header
    // Only search transaction media types are supported for now
    // Based off of Sections 8.7.7 and  10.6.4 in Part 18
    string|http:HeaderNotFoundError acceptHeader = httpRequest.getHeader("Accept");

    if acceptHeader is http:HeaderNotFoundError {
        string message = "Missing mandatory 'Accept' header in request";
        return dicomweb:createDicomwebError(message, dicomweb:VALIDATION_ERROR,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    match acceptHeader {
        ""|"*/*"|dicomweb:MIME_TYPE_JSON|dicomweb:MIME_TYPE_DICOM_JSON => {
            // Use default JSON type
            requestMimeHeaders.acceptType = dicomweb:MIME_TYPE_JSON;
        }
        _ => {
            string message = string `Unsupported 'Accept' header value in request: ${acceptHeader}`;
            string diagnostic = string `Supported values for 'Accept' header: ${joinWithComma(dicomweb:MIME_TYPE_JSON,
                    dicomweb:MIME_TYPE_DICOM_JSON)}`;
            return dicomweb:createDicomwebError(message, dicomweb:VALIDATION_ERROR,
                    diagnostic, httpStatusCode = http:STATUS_NOT_ACCEPTABLE);
        }
    }

    return requestMimeHeaders;
}

# Creates a `HttpRequest` record from a `http:Request`.
#
# + request - The `http:Request` from which the headers are extracted
# + payload - The payload
# + return - The constructed `HttpRequest` record
isolated function createHttpRequestRecord(http:Request request, json|xml? payload) returns HttpRequest & readonly {
    map<string[]> headers = {};

    foreach string headerName in request.getHeaderNames() {
        string[]|http:HeaderNotFoundError headerValues = request.getHeaders(headerName);
        if headerValues is string[] {
            headers[headerName] = headerValues;
        }
    }

    return {
        headers: headers.cloneReadOnly(),
        payload: payload.cloneReadOnly()
    };
}

# Associates a DICOM context with an HTTP context.
#
# + dicomContext - The DICOM context
# + httpContext - The HTTP context
isolated function setDicomContext(DicomContext dicomContext, http:RequestContext httpContext) {
    httpContext.set(DICOM_CONTEXT_PROP_NAME, dicomContext);
}



# Processes HTTP query parameters for a DICOMweb resource.
#
# + queryParams - The query params to be processed 
# + resourceType - The DICOMweb resource type the request was made
# + queryParamConfigMap - The query param configuration map
# + return - A `dicomweb:QueryParameterMap` containing the processed params if the processing is successful, 
# or a `dicomweb:Error` if unsuccessful
isolated function processQueryParams(map<string[]> queryParams, dicomweb:ResourceType resourceType,
        map<QueryParamConfig> queryParamConfigMap) returns dicomweb:QueryParameterMap|dicomweb:Error {
    dicomweb:QueryParameterMap processedParams = {};

    // Dicom attribute/value pairs for match query parameter
    dicomweb:MatchParameterMap matchParameters = {};

    // Process each query parameter
    foreach [string, string[]] [param, value] in queryParams.entries() {
        if queryParamConfigMap.hasKey(param) { // If there's a pre-processor given in the param config
            QueryParamConfig paramConfig = queryParamConfigMap.get(param);
            if !paramConfig.active {
                string message = string `Unsupported query parameter: ${paramConfig.name}`;
                string diagnostic = string `Supported query parameters: ` +
                        string `${joinWithComma(...extractActiveQueryParameterNames(queryParamConfigMap))}`;
                return dicomweb:createDicomwebError(message, diagnostic = diagnostic,
                        httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
            }
            // Get the pre-processor and process the value
            QueryParamPreProcessor? preProcessor = paramConfig.preProcessor;
            if preProcessor is QueryParamPreProcessor {
                dicomweb:QueryParameterValue processedValue = check preProcessor(value);
                processedParams[param] = processedValue;
            }
        } else if dicomweb:isValidResourceMatchAttribute(param, resourceType) { // Possible attribute matching
            // TODO: Multiple values are allowed if a UID list matching
            // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1540
            if value.length() == 1 { // Only one value is allowed for match attributes
                matchParameters[param] = value[0];
            }
        }
    }

    if matchParameters.length() != 0 {
        processedParams[dicomweb:MATCH] = matchParameters;
    }

    return processedParams;
}

# Extracts active query parameter names from a query parameter config map.
#
# + paramConfigMap - The query parameter config map
# + return - An array of extracted query parameter names
isolated function extractActiveQueryParameterNames(map<QueryParamConfig> paramConfigMap) returns string[] {
    string[] activeParams = [];
    foreach [string, QueryParamConfig] [param, paramConfig] in paramConfigMap.entries() {
        if paramConfig.active {
            activeParams.push(param);
        }
    }
    return activeParams;
}
