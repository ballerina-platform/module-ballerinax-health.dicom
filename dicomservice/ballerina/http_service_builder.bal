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
import ballerinax/health.dicom.dicomweb;

# Constructs a DICOM specific HTTP service for the DICOM service.
#
# + dicomServiceHolder - The DICOM service holder instance
# + apiConfig - The API configuration
# + return - The constructed HTTP service object
isolated function getHttpService(DicomServiceHolder dicomServiceHolder, ApiConfig apiConfig) returns http:Service {
    http:InterceptableService httpService = isolated service object {

        private final DicomServiceHolder dicomServiceHolder = dicomServiceHolder;
        private final DicomPreprocessor dicomPreprocessor = new DicomPreprocessor(apiConfig);

        public function createInterceptors() returns [DicomResponseErrorInterceptor, DicomResponseInterceptor] {
            return [new DicomResponseErrorInterceptor(), new DicomResponseInterceptor(apiConfig)];
        }

        isolated resource function get [string... path](http:Request req, http:RequestContext ctx) returns any|error {
            // Get DICOM service from the holder
            Service dicomService = self.dicomServiceHolder.getDicomService();
            // Get matching method in the DICOM service
            handle? resourceMethod = getResourceMethod(dicomService, path, http:GET);

            if resourceMethod == () { // No matching method
                string message = string `Path not found: ${req.extraPathInfo}`;
                return dicomweb:createDicomwebError(message, httpStatusCode = http:STATUS_NOT_FOUND);
            }

            DicomContext? dicomContext;
            any|error executionResult = ();

            // A GET request could be a Search or a Retrieve transaction resource request
            dicomweb:ResourceType? resourceType = getSearchResourceFromPath(path);
            if resourceType is dicomweb:ResourceType { // Search resource
                // Get path params from the path
                map<string> pathParams = getResourcePathParams(resourceType, path);
                // Process search resource
                check self.dicomPreprocessor.processSearchResource(req, ctx, resourceType);
                // Get DICOM context from HTTP context
                dicomContext = getDicomContext(ctx);
                if dicomContext == () {
                    return createDicomContextNotFoundError();
                }
                // Execute search transaction resource
                executionResult = executeSearchTransactionResource(resourceType, pathParams,
                            dicomContext, dicomService, resourceMethod);
                // If execution is erroneous, update DICOM context accordingly
                if executionResult is error {
                    dicomContext.setInErrorState(true);
                    dicomContext.setErrorCode(getErrorCode(executionResult));
                }
            } else { // Could be a retrieve resource
                resourceType = getRetrieveResourceFromPath(path);
                if resourceType is dicomweb:ResourceType {
                    // TODO: Implement
                    // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1537
                    return createTransactionNotSupportedError("Retrieve transaction (WADO-RS)");
                } else {
                    return createInvalidResourceError(req.extraPathInfo);
                }
            }
            return executionResult;
        }

        isolated resource function post [string... path](http:Request req, http:RequestContext ctx) returns any|error {
            // Get DICOM service from the holder
            Service dicomService = self.dicomServiceHolder.getDicomService();
            // Get matching method in the DICOM service
            handle? resourceMethod = getResourceMethod(dicomService, path, http:POST);

            if resourceMethod == () { // No matching method
                return createPathNotFoundError(req.extraPathInfo);
            }

            json|http:ClientError payload = req.getJsonPayload();
            if payload is http:ClientError { // Invalid payload
                return createInvalidPayloadError();
            }

            dicomweb:ResourceType? storeResourceType = getStoreResourceFromPath(path);
            if storeResourceType == () { // Invalid DICOMweb resource
                return createInvalidResourceError(req.extraPathInfo);
            }

            // TODO: Implement
            // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1538
            return createTransactionNotSupportedError("Store transaction (STOW-RS)");
        }

    };
    
    return httpService;
}

# Retrieves the matching DICOMweb search resource type from a request path.
#
# + path - The request path
# + return - The matching `dicomweb:ResourceType` if a matching resource is found, otherwise `()`
isolated function getSearchResourceFromPath(string[] path) returns dicomweb:ResourceType? {
    match path {
        ["studies"] => {
            return dicomweb:SEARCH_ALL_STUDIES;
        }
        ["series"] => {
            return dicomweb:SEARCH_ALL_SERIES;
        }
        ["instances"] => {
            return dicomweb:SEARCH_ALL_INSTANCES;
        }
        ["studies", _, "series"] => {
            return dicomweb:SEARCH_STUDY_SERIES;
        }
        ["studies", _, "instances"] => {
            return dicomweb:SEARCH_STUDY_INSTANCES;
        }
        ["studies", _, "series", _, "instances"] => {
            return dicomweb:SEARCH_STUDY_SERIES_INSTANCES;
        }
        _ => {
            return;
        }
    }
}

