## Overview

The `dicomservice` module contains a custom service type that can be used to implement DICOMweb APIs. This service provides a range of features that make the API development straightforward and convenient.

## Usage

### DICOMweb API with Default API Config

Implement a DICOMweb API with the default API config the `dicomservice` module provides. This API config uses the pre and post processors included in the `dicomservice` module.

```ballerina
import ballerinax/health.dicom.dicomservice;
import ballerinax/health.dicom.dicomweb;

service /dicomweb on new dicomservice:Listener(9090, dicomservice:DEFAULT_API_CONFIG) {
    isolated resource function get studies(dicomservice:DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error? {
        // API resource implementation
    }
}
```

### DICOMweb API with Custom API Config

Instead of the default config, a custom API config can be defined and used,

```ballerina
import ballerina/http;
import ballerinax/health.dicom.dicomservice;
import ballerinax/health.dicom.dicomweb;

// Sample custom limit parameter pre-processor
isolated function customLimitQueryParamPreProcessor(string[] paramValue)
        returns dicomweb:QueryParameterValue|dicomweb:Error {
    int|error 'limit = int:fromString(paramValue[0]);
    if 'limit is int && 'limit >= 0 {
        return 'limit;
    }
    return dicomweb:createDicomwebError("'limit' parameter value must be an unsigned integer", dicomweb:VALIDATION_ERROR);
}

// Sample custom limit parameter post-processor
isolated function customLimitQueryParamPostProcessor(http:Response response,
        dicomweb:QueryParameterValue 'limit) returns dicomweb:Error? {
    json|error responsePayload = response.getJsonPayload();
    if responsePayload is json[] && 'limit is int {
        if responsePayload.length() > 'limit {
            responsePayload.setLength('limit);
        }
    }
}

dicomservice:ApiConfig apiConfig = {
    queryParameters: [
        {
            name: dicomweb:LIMIT,
            active: true,
            preProcessor: customLimitQueryParamPreProcessor,
            postProcessor: customLimitQueryParamPostProcessor
        }
    ]
};

service /dicomweb on new dicomservice:Listener(9090, apiConfig) {
    isolated resource function get studies(dicomservice:DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error? {
       // API resource implementation 
    }
}
```
