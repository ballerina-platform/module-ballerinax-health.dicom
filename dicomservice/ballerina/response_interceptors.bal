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

# The DICOM response interceptor class that is used to intercept and post-process DICOM service responses.
public isolated service class DicomResponseInterceptor {
    *http:ResponseInterceptor;

    final ApiConfig apiConfig;
    final map<QueryParamConfig> & readonly queryParamConfigMap;

    # Initializes a new instance of the `DicomResponseInterceptor`
    #
    # + apiConfig - The DICOM service API config
    public function init(ApiConfig apiConfig) {
        self.apiConfig = apiConfig;
        map<QueryParamConfig> queryParamConfigs = {};
        foreach QueryParamConfig paramConfig in apiConfig.queryParameters {
            queryParamConfigs[paramConfig.name] = paramConfig;
        }
        self.queryParamConfigMap = queryParamConfigs.cloneReadOnly();
    }

    # Intercepts a response.
    #
    # + httpContext - The HTTP context
    # + response - The HTTP response
    # + return - The next service to be invoked or a `dicomweb:Error` if an error occurs
    isolated remote function interceptResponse(http:RequestContext httpContext,
            http:Response response) returns http:NextService|dicomweb:Error? {
        // Set response content type
        // Only application/dicom+json is supported
        error? setContentTypeRes = response.setContentType(dicomweb:MIME_TYPE_DICOM_JSON);
        if setContentTypeRes is error {
            // Ignore
        }
        // Post process response
        DicomContext? dicomContext = getDicomContext(httpContext);
        if dicomContext is DicomContext {
            check self.postProcessResponse(dicomContext, response);
        }
        return getNextService(httpContext);
    }

    # Post-processes a DICOM service response.
    #
    # + dicomContext - The DICOM context
    # + response - The HTTP response
    # + return - An optional Error if an error occurred during processing
    isolated function postProcessResponse(DicomContext dicomContext, http:Response response) returns dicomweb:Error? {
        dicomweb:QueryParameterMap & readonly queryParams = dicomContext.getRequestQueryParameters();
        foreach [string, dicomweb:QueryParameterValue] [param, value] in queryParams.entries() {
            if self.queryParamConfigMap.hasKey(param) { // If there's a post-processor given in the param config
                QueryParamConfig paramConfig = self.queryParamConfigMap.get(param);
                check postProcessQueryParam(response, paramConfig, value);
            }
        }
    }
}

# The DICOM response error interceptor class that is used to intercept and handle errors.
public isolated service class DicomResponseErrorInterceptor {
    *http:ResponseErrorInterceptor;

    # Intercepts a error.
    #
    # + err - The error that occurred
    # + request - The HTTP request that was sent
    # + return - An HTTP status code response based on the error
    isolated remote function interceptResponseError(error err, http:Request request)
            returns http:BadRequest|http:NotFound|http:InternalServerError|http:NotAcceptable|http:NotImplemented {
        return constructHttpStatusCodeResponse(err, getBasePath(request.rawPath), dicomweb:MIME_TYPE_DICOM_JSON);
    }
}

# Constructs an HTTP status code response from an error.
#
# + err - The error to be used
# + uri - The base URI of the request
# + mediaType - The value of response `Content-type` header
# + return - The constructed HTTP status code response
public isolated function constructHttpStatusCodeResponse(error err, string uri,
        string mediaType) returns http:BadRequest|http:NotFound|http:InternalServerError
                |http:NotAcceptable|http:NotImplemented {
    if err !is dicomweb:Error {
        http:InternalServerError internalServerError = {
            body: dicomweb:constructStatusReport(err, uri),
            mediaType: mediaType
        };
        return internalServerError;
    }
    // dicomweb:Error 
    match err.detail().httpStatusCode {
        http:STATUS_BAD_REQUEST => {
            http:BadRequest badRequest = {
                body: dicomweb:constructStatusReport(err, uri),
                mediaType: mediaType
            };
            return badRequest;
        }
        http:STATUS_NOT_FOUND => {
            http:NotFound notFound = {
                body: dicomweb:constructStatusReport(err, uri),
                mediaType: mediaType
            };
            return notFound;
        }
        http:STATUS_INTERNAL_SERVER_ERROR => {
            http:InternalServerError internalServerError = {
                body: dicomweb:constructStatusReport(err, uri),
                mediaType: mediaType
            };
            return internalServerError;
        }
        http:STATUS_NOT_ACCEPTABLE => {
            http:NotAcceptable notAcceptable = {
                body: dicomweb:constructStatusReport(err, uri),
                mediaType: mediaType
            };
            return notAcceptable;
        }
        http:STATUS_NOT_IMPLEMENTED => {
            http:NotImplemented notImplemented = {
                body: dicomweb:constructStatusReport(err, uri),
                mediaType: mediaType
            };
            return notImplemented;
        }
        _ => {
            http:InternalServerError internalServerError = {
                body: dicomweb:constructStatusReport(err, uri),
                mediaType: mediaType
            };
            return internalServerError;
        }
    }
}

# Retrieves the next HTTP service from an HTTP context.
#
# + context - The HTTP context
# + return - The retrieved `http:NextService?` if the retrieval is successful, or a `dicomweb:Error` if unsuccessful
isolated function getNextService(http:RequestContext context) returns http:NextService?|dicomweb:Error {
    http:NextService|error? next = context.next();
    if next is error {
        string message = "Error occurred while retrieving next HTTP service";
        return dicomweb:createInternalDicomwebError(message, dicomweb:PROCESSING_ERROR);
    }
    return next;
}