# Retrieves the matching DICOMweb retrieve resource type from a request path.
#
# + path - The request path
# + return - The matching `dicomweb:ResourceType` if a matching resource is found, otherwise `()`
public isolated function getRetrieveResourceFromPath(string[] path) returns dicomweb:ResourceType? {
    // Determine the retrieve transaction resource from path
    match path {
        ["studies", _] => {
            return dicomweb:RETRIEVE_STUDY_INSTANCES;
        }
        ["studies", _, "series", _] => {
            return dicomweb:RETRIEVE_SERIES_INSTANCES;
        }
        ["studies", _, "series", _, "instances", _] => {
            return dicomweb:RETRIEVE_INSTANCE;
        }
        ["studies", _, "metadata"] => {
            return dicomweb:RETRIEVE_STUDY_METADATA;
        }
        ["studies", _, "series", _, "metadata"] => {
            return dicomweb:RETRIEVE_SERIES_METADATA;
        }
        ["studies", _, "series", _, "instances", _, "metadata"] => {
            return dicomweb:RETRIEVE_INSTANCE_METADATA;
        }
        ["studies", _, "rendered"] => {
            return dicomweb:RETRIEVE_RENDERED_STUDY;
        }
        ["studies", _, "series", _, "rendered"] => {
            return dicomweb:RETRIEVE_RENDERED_SERIES;
        }
        ["studies", _, "series", _, "instances", _, "rendered"] => {
            return dicomweb:RETRIEVE_RENDERED_INSTANCE;
        }
        ["studies", _, "series", _, "instances", _, "frames", _, "rendered"] => {
            return dicomweb:RETRIEVE_RENDERED_FRAMES;
        }
        ["studies", _, "thumbnail"] => {
            return dicomweb:RETRIEVE_STUDY_THUMBNAIL;
        }
        ["studies", _, "series", _, "thumbnail"] => {
            return dicomweb:RETRIEVE_SERIES_THUMBNAIL;
        }
        ["studies", _, "series", _, "instances", _, "thumbnail"] => {
            return dicomweb:RETRIEVE_INSTANCE_THUMBNAIL;
        }
        ["studies", _, "series", _, "instances", _, "frames", _, "thumbnail"] => {
            return dicomweb:RETRIEVE_FRAME_THUMBNAIL;
        }
        ["studies", _, "bulkdata"] => {
            return dicomweb:RETRIEVE_STUDY_BULKDATA;
        }
        ["studies", _, "series", _, "bulkdata"] => {
            return dicomweb:RETRIEVE_SERIES_BULKDATA;
        }
        ["studies", _, "series", _, "instances", _, "bulkdata"] => {
            return dicomweb:RETRIEVE_INSTANCE_BULKDATA;
        }
        [_] => {
            return dicomweb:RETRIEVE_BULKDATA;
        }
        _ => {
            return;
        }
    }
}

# Retrieves the matching DICOMweb store resource type from a request path.
#
# + path - The request path
# + return - The matching `dicomweb:ResourceType` if a matching resource is found, otherwise `()`
isolated function getStoreResourceFromPath(string[] path) returns dicomweb:ResourceType? {
    match path {
        ["studies"] => {
            return dicomweb:STORE_STUDIES;
        }
        ["studies", _] => {
            return dicomweb:STORE_STUDY;
        }
        _ => {
            return;
        }
    }
}

