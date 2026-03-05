# Ballerina DICOM Service

## Overview

The `dicomservice` module provides a custom Ballerina service type for building DICOMweb APIs. It wraps a standard HTTP listener with DICOM-specific request processing — including header validation, query parameter pre/post processing, and a `DicomContext` object to enrich resource function handlers.

It is part of the [`ballerinax/health.dicom`](https://central.ballerina.io/ballerinax/health.dicom) family of packages.

## Compatibility

|                    | Version             |
| ------------------ | ------------------- |
| Ballerina Language | Swan Lake 2201.12.x |

---

## Features

- **Custom Listener**: `dicomservice:Listener` wraps a Ballerina HTTP listener with DICOMweb-specific processing.
- **DicomContext**: A per-request context object providing access to the parsed DICOM request, query parameters, MIME type, and error state.
- **Request Header Validation**: Automatically validates DICOMweb request headers (e.g., `Accept` header).
- **Query Parameter Processing**: Built-in processors for standard query parameters (`includefield`, `limit`, `offset`, `fuzzymatching`) with support for custom pre/post processors.
- **Default API Config**: `DEFAULT_API_CONFIG` provides sensible defaults for all standard query parameters.
- **Error Handling**: Automatic status report generation for validation and processing errors.

---

## Usage

### 1. DICOMweb Service with Default API Config

The simplest way to create a DICOMweb service is using the provided `DEFAULT_API_CONFIG`. This activates built-in processors for `includefield`, `limit`, and `offset` query parameters.

```ballerina
import ballerinax/health.dicom.dicomservice;
import ballerinax/health.dicom.dicomweb;

service /dicomweb on new dicomservice:Listener(9090, dicomservice:DEFAULT_API_CONFIG) {

    isolated resource function get studies(dicomservice:DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error? {
        // context holds request metadata; queryParams already processed by the framework
        // implement your data retrieval and response building here
        return [];
    }

    isolated resource function get studies/[string studyInstanceUID]/series(
            dicomservice:DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error? {
        return [];
    }
}
```

---

### 2. DICOMweb Service with Custom API Config

Override query parameter handling with custom pre-processors and post-processors.

```ballerina
import ballerina/http;
import ballerinax/health.dicom.dicomservice;
import ballerinax/health.dicom.dicomweb;

// Custom pre-processor for the 'limit' query parameter
isolated function customLimitPreProcessor(string[] paramValue)
        returns dicomweb:QueryParameterValue|dicomweb:Error {
    int|error 'limit = int:fromString(paramValue[0]);
    if 'limit is int && 'limit >= 0 {
        return 'limit;
    }
    return dicomweb:createDicomwebError("'limit' must be an unsigned integer", dicomweb:VALIDATION_ERROR);
}

// Custom post-processor to trim response to 'limit' size
isolated function customLimitPostProcessor(http:Response response,
        dicomweb:QueryParameterValue 'limit) returns dicomweb:Error? {
    json|error payload = response.getJsonPayload();
    if payload is json[] && 'limit is int && payload.length() > 'limit {
        payload.setLength('limit);
    }
}

dicomservice:ApiConfig apiConfig = {
    queryParameters: [
        {
            name: dicomweb:LIMIT,
            active: true,
            preProcessor: customLimitPreProcessor,
            postProcessor: customLimitPostProcessor
        },
        {
            name: dicomweb:INCLUDEFIELD,
            active: true
            // Uses the built-in dicomservice pre-processor by default when none is specified
        },
        {
            name: dicomweb:FUZZYMATCHING,
            active: false // Disable unsupported parameters
        }
    ]
};

service /dicomweb on new dicomservice:Listener(9090, apiConfig) {

    isolated resource function get studies(dicomservice:DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error? {
        return [];
    }
}
```

---

### 3. Using DicomContext

The `DicomContext` object is injected into every resource function and provides rich request metadata.

```ballerina
import ballerinax/health.dicom.dicomservice;
import ballerinax/health.dicom.dicomweb;

service /dicomweb on new dicomservice:Listener(9090, dicomservice:DEFAULT_API_CONFIG) {

    isolated resource function get studies(dicomservice:DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error? {

        // Get the DICOMweb resource type (e.g., SEARCH_ALL_STUDIES)
        dicomweb:ResourceType resourceType = context.getDicomRequestResourceType();

        // Get the client's accepted MIME type from the Accept header
        dicomweb:MimeType acceptFormat = context.getClientAcceptFormat();

        // Retrieve the processed query parameters map
        dicomweb:QueryParameterMap & readonly params = context.getRequestQueryParameters();

        // Retrieve a specific query parameter value by name
        dicomweb:QueryParameterValue? limitVal = context.getRequestQueryParameterValue(dicomweb:LIMIT);

        // Check direction: IN (incoming request) or OUT (response going out)
        dicomservice:MessageDirection direction = context.getDirection();

        // Check if the context is in an error state
        if context.isInErrorState() {
            int errorCode = context.getErrorCode();
            // Handle error state
        }

        return [];
    }
}
```

---

### 4. Complete Example: QIDO-RS Study Search

A complete DICOMweb QIDO-RS study search endpoint backed by DICOM file parsing.

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;
import ballerinax/health.dicom.dicomweb;
import ballerinax/health.dicom.dicomservice;

// Pre-load datasets at startup
final dicom:Dataset[] & readonly datasets = loadDatasets();

function loadDatasets() returns dicom:Dataset[] & readonly {
    dicom:Dataset[] result = [];
    string[] dicomFiles = ["./data/study1.dcm", "./data/study2.dcm"];
    foreach string filePath in dicomFiles {
        dicom:File|dicom:ParsingError parsed = dicomparser:parseFile(filePath,
                dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
        if parsed is dicom:File {
            result.push(parsed.dataset);
        }
    }
    return result.cloneReadOnly();
}

service /wado on new dicomservice:Listener(9090, dicomservice:DEFAULT_API_CONFIG) {

    // GET /wado/studies
    isolated resource function get studies(dicomservice:DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error? {
        return dicomweb:generateResponse(datasets, dicomweb:SEARCH_ALL_STUDIES,
                processedQueryParams = queryParams);
    }

    // GET /wado/studies/{studyInstanceUID}/series
    isolated resource function get studies/[string studyInstanceUID]/series(
            dicomservice:DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error? {
        return dicomweb:generateResponse(datasets, dicomweb:SEARCH_STUDY_SERIES,
                processedQueryParams = queryParams);
    }

    // GET /wado/studies/{studyInstanceUID}/series/{seriesInstanceUID}/instances
    isolated resource function get studies/[string studyInstanceUID]/series/[string seriesInstanceUID]/instances(
            dicomservice:DicomContext context,
            dicomweb:QueryParameterMap queryParams) returns dicomweb:Response|dicomweb:Error? {
        return dicomweb:generateResponse(datasets, dicomweb:SEARCH_STUDY_SERIES_INSTANCES,
                processedQueryParams = queryParams);
    }
}
```

---

## Sample HTTP Requests

Assuming the service runs at `http://localhost:9090/wado`, here are sample `curl` requests for each supported endpoint. The **`Accept: application/dicom+json`** header is **required** on all requests.

### QIDO-RS — Search All Studies

```bash
curl -X GET "http://localhost:9090/wado/studies" \
  -H "Accept: application/dicom+json"
```

**Response** `200 OK`
```json
[
  {
    "00080020": { "vr": "DA", "Value": ["20010103"] },
    "00100010": { "vr": "PN", "Value": [{ "Alphabetic": "Smith^John" }] },
    "00100020": { "vr": "LO", "Value": ["PAT001"] },
    "0020000D": { "vr": "UI", "Value": ["1.3.12.2.1107.5.4.3.19951114.94101.16"] }
  }
]
```

### QIDO-RS — Search All Series

```bash
curl -X GET "http://localhost:9090/wado/series" \
  -H "Accept: application/dicom+json"
```

### QIDO-RS — Search Series Within a Study

```bash
curl -X GET "http://localhost:9090/wado/studies/1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.16/series" \
  -H "Accept: application/dicom+json"
```

### QIDO-RS — Search Instances Within a Series

```bash
curl -X GET "http://localhost:9090/wado/studies/1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.16/series/1.3.12.2.1107.5.4.3.4975316777216.19951114.94101.17/instances" \
  -H "Accept: application/dicom+json"
```

---

### Query Parameters

#### `includefield` — add extra attributes to the response

```bash
# Include by keyword
curl -X GET "http://localhost:9090/wado/studies?includefield=Modality" \
  -H "Accept: application/dicom+json"

# Include by tag hex (8-character uppercase)
curl -X GET "http://localhost:9090/wado/studies?includefield=00080060" \
  -H "Accept: application/dicom+json"

# Include all available attributes
curl -X GET "http://localhost:9090/wado/studies?includefield=all" \
  -H "Accept: application/dicom+json"
```

#### `limit` — restrict the number of results

```bash
curl -X GET "http://localhost:9090/wado/studies?limit=10" \
  -H "Accept: application/dicom+json"
```

#### `offset` — paginate results

```bash
curl -X GET "http://localhost:9090/wado/studies?limit=10&offset=20" \
  -H "Accept: application/dicom+json"
```

---

### Error Responses

| Scenario | Status Code | Notes |
|---|---|---|
| Missing `Accept` header | `400 Bad Request` | Framework enforces mandatory Accept header |
| Unsupported `Accept` value (e.g., `application/xml`) | `406 Not Acceptable` | Only `application/dicom+json` / `application/json` supported |
| Invalid `limit` or `offset` (negative or non-integer) | `400 Bad Request` | Parameter validation by built-in pre-processor |
| Unsupported parameter (e.g., `fuzzymatching=true`) | `501 Not Implemented` | Parameter marked `active: false` in `DEFAULT_API_CONFIG` |
| Non-existing path | `404 Not Found` | Returns a `StatusReport` body |

**Example error body** (`application/dicom+json`):
```json
{
  "errorDetails": {
    "message": "Missing mandatory 'Accept' header in the request",
    "trackingId": "550e8400-e29b-41d4-a716-446655440000"
  },
  "uri": "/wado/studies"
}
```

---

## Key Types

| Type | Description |
|---|---|
| `Listener` | Custom listener wrapping `http:Listener` with DICOM processing |
| `Service` | Distinct service object type for DICOM services |
| `DicomContext` | Per-request context with request metadata and error state |
| `ApiConfig` | Configuration for query parameter processors |
| `QueryParamConfig` | Configuration for a single query parameter (name, active, pre/post processor) |
| `QueryParamPreProcessor` | `isolated function (string[]) returns QueryParameterValue\|Error` |
| `QueryParamPostProcessor` | `isolated function (http:Response, QueryParameterValue) returns Error?` |
| `MessageDirection` | `IN` or `OUT` representing request/response direction |
| `HttpRequest` | Record holding HTTP headers and payload |

## Default API Config

`DEFAULT_API_CONFIG` pre-configures the following query parameters:

| Parameter | Status | Notes |
|---|---|---|
| `includefield` | Active | Adds extra attributes to the response |
| `limit` | Active | Limits number of results |
| `offset` | Active | Paginates results |
| `fuzzymatching` | Inactive | Not yet implemented |

---

## Report Issues

To report bugs, request new features, or start new discussions, go to the [Ballerina Extended Library repository](https://github.com/ballerina-platform/ballerina-library).
