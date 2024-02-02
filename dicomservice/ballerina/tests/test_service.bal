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

Service dicomService = service object {
    resource function get studies(DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error {
        return [];
    }

    resource function get series(DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error {
        return [];
    }

    resource function get instances(DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error {
        return [];
    }

    resource function get studies/[string study]/series(DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error {
        return [];
    }

    resource function get studies/[string study]/series/[string series]/instances(DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error {
        return [];
    }

    resource function get studies/[string study](DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns anydata {
        return [];
    }

    resource function get studies/[string study]/metadata(DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns anydata {
        return [];
    }
};