# Executes a search resource based on the search resource type.
#
# + searchResource - The search resource type
# + pathParams - The path parameters map
# + dicomContext - The DICOM context
# + dicomService - The DICOM service object
# + resourceMethod - The resource method to be executed
# + return - The result of the execution
isolated function executeSearchTransactionResource(dicomweb:ResourceType searchResource, map<string> pathParams,
        DicomContext dicomContext, Service dicomService, handle resourceMethod) returns any|error {
    match searchResource {
        dicomweb:SEARCH_STUDY_SERIES|dicomweb:SEARCH_STUDY_INSTANCES => {
            return executeWithStudy(pathParams.get("study"), dicomContext,
                dicomContext.getRequestQueryParameters(), dicomService, resourceMethod);
        }
        dicomweb:SEARCH_STUDY_SERIES_INSTANCES => {
            return executeWithStudyAndSeries(pathParams.get("study"), pathParams.get("series"),
                dicomContext, dicomContext.getRequestQueryParameters(), dicomService,
                resourceMethod);
        }
        _ => { // Resources with no path params
            return executeWithNoPathParams(dicomContext, dicomContext.getRequestQueryParameters(),
                dicomService, resourceMethod);
        }
    }
}

# Retrieves the resource path parameters from a path.
#
# + resourceType - The resource type
# + path - The path to extract the parameters from
# + return - The extracted resource path parameters
isolated function getResourcePathParams(dicomweb:ResourceType resourceType, string[] path) returns map<string> {
    // Match and extract path parameter values from the path
    // TODO: Add retrieve and store transaction resources
    // Issues: https://github.com/wso2-enterprise/open-healthcare/issues/1537, 
    // https://github.com/wso2-enterprise/open-healthcare/issues/1538
    match resourceType {
        dicomweb:SEARCH_STUDY_SERIES|dicomweb:SEARCH_STUDY_INSTANCES => {
            return {"study": path[1]};
        }
        dicomweb:SEARCH_STUDY_SERIES_INSTANCES => {
            return {"study": path[1], "series": path[3]};
        }
        _ => {
            return {};
        }
    }
}

# Retrieves the DICOM context from an HTTP context.
#
# + httpContext - The HTTP context to extract the DICOM context from
# + return - The extracted DICOM context if exists, `()` otherwise
isolated function getDicomContext(http:RequestContext httpContext) returns DicomContext? {
    if httpContext.hasKey(DICOM_CONTEXT_PROP_NAME) {
        http:ReqCtxMember dicomContext = httpContext.get(DICOM_CONTEXT_PROP_NAME);
        return dicomContext is DicomContext ? dicomContext : ();
    }
    return;
}

# Retrieves the matching error code for an error.
#
# + err - The error to extract the error code from
# + return - The matching error code
isolated function getErrorCode(error err) returns int {
    if err is dicomweb:Error && !err.detail().internalError {
        return err.detail().httpStatusCode;
    }
    return http:STATUS_INTERNAL_SERVER_ERROR;
}

# Constructs a path not found error message.
#
# + extraPathInfo - The extra path information to be used in the error message
# + return - The constructed error message
isolated function createPathNotFoundError(string extraPathInfo) returns dicomweb:Error =>
    dicomweb:createDicomwebError(string `Path not found: ${extraPathInfo}`, httpStatusCode = http:STATUS_NOT_FOUND);

# Constructs an invalid payload error message.
#
# + return - The constructed error message
isolated function createInvalidPayloadError() returns dicomweb:Error =>
    dicomweb:createDicomwebError("Invalid payload", httpStatusCode = http:STATUS_BAD_REQUEST);

# Constructs an invalid resource error message.
#
# + extraPathInfo - The extra path information to be used in the error message
# + return - The constructed error message
isolated function createInvalidResourceError(string extraPathInfo) returns dicomweb:Error {
    string message = string `Invalid DICOMweb resource: ${extraPathInfo}`;
    string diagnostic = string `Check the conformance statement for supported resources`;
    return dicomweb:createDicomwebError(message, dicomweb:VALIDATION_ERROR,
        diagnostic, httpStatusCode = http:STATUS_BAD_REQUEST);
}

# Constructs a transaction not supported error message.
#
# + 'transaction - The unsupported transaction
# + return - The constructed error message
isolated function createTransactionNotSupportedError(string 'transaction) returns dicomweb:Error {
    string message = string `${'transaction} resources are not supported yet`;
    string diagnostic = "Check the conformance statement for supported transactions";
    return dicomweb:createDicomwebError(message, httpStatusCode = http:STATUS_NOT_IMPLEMENTED,
            diagnostic = diagnostic);
}

# Constructs a DICOM context not found error message.
#
# + return - The constructed error message
isolated function createDicomContextNotFoundError() returns dicomweb:Error =>
    dicomweb:createInternalDicomwebError("DICOM context not found");
