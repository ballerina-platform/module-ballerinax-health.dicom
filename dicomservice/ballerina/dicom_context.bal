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

import ballerinax/health.dicom.dicomweb;

# Class representing a DICOM context.
public isolated class DicomContext {

    private MessageDirection direction = IN;
    private final DicomRequest dicomRequest;
    private final HttpRequest & readonly httpRequest;
    private boolean inErrorState = false;
    private int errorCode = 500;

    # Initializes a new instance of the `DicomContext`.
    #
    # + dicomRequest - The DICOM request associated with the context
    # + httpRequest - The HTTP request associated with the context
    public isolated function init(DicomRequest dicomRequest, HttpRequest & readonly httpRequest) {
        self.dicomRequest = dicomRequest;
        self.httpRequest = httpRequest;
    }

    # Sets the message direction of the context.
    #
    # + direction - The message direction to be set
    public isolated function setDirection(MessageDirection direction) {
        lock {
            self.direction = direction;
        }
    }

    # Retrieves the message direction of the context.
    #
    # + return - The current message direction of the context
    public isolated function getDirection() returns MessageDirection {
        lock {
            return self.direction;
        }
    }

    # Checks if the context is in an error state.
    #
    # + return - `true` if the context is in an error state, `false` otherwise
    public isolated function isInErrorState() returns boolean {
        lock {
            return self.inErrorState;
        }
    }

    # Sets the error state of the context.
    #
    # + inErrorState - The error state to be set
    public isolated function setInErrorState(boolean inErrorState) {
        lock {
            self.inErrorState = inErrorState;
        }
    }

    # Retrieves the error code of the context.
    #
    # + return - The current error code of the context
    public isolated function getErrorCode() returns int {
        lock {
            return self.errorCode;
        }
    }

    # Sets the error code of the context.
    #
    # + errorCode - The error code to be set
    public isolated function setErrorCode(int errorCode) {
        lock {
            self.errorCode = errorCode;
        }
    }

    # Retrieves the DICOM request associated with the context.
    #
    # + return - The DICOM request associated with the context
    public isolated function getDicomRequest() returns DicomRequest {
        return self.dicomRequest;
    }

    # Retrieves the HTTP request associated with the context.
    #
    # + return - The HTTP request associated with the context
    public isolated function getHttpRequest() returns HttpRequest & readonly {
        return self.httpRequest;
    }

    # Retrieves the resource type of the DICOM request associated with the context.
    #
    # + return - The resource type of the DICOM request
    public isolated function getDicomRequestResourceType() returns dicomweb:ResourceType {
        return self.dicomRequest.getResourceType();
    }

    # Retrieves the client accept format of the DICOM request associated with the context.
    #
    # + return - The client accept format of the DICOM request
    public isolated function getClientAcceptFormat() returns dicomweb:MimeType {
        return self.dicomRequest.getAcceptType();
    }

    # Retrieves the query parameters of the DICOM request associated with the context.
    #
    # + return - The query parameters map of the DICOM request
    public isolated function getRequestQueryParameters() returns dicomweb:QueryParameterMap & readonly {
        return self.dicomRequest.getQueryParameters();
    }

    # Retrieves the query parameter value of a query parameter of the DICOM request associated with the context.
    #
    # + param - The query parameter to get the value of
    # + return - The query parameter value if found, `()` otherwise
    public isolated function getRequestQueryParameterValue(string param) returns dicomweb:QueryParameterValue? {
        dicomweb:QueryParameterMap & readonly queryParams = self.dicomRequest.getQueryParameters();
        if queryParams.hasKey(param) {
            return queryParams.get(param);
        }
        // Could be a match parameter
        if queryParams.hasKey(dicomweb:MATCH) {
            dicomweb:MatchParameterMap|error matchParams = queryParams.get(dicomweb:MATCH).ensureType();
            if matchParams is dicomweb:MatchParameterMap && matchParams.hasKey(param) {
                return matchParams.get(param);
            }
        }
        return;
    }
    
}
