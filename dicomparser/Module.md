## Overview

The `dicomparser` module provides essential parsers designed for decoding DICOM entities. These parsers cover a range of DICOM components, including DICOM files, data sets, VRs, and data element values.

## Usage

### Parse a DICOM Image File

Parse DICOM image files using the generic `dicomparser:parse()` function or the dedicated `dicomparser:parseFile()` function.

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;

public function main() {
    // Parse a dicom file encoded in explicit vr little endian transfer syntax
    dicom:File|dicom:Dataset|dicom:ParsingError parsedFile1 = dicomparser:parse("./sample1.dcm", dicom:EXPLICIT_VR_LITTLE_ENDIAN);

    // OR

    dicom:File|dicom:ParsingError parsedFile2 = dicomparser:parseFile("./sample2.dcm", dicom:EXPLICIT_VR_LITTLE_ENDIAN);
}
```

By setting `metaElementsOnly = true`, exclusively parse the file meta-information elements. Also parsing can be done while omitting pixel data by setting `ignorePixelData = true`,

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;

public function main() {
    // Parse only the file meta information elements
    dicom:File|dicom:ParsingError parsedFile1 = dicomparser:parseFile("./sample1.dcm",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, metaElementsOnly = true);

    // Parse ignoring pixel data
    dicom:File|dicom:ParsingError parsedFile2 = dicomparser:parseFile("./sample2.dcm",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
}
```

### Parse an Encoded DICOM Data Set

Parse an encoded DICOM dataset using either the generic `dicomparser:parse()` function or the dedicated `dicomparser:parseDataset()` function,

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;

public function main() returns error? {
    // Data Set
    dicom:Dataset dataset = table [
        {tag: {group: 0x0008, element: 0x0020}, vr: dicom:DA, value: "19970815"}, // StudyDate
        {tag: {group: 0x0010, element: 0x1010}, vr: dicom:AS, value: "020Y"}, // PatientAge
        {tag: {group: 0x0028, element: 0x0002}, vr: dicom:US, value: 1} // SamplesPerPixel
    ];

    // Encode dataset
    byte[] datasetBytes = check dicom:toBytes(dataset, dicom:EXPLICIT_VR_LITTLE_ENDIAN);

    // Parse the encoded dataset
    dicom:Dataset|dicom:ParsingError parsedDataset = dicomparser:parseDataset(datasetBytes, dicom:EXPLICIT_VR_LITTLE_ENDIAN);
}
```
