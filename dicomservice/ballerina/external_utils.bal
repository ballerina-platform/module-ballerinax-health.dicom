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

import ballerina/jballerina.java;
import ballerinax/health.dicom.dicomweb;

# Retrieves the matching resource method from the DICOM service.
#
# + serviceObject - The DICOM service object
# + requestPath - The request path
# + accessor - The HTTP method
# + return - The resource method handle if there's a matching resource, or `()` otherwise
isolated function getResourceMethod(service object {} serviceObject, string[] requestPath, string accessor)
    returns handle? = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.Utils"
} external;

# Executes a resource method that does not contain any path parameters.
#
# + dicomContext - The DICOM context to be passed as a parameter to the resource method
# + queryParams - The map of processed query parameters to be passed as a parameter to the resource method
# + serviceObject - The DICOM service object
# + resourceMethod - The resource method to be executed
# + return - The result of executing the resource method
isolated function executeWithNoPathParams(DicomContext dicomContext, dicomweb:QueryParameterMap queryParams,
        service object {} serviceObject, handle resourceMethod) returns any|error = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.HttpToDicomwebAdaptor"
} external;

# Executes a resource method that contains the study path parameter.
#
# + study - The study path parameter value
# + dicomContext - The DICOM context to be passed as a parameter to the resource method
# + queryParams - The map of processed query parameters to be passed as a parameter to the resource method
# + serviceObject - The DICOM service object
# + resourceMethod - The resource method to be executed
# + return - The result of executing the resource method
isolated function executeWithStudy(string study, DicomContext dicomContext, dicomweb:QueryParameterMap queryParams,
        service object {} serviceObject, handle resourceMethod) returns any|error = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.HttpToDicomwebAdaptor"
} external;

# Executes a resource method that contains the study and series path parameters.
#
# + study - The study path parameter value
# + series - The series path parameter value
# + dicomContext - The DICOM context to be passed as a parameter to the resource method
# + queryParams - The map of processed query parameters to be passed as a parameter to the resource method
# + serviceObject - The DICOM service object
# + resourceMethod - The resource method to be executed
# + return - The result of executing the resource method
isolated function executeWithStudyAndSeries(string study, string series, DicomContext dicomContext,
        dicomweb:QueryParameterMap queryParams, service object {} serviceObject,
        handle resourceMethod) returns any|error = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.HttpToDicomwebAdaptor"
} external;

isolated function setModule() = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.ModuleUtils"
} external;
