# Ballerina DICOMweb

## Overview

The `dicomweb` module provides DICOMweb-specific data types, error types, a response builder, and utility functions necessary for creating DICOMweb APIs. It implements the [DICOMweb standard](https://www.dicomstandard.org/using/dicomweb) (DICOM Part 18) for web-based DICOM services.

It is part of the [`ballerinax/health.dicom`](https://central.ballerina.io/ballerinax/health.dicom) family of packages.

## Compatibility

|                    | Version             |
| ------------------ | ------------------- |
| Ballerina Language | Swan Lake 2201.12.x |

---

## Features

- **DICOMweb Response Builder**: Build compliant DICOM JSON Model (DICOMweb) responses from parsed DICOM datasets.
- **Resource Types**: Full coverage of QIDO-RS, WADO-RS, and STOW-RS resource types.
- **Query Parameter Support**: Process and apply DICOMweb query parameters (`match`, `includefield`, `limit`, `offset`, `fuzzymatching`).
- **Error Handling**: Typed `ProcessingError` and `ValidationError` with HTTP status codes and diagnostic info.
- **Status Reports**: DICOMweb status report generation for error responses.

---

## Usage

### 1. Generate a DICOMweb Search Response (QIDO-RS)

Convert one or more parsed DICOM datasets into a standard DICOMweb JSON response using `generateResponse()`.

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;
import ballerinax/health.dicom.dicomweb;

public function main() returns error? {
    // Parse DICOM files
    dicom:File file1 = check dicomparser:parseFile("./study1.dcm", dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
    dicom:File file2 = check dicomparser:parseFile("./study2.dcm", dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);

    dicom:Dataset[] datasets = [file1.dataset, file2.dataset];

    // Generate a QIDO-RS "Search All Studies" response
    dicomweb:Response|dicomweb:Error response = dicomweb:generateResponse(datasets, dicomweb:SEARCH_ALL_STUDIES);

    if response is dicomweb:Response {
        // response is a ModelObject[] — a DICOMweb DICOM JSON array
        // Serialize to JSON using Ballerina's json:toJsonString()
    }
}
```

---

### 2. Available DICOMweb Resource Types

The `ResourceType` enum covers all WADO-RS, STOW-RS, and QIDO-RS resource types:

| Category | Resource Types |
|---|---|
| **QIDO-RS (Search)** | `SEARCH_ALL_STUDIES`, `SEARCH_STUDY_SERIES`, `SEARCH_STUDY_INSTANCES`, `SEARCH_ALL_SERIES`, `SEARCH_ALL_INSTANCES` |
| **WADO-RS (Retrieve)** | `RETRIEVE_STUDY_INSTANCES`, `RETRIEVE_SERIES_INSTANCES`, `RETRIEVE_INSTANCE` |
| **WADO-RS Metadata** | `RETRIEVE_STUDY_METADATA`, `RETRIEVE_SERIES_METADATA`, `RETRIEVE_INSTANCE_METADATA` |
| **WADO-RS Rendered** | `RETRIEVE_RENDERED_STUDY`, `RETRIEVE_RENDERED_SERIES`, `RETRIEVE_RENDERED_INSTANCE` |
| **WADO-RS Thumbnails** | `RETRIEVE_STUDY_THUMBNAIL`, `RETRIEVE_SERIES_THUMBNAIL`, `RETRIEVE_INSTANCE_THUMBNAIL` |
| **WADO-RS Pixel Data** | `RETRIEVE_STUDY_PIXEL_DATA`, `RETRIEVE_SERIES_PIXEL_DATA`, `RETRIEVE_FRAME_PIXEL_DATA` |
| **STOW-RS (Store)** | `STORE_STUDIES`, `STORE_STUDY` |

---

### 3. Using Query Parameters

Apply DICOMweb query parameters to filter and shape the response.

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomweb;

public function main() returns error? {
    dicom:Dataset[] datasets = [...]; // obtained from dicomparser

    // Build query parameters map
    dicomweb:QueryParameterMap queryParams = {
        // Match studies by PatientID
        "match": {"00100020": "PAT001"},

        // Include all attributes in the response
        "includefield": "all",

        // Limit response to 10 results
        "limit": 10,

        // Skip first 20 results (pagination)
        "offset": 20
    };

    dicomweb:Response|dicomweb:Error response = dicomweb:generateResponse(
            datasets, dicomweb:SEARCH_ALL_STUDIES, processedQueryParams = queryParams);
}
```

---

### 4. Working with Responses

A `dicomweb:Response` is a `ModelObject[]` — an array of JSON-representable DICOM attribute maps following the [DICOM JSON Model](https://dicom.nema.org/medical/dicom/current/output/html/part18.html#sect_F.2).

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomweb;

public function main() returns error? {
    dicom:Dataset[] datasets = [...];

    dicomweb:Response|dicomweb:Error response = dicomweb:generateResponse(datasets, dicomweb:SEARCH_ALL_STUDIES);
    if response is dicomweb:Response {
        // Each ModelObject is a map<AttributeObject>
        foreach dicomweb:ModelObject modelObject in response {
            // Access the PatientName attribute object (tag 00100010)
            dicomweb:AttributeObject? patientNameAttr = modelObject["00100010"];
            if patientNameAttr is dicomweb:AttributeObject {
                string vr = patientNameAttr.vr; // "PN"
                dicomweb:AttributeObjectValue? value = patientNameAttr.Value;
            }
        }
    }
}
```

---

### 5. Error Handling

The `dicomweb` module provides typed `ProcessingError` and `ValidationError` types, both carrying HTTP status codes and diagnostic information.

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomweb;

public function main() {
    dicom:Dataset[] datasets = [...];

    dicomweb:Response|dicomweb:Error response = dicomweb:generateResponse(datasets, dicomweb:SEARCH_ALL_STUDIES);
    if response is dicomweb:Error {
        dicomweb:ErrorDetails details = response.detail();
        int statusCode  = details.httpStatusCode;
        string errorId  = details.uuid;
        string? diag    = details.diagnostic;
    }
}
```

---

### 6. Using in a Ballerina HTTP Service

Build a DICOMweb-compatible QIDO-RS service endpoint:

```ballerina
import ballerina/http;
import ballerina/log;
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;
import ballerinax/health.dicom.dicomweb;

service /wado on new http:Listener(9090) {

    resource function get studies() returns json|http:InternalServerError {
        // Load and parse DICOM files
        dicom:File|dicom:ParsingError parsedFile = dicomparser:parseFile("./data/sample.dcm",
                dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
        if parsedFile is dicom:ParsingError {
            log:printError("Parsing error", parsedFile);
            return http:INTERNAL_SERVER_ERROR;
        }

        // Build DICOMweb response
        dicomweb:Response|dicomweb:Error response = dicomweb:generateResponse(
                [parsedFile.dataset], dicomweb:SEARCH_ALL_STUDIES);
        if response is dicomweb:Error {
            log:printError("DICOMweb response error", response);
            return http:INTERNAL_SERVER_ERROR;
        }
        return response.toJson();
    }
}
```

---

## Key Types

| Type | Description |
|---|---|
| `Response` | `ModelObject[]` — a DICOM JSON Model response array |
| `ModelObject` | `map<AttributeObject>` — one DICOM object's attributes |
| `AttributeObject` | A DICOM attribute with `vr`, `Value`, `BulkDataURI`, or `InlineBinary` |
| `ResourceType` | Enum of all supported DICOMweb resource types |
| `QueryParameterMap` | `map<QueryParameterValue>` — processed query parameters |
| `Error` | Base DICOMweb error (`ProcessingError` or `ValidationError`) |
| `StatusReport` | DICOMweb error status report structure |
| `MimeType` | Enum of supported MIME types (`application/dicom+json`, etc.) |

---

## Acknowledgements

The sample DICOM file(s) used as test resources in this package were sourced from [Rubo Medical Imaging](https://www.rubomedical.com/dicom_files/).

---

## Report Issues

To report bugs, request new features, or start new discussions, go to the [Ballerina Extended Library repository](https://github.com/ballerina-platform/ballerina-library).
