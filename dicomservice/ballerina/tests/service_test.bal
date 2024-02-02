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
import ballerina/test;
import ballerinax/health.dicom.dicomweb;

Listener dicomListener = check new (9292, DEFAULT_API_CONFIG);
http:Client dicomClient = check new ("http://localhost:9292");

@test:BeforeSuite
function startService() returns error? {
    check dicomListener.attach(dicomService);
    check dicomListener.'start();
}

@test:Config {groups: ["service"]}
function retrieveStudyInstancesTest() returns error? {
    string study = "1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.16";
    http:Response response = check dicomClient->/studies/[study]({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    });
    test:assertTrue(response.statusCode == 501);
    test:assertEquals(response.getContentType(), dicomweb:MIME_TYPE_DICOM_JSON);
}

@test:Config {groups: ["service"]}
function retrieveStudyMetadataTest() returns error? {
    string study = "1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.16";
    http:Response response = check dicomClient->/studies/[study]/metadata({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    });
    test:assertTrue(response.statusCode == 501);
    test:assertEquals(response.getContentType(), dicomweb:MIME_TYPE_DICOM_JSON);
}

@test:Config {groups: ["service"]}
function searchAllStudiesValidRequestTest() returns error? {
    http:Response response = check dicomClient->/studies({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    });
    test:assertTrue(response.statusCode == 200);
    test:assertEquals(response.getContentType(), dicomweb:MIME_TYPE_DICOM_JSON);
}

@test:Config {groups: ["service"]}
function searchAllSeriesValidRequestTest() returns error? {
    http:Response response = check dicomClient->/series({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    });
    test:assertTrue(response.statusCode == 200);
    test:assertEquals(response.getContentType(), dicomweb:MIME_TYPE_DICOM_JSON);
}

@test:Config {groups: ["service"]}
function searchAllInstancesValidRequestTest() returns error? {
    http:Response response = check dicomClient->/instances({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    });
    test:assertTrue(response.statusCode == 200);
    test:assertEquals(response.getContentType(), dicomweb:MIME_TYPE_DICOM_JSON);
}

@test:Config {groups: ["service"]}
function searchStudiesSeriesValidRequestTest() returns error? {
    string study = "1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.16";
    http:Response response = check dicomClient->/studies/[study]/series({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    });
    test:assertTrue(response.statusCode == 200);
    test:assertEquals(response.getContentType(), dicomweb:MIME_TYPE_DICOM_JSON);
}

@test:Config {groups: ["service"]}
function searchStudySeriesInstancesValidRequestTest() returns error? {
    string study = "1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.16";
    string series = "1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.17";
    http:Response response = check dicomClient->/studies/[study]/series/[series]/instances({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    });
    test:assertTrue(response.statusCode == 200);
    test:assertEquals(response.getContentType(), dicomweb:MIME_TYPE_DICOM_JSON);
}

@test:Config {groups: ["service"]}
function searchAllStudiesInvalidRequestMissingAcceptHeaderTest() returns error? {
    http:Response response = check dicomClient->get("/studies");
    test:assertTrue(response.statusCode == 400);

    json payload = check response.getJsonPayload();
    dicomweb:StatusReport? statusReport = getStatusReportFromJsonPayload(payload);
    if statusReport is dicomweb:StatusReport {
        test:assertTrue(statusReport.errorDetails.message.startsWith("Missing mandatory 'Accept'"));
    } else {
        test:assertFail("Request with missing 'Accept' header must return a dicomweb:StatusReport error response");
    }
}

@test:Config {groups: ["service"]}
function searchAllStudiesInvalidRequestUnsupportedAcceptHeaderTest() returns error? {
    http:Response response = check dicomClient->/studies({
        Accept: dicomweb:MIME_TYPE_XML
    });
    test:assertTrue(response.statusCode == 406);
}

@test:Config {groups: ["service", "query_params"]}
function searchAllStudiesValidRequestValidIncludeFieldQueryParamKeywordTest() returns error? {
    http:Response response = check dicomClient->/studies({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    }, includefield = "Modality");
    test:assertTrue(response.statusCode == 200);
}

@test:Config {groups: ["service", "query_params"]}
function searchAllStudiesValidRequestValidIncludeFieldQueryParamTagTest() returns error? {
    http:Response response = check dicomClient->/studies({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    }, includefield = "00080060");
    test:assertTrue(response.statusCode == 200);
}

@test:Config {groups: ["service", "query_params"]}
function searchAllStudiesValidRequestValidIncludeFieldQueryParamAllTest() returns error? {
    http:Response response = check dicomClient->/studies({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    }, includefield = "all");
    test:assertTrue(response.statusCode == 200);
}

@test:Config {groups: ["service", "query_params"]}
function searchAllStudiesInvalidRequestInvalidIncludeFieldQueryParamTest() returns error? {
    http:Response response = check dicomClient->/studies({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    }, includefield = "NotAValidKeyword");
    test:assertTrue(response.statusCode == 400);
}

@test:Config {groups: ["service", "query_params"]}
function searchAllStudiesValidRequestValidLimitQueryParamTest() returns error? {
    http:Response response = check dicomClient->/studies({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    }, 'limit = 1);
    test:assertTrue(response.statusCode == 200);
}

@test:Config {groups: ["service", "query_params"]}
function searchAllStudiesInvalidRequestInvalidLimitQueryParamTest() returns error? {
    [string, int, int[]] invalidValues = ["invalidValue", -5, [1, 3, 4]];
    foreach string|int|int[] value in invalidValues {
        http:Response response = check dicomClient->/studies({
            Accept: dicomweb:MIME_TYPE_DICOM_JSON
        }, 'limit = value);
        test:assertTrue(response.statusCode == 400);
    }
}

@test:Config {groups: ["service", "query_params"]}
function searchAllStudiesValidRequestValidOffsetQueryParamTest() returns error? {
    http:Response response = check dicomClient->/studies({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    }, offset = 2);
    test:assertTrue(response.statusCode == 200);
}

@test:Config {groups: ["service", "query_params"]}
function searchAllStudiesInvalidRequestInvalidOffsetQueryParamTest() returns error? {
    [string, int, int[]] invalidValues = ["invalidValue", -5, [1, 3, 4]];
    foreach string|int|int[] value in invalidValues {
        http:Response response = check dicomClient->/studies({
            Accept: dicomweb:MIME_TYPE_DICOM_JSON
        }, offset = value);
        test:assertTrue(response.statusCode == 400);
    }
}

@test:Config {groups: ["service", "query_params"]}
function searchAllStudiesUnsupportedQueryParamTest() returns error? {
    http:Response response = check dicomClient->/studies({
        Accept: dicomweb:MIME_TYPE_DICOM_JSON
    }, fuzzymatching = true);
    test:assertTrue(response.statusCode == 501);
}

@test:Config {groups: ["service"]}
function invalidRequestNonExistingPathTest() returns error? {
    http:Response response = check dicomClient->get("/nonexistingpath");
    test:assertTrue(response.statusCode == 404);

    json payload = check response.getJsonPayload();
    dicomweb:StatusReport? statusReport = getStatusReportFromJsonPayload(payload);
    if statusReport is dicomweb:StatusReport {
        test:assertTrue(statusReport.errorDetails.message.startsWith("Path not found"));
    } else {
        test:assertFail("Request to a non-existing path must return a dicomweb:StatusReport error response");
    }
}

function getStatusReportFromJsonPayload(json payload) returns dicomweb:StatusReport? {
    dicomweb:StatusReport|error statusReport = payload.fromJsonWithType();
    if statusReport is dicomweb:StatusReport {
        return statusReport;
    }
    return;
}
