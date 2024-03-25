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

# Class representing a DICOM request.
public isolated class DicomRequest {

    private final dicomweb:MimeType acceptType;
    private final dicomweb:QueryParameterMap & readonly queryParams;
    private final dicomweb:ResourceType resourceType;

    # Initializes a new instance of the `DicomRequest`.
    #
    # + acceptType - The MIME type that the client can accept
    # + queryParams - The processed query parameters
    # + resourceType - The DICOMweb resource type
    public isolated function init(dicomweb:MimeType acceptType, dicomweb:QueryParameterMap & readonly queryParams,
            dicomweb:ResourceType resourceType) {
        self.acceptType = acceptType;
        self.queryParams = queryParams;
        self.resourceType = resourceType;
    }

    # Retrieves the accept type of the request.
    #
    # + return - The MIME type that the client can accept
    public isolated function getAcceptType() returns dicomweb:MimeType {
        return self.acceptType;
    }

    # Retrieves the query parameters of the request.
    #
    # + return - The query parameters map of the request
    public isolated function getQueryParameters() returns dicomweb:QueryParameterMap & readonly {
        return self.queryParams;
    }

    # Retrieves the match query parameters of the request.
    #
    # + return - The match query parameters of the request if exists, or `()` otherwise
    public isolated function getMatchQueryParameters() returns dicomweb:MatchParameterMap? & readonly {
        dicomweb:MatchParameterMap|error matchParams = trap self.queryParams.get(dicomweb:MATCH).ensureType();
        return matchParams is dicomweb:MatchParameterMap ? matchParams.cloneReadOnly() : ();
    }

    # Retrieves the resource type of the request.
    #
    # + return - The resource type of the request
    public isolated function getResourceType() returns dicomweb:ResourceType {
        return self.resourceType;
    }
    
}
