# Ballerina DICOM Parser

## Overview

The `dicomparser` module provides essential parsers for decoding DICOM entities. These parsers cover DICOM files, datasets, Value Representations (VRs), and data element values. It is part of the [`ballerinax/health.dicom`](https://central.ballerina.io/ballerinax/health.dicom) family of packages.

## Compatibility

|                    | Version               |
| ------------------ | --------------------- |
| Ballerina Language | Swan Lake 2201.12.x   |

---

## Features

- **DICOM File Parser**: Parse `.dcm` files with support for different transfer syntaxes, selective pixel data exclusion, and metadata-only parsing.
- **Dataset Parser**: Parse raw encoded DICOM byte arrays into structured `Dataset` objects.
- **Tag Constants**: Over 5,000 human-readable tag constants (e.g., `dicom:TAG_PATIENT_NAME`) for easy tag access.
- **VR Accessor Helpers**: Type-safe helpers to retrieve any DICOM Value Representation from a Dataset.
- **Structured VR Parsers**: Parse complex VRs like `PN` (Person Name), `DA` (Date), and `TM` (Time) into native Ballerina records.

---

## Usage

### 1. Parse a DICOM File

Parse a DICOM `.dcm` file using either the generic `parse()` or the dedicated `parseFile()` function.

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;

public function main() {
    // Parse a DICOM file using Explicit VR Little Endian transfer syntax
    dicom:File|dicom:ParsingError parsedFile = dicomparser:parseFile("./sample.dcm",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN);

    if parsedFile is dicom:File {
        // Access the parsed dataset
        dicom:Dataset dataset = parsedFile.dataset;
    }
}
```

#### Parsing options

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;

public function main() {
    // Parse only the File Meta Information elements (Group 0002)
    dicom:File|dicom:ParsingError metaOnly = dicomparser:parseFile("./sample.dcm",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, metaElementsOnly = true);

    // Parse excluding pixel data (faster for metadata extraction)
    dicom:File|dicom:ParsingError noPixels = dicomparser:parseFile("./sample.dcm",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
}
```

---

### 2. Parse an Encoded Dataset

Parse a raw encoded DICOM byte array back into a `Dataset`.

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;

public function main() returns error? {
    dicom:Dataset dataset = table [
        {tag: {group: 0x0008, element: 0x0020}, vr: dicom:DA, value: "20010103"},  // StudyDate
        {tag: {group: 0x0010, element: 0x1010}, vr: dicom:AS, value: "020Y"},       // PatientAge
        {tag: {group: 0x0028, element: 0x0002}, vr: dicom:US, value: 1}             // SamplesPerPixel
    ];

    byte[] encoded = check dicom:toBytes(dataset, dicom:EXPLICIT_VR_LITTLE_ENDIAN);
    dicom:Dataset|dicom:ParsingError parsed = dicomparser:parseDataset(encoded, dicom:EXPLICIT_VR_LITTLE_ENDIAN);
}
```

---

### 3. Access Tags Using Named Constants

The `health.dicom` core package exposes over 5,000 typed tag constants so you can reference tags by their human-readable names instead of raw hex numbers.

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;

public function main() {
    dicom:File|dicom:ParsingError parsedFile = dicomparser:parseFile("./sample.dcm",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);

    if parsedFile is dicom:File {
        dicom:Dataset dataset = parsedFile.dataset;

        // Use named constants instead of 0x00100010
        string|dicom:Error patientName = dicom:getString(dataset, dicom:TAG_PATIENT_NAME);
        string|dicom:Error studyDate   = dicom:getString(dataset, dicom:TAG_STUDY_DATE);
        string|dicom:Error modality    = dicom:getString(dataset, dicom:TAG_MODALITY);
    }
}
```

---

### 4. Type-Safe VR Accessor Helpers

Use the following helpers to extract values in their native types directly from a `Dataset`.

| Function | Return Type | Description |
|---|---|---|
| `getString(dataset, tag)` | `string\|Error` | For string VRs: `AE`, `AS`, `CS`, `DA`, `DS`, `LO`, `PN`, `SH`, `TM`, `UI`, etc. |
| `getInt(dataset, tag)` | `int\|Error` | For integer VRs: `AT`, `SL`, `SS`, `SV`, `UL`, `US`, `UV` |
| `getFloat(dataset, tag)` | `float\|Error` | For float VRs: `FL`, `FD` and numeric strings like `DS` |
| `getStringArray(dataset, tag)` | `string[]\|Error` | Multi-value strings split by `\` (e.g., `CS` with VM>1) |
| `getIntArray(dataset, tag)` | `int[]\|Error` | Multi-value integer strings split by `\` (e.g., `IS`) |
| `getFloatArray(dataset, tag)` | `float[]\|Error` | Multi-value decimal strings split by `\` (e.g., `DS`) |
| `getDataElement(dataset, tag)` | `DataElement?` | Returns the raw `DataElement` record |
| `getSequence(dataset, tag)` | `SequenceValue\|Error` | For `SQ` (Sequence of Items) VRs |

#### Examples

```ballerina
import ballerinax/health.dicom;
import ballerinax/health.dicom.dicomparser;

public function main() {
    dicom:File|dicom:ParsingError parsedFile = dicomparser:parseFile("./sample.dcm",
            dicom:EXPLICIT_VR_LITTLE_ENDIAN, ignorePixelData = true);
    if parsedFile is dicom:File {
        dicom:Dataset dataset = parsedFile.dataset;

        // Integer: Rows (0028,0010)
        int|dicom:Error rows = dicom:getInt(dataset, dicom:TAG_ROWS);

        // Float: Slice Thickness (0050,0018)
        float|dicom:Error sliceThickness = dicom:getFloat(dataset, dicom:TAG_SLICE_THICKNESS);

        // Multi-value float array: ImagePositionPatient (0020,0032) - VM = 3
        float[]|dicom:Error imagePosition = dicom:getFloatArray(dataset, dicom:TAG_IMAGE_POSITION_PATIENT);
        if imagePosition is float[] {
            float x = imagePosition[0];
            float y = imagePosition[1];
            float z = imagePosition[2];
        }

        // Multi-value string array: ImageType (0008,0008) - VM = 2-n
        string[]|dicom:Error imageType = dicom:getStringArray(dataset, dicom:TAG_IMAGE_TYPE);

        // Sequence VR: ReferencedStudySequence (0008,1110)
        dicom:SequenceValue|dicom:Error refStudy = dicom:getSequence(dataset, dicom:TAG_REFERENCED_STUDY_SEQUENCE);
    }
}
```

---

### 5. Parse Structured VRs

#### Person Name (PN)

The `PN` VR stores names in the format `FamilyName^GivenName^MiddleName^Prefix^Suffix`.
Use `parsePersonName` to extract each component into a typed `PersonName` record.

```ballerina
import ballerinax/health.dicom;

public function main() {
    dicom:Dataset dataset = ...; // obtained from parseFile

    string|dicom:Error rawName = dicom:getString(dataset, dicom:TAG_PATIENT_NAME);
    if rawName is string {
        dicom:PersonName pn = dicom:parsePersonName(rawName);

        string? family = pn.familyName;  // "Adams"
        string? given  = pn.givenName;   // "John"
        string? middle = pn.middleName;  // "Robert"
        string? prefix = pn.prefix;      // "Dr."
        string? suffix = pn.suffix;      // "Jr."
    }
}
```

#### Date (DA)

The `DA` VR stores dates as `YYYYMMDD`. Use `parseDate` for structured access.

```ballerina
import ballerinax/health.dicom;

public function main() {
    dicom:Dataset dataset = ...;

    string|dicom:Error rawDate = dicom:getString(dataset, dicom:TAG_STUDY_DATE);
    if rawDate is string {
        dicom:DicomDate|dicom:Error date = dicom:parseDate(rawDate);
        if date is dicom:DicomDate {
            int year  = date.year;   // e.g. 2001
            int month = date.month;  // e.g. 1
            int day   = date.day;    // e.g. 3
        }
    }
}
```

#### Time (TM)

The `TM` VR stores time as `HH[MM[SS[.FFFFFF]]]`. Use `parseTime` for structured access.

```ballerina
import ballerinax/health.dicom;

public function main() {
    dicom:Dataset dataset = ...;

    string|dicom:Error rawTime = dicom:getString(dataset, dicom:TAG_STUDY_TIME);
    if rawTime is string {
        dicom:DicomTime|dicom:Error time = dicom:parseTime(rawTime);
        if time is dicom:DicomTime {
            int    hours      = time.hours;        // 14
            int?   minutes    = time.minutes;      // 21
            int?   seconds    = time.seconds;      // 30
            int?   fractional = time.fractional;   // 500 (microseconds)
        }
    }
}
```

---

## Acknowledgements

The sample DICOM file(s) used as test resources in this package were sourced from:
- [Rubo Medical Imaging](https://www.rubomedical.com/dicom_files/)
- [dcm4che test data](https://github.com/dcm4che/dcm4che)

---

## Report Issues

To report bugs, request new features, or start new discussions, go to the [Ballerina Extended Library repository](https://github.com/ballerina-platform/ballerina-library).
