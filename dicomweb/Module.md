## Overview

The `dicomweb` module contains DICOMweb specific data types, error types, a response builder, and other utility functions necessary for creating DICOMweb APIs.

## Usage

### Build DICOMweb Response (DICOM JSON Model)

Build DICOMweb resource specific responses using `dicomweb:generateResponse()` function,

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;
import ballerinax/health.dicom.dicomweb;

public function main() returns error? {
    // Data Set 1 from a sample file 1
    dicom:File parsedFile1 = check dicomparser:parseFile("./sample1.dcm", dicom:EXPLICIT_VR_LITTLE_ENDIAN);
    dicom:Dataset dataset1 = parsedFile1.dataset; 

    // Data Set 2 from a sample file 2
    dicom:File parsedFile2 = check dicomparser:parseFile("./sample2.dcm", dicom:EXPLICIT_VR_LITTLE_ENDIAN);
    dicom:Dataset dataset2 = parsedFile2.dataset;

    dicom:Dataset[] datasets = [dataset1, dataset2];

    // Generate DICOMweb response for "All Studies" resource in "Search Transaction (QIDO-RS)"
    dicomweb:Response|dicomweb:Error allStudiesResponse = dicomweb:generateResponse(datasets, dicomweb:SEARCH_ALL_STUDIES);
}
```
