## Overview

The `dicom` (core) module is the base DICOM module. This module includes DICOM data types, data element dictionaries, encoders, validators, and utility functions necessary for various DICOM-related tasks.

## Usage

### Construct DICOM Entities

```ballerina
import ballerinax/health.dicom;

public function main() {
    // Tag - StudyDate
    dicom:Tag tag = {group: 0x0008, element: 0x0020};

    // Data Element - StudyDate
    dicom:DataElement dataElement = {
        tag: {group: 0x0008, element: 0x0020},
        vr: dicom:DA,
        value: "19970815"
    };

    // Data Set
    dicom:Dataset dataset = table [
        {tag: {group: 0x0008, element: 0x0020}, vr: dicom:DA, value: "19970815"}, // StudyDate
        {tag: {group: 0x0010, element: 0x1010}, vr: dicom:AS, value: "020Y"}, // PatientAge
        {tag: {group: 0x0028, element: 0x0002}, vr: dicom:US, value: 1} // SamplesPerPixel
    ];
}

```

### Validate DICOM Entities

Constructed DICOM entities can be validated to confirm whether the entities are constructed according to the standard using the `dicom:validate()` function,

```ballerina
// Validate Tag
dicom:ValidationError? tagValidationRes = dicom:validate(tag, dicom:EXPLICIT_VR_LITTLE_ENDIAN);

// Validate Data element
dicom:ValidationError? dataElementValidationRes = dicom:validate(dataElement, dicom:EXPLICIT_VR_LITTLE_ENDIAN);

// Validate Data Set
dicom:ValidationError? datasetValidationRes = dicom:validate(dataset, dicom:EXPLICIT_VR_LITTLE_ENDIAN);
```

### Encode DICOM Entities

Constructed DICOM entities can be encoded to bytes according to the DICOM standard using the `dicom:toBytes()` function,

```ballerina
// Encode tag using explicit vr little endian transfer syntax
byte[]|dicom:EncodingError tagBytes = dicom:toBytes(tag, dicom:EXPLICIT_VR_LITTLE_ENDIAN);

// Encode data element using explicit vr big endian transfer syntax
byte[]|dicom:EncodingError dataElementBytes = dicom:toBytes(dataElement, dicom:EXPLICIT_VR_BIG_ENDIAN);

// Encode data set using implicit vr little endian transfer syntax
byte[]|dicom:EncodingError datasetBytes = dicom:toBytes(dataset, dicom:EXPLICIT_VR_LITTLE_ENDIAN);
```

Entities are validated before encoding by default. This function - while not recommended - can be overridden if necessary by passing `validateBeforeEncoding = false`,

```ballerina
// Encode data element without validating
byte[]|dicom:EncodingError dataElementBytes = dicom:toBytes(dataElement, dicom:EXPLICIT_VR_BIG_ENDIAN, validateBeforeEncoding = false);
```

### Retrieve Tag / Data Element Information From DICOM Dictionaries (Registry)

The `core` module includes DICOM data element dictionaries sourced from the DICOM registry. These dictionaries encapsulate essential information about each data element, including the Tag, Name, Keyword, Value Multiplicity (VM), and retirement status.

```ballerina
import ballerinax/health.dicom;

public function main() {
    // Standard - TagInfo of PatientName tag
    dicom:Tag patientNameTag = {group: 0x0010, element: 0x0010};
    dicom:TagInfo? patientNameTagInfo = dicom:getStandardTagInfo(patientNameTag);

    // Repeating - TagInfo of TypeOfData tag
    dicom:Tag typeOfDataTag = {group: 0x5000, element: 0x0020};
    dicom:TagInfo? typeOfDataTagInfo = dicom:getRepeatingTagInfo(typeOfDataTag);

    // Private - TagInfo of MaximumImageFrameSize of CARDIO-D.R. 1.0 creator ID
    dicom:Tag maximumImageFrameSizeTag = {group: 0x0019, element: 0x1030};
    dicom:TagInfo? maximumImageFrameSizeTagInfo = dicom:getPrivateTagInfo(maximumImageFrameSizeTag, "CARDIO-D.R. 1.0");
}
```
