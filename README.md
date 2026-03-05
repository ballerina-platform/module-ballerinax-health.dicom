# Ballerina DICOM Packages

The Ballerina DICOM packages provide a suite of modules for working with the [Digital Imaging and Communications in Medicine (DICOM)](https://www.dicomstandard.org/) standard in Ballerina programs. These packages enable developers to parse DICOM files, work with DICOM data elements, build DICOMweb APIs, and implement standards-compliant DICOM services.

> **Note:** These packages are currently in a work-in-progress state and are undergoing rapid changes to ensure their functionality and reliability.

---

## Packages

| Package | Description | README |
| --- | --- | --- |
| `ballerinax/health.dicom` | Core package — DICOM data types, error types, data element dictionaries, VR encoders/validators, tag constants, and utility functions. | [README](core/ballerina/README.md) |
| `ballerinax/health.dicom.dicomparser` | DICOM file, dataset, and data element parsers. Supports structured type parsing for PN, DA, and TM VRs. | [README](dicomparser/README.md) |
| `ballerinax/health.dicom.dicomweb` | DICOMweb data types, error types, a JSON response builder (`generateResponse`), and query parameter utilities. | [README](dicomweb/README.md) |
| `ballerinax/health.dicom.dicomservice` | Custom Ballerina service type (`Listener`, `DicomContext`, `ApiConfig`) for building DICOMweb APIs with built-in request/query parameter processing. | [README](dicomservice/ballerina/README.md) |

---

## Architecture Overview

The packages are designed as layered modules that build on each other:

```
┌─────────────────────────────────────────────────┐
│          health.dicom.dicomservice              │  ← DICOMweb API service type
└───────────────────────┬─────────────────────────┘
                        │ depends on
┌───────────────────────▼─────────────────────────┐
│          health.dicom.dicomweb                  │  ← DICOMweb response builder
└───────────────────────┬─────────────────────────┘
                        │ depends on
┌───────────────────────▼─────────────────────────┐
│          health.dicom.dicomparser               │  ← DICOM file/dataset parsing
└───────────────────────┬─────────────────────────┘
                        │ depends on
┌───────────────────────▼─────────────────────────┐
│          health.dicom  (core)                   │  ← DICOM types, dictionary, utils
└─────────────────────────────────────────────────┘
```

### Package Responsibilities

- **`health.dicom`** — The foundation layer. Contains all DICOM primitive types (`Dataset`, `Tag`, `Vr`, `DataElement`), the data element dictionary, transfer syntax constants, VR encoders/validators, named tag constants (e.g., `TAG_PATIENT_NAME`), and core utility functions (`getString`, `getInt`, `parseDate`, `parseTime`, `parsePersonName`, etc.).

- **`health.dicom.dicomparser`** — Builds on the core to parse raw DICOM binary files and byte streams into structured `Dataset` objects. Supports Little Endian and Big Endian transfer syntaxes, implicit/explicit VR, and pixel data skipping for performance.

- **`health.dicom.dicomweb`** — Transforms parsed DICOM `Dataset` arrays into DICOMweb JSON Model Objects (`application/dicom+json`) following the QIDO-RS, WADO-RS, and STOW-RS specifications. Provides structured error types (`ProcessingError`, `ValidationError`) and `StatusReport` responses.

- **`health.dicom.dicomservice`** — A custom Ballerina service type that wraps an HTTP listener with DICOMweb-specific processing: header validation, query parameter pre/post processing, and a `DicomContext` object injected into every resource function.

---

## Build from the Source

### Prerequisites

1. **Install Ballerina:**

    Download and install [Ballerina Swan Lake](https://ballerina.io/) (2201.12.x or later).

2. **(Optional) Install JDK 21:**

    > **Note:** Only required to build the `core` or `dicomservice` packages (Java native components).

    - [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    - [OpenJDK / Eclipse Temurin](https://adoptium.net/)

    > Set the `JAVA_HOME` environment variable to the JDK installation path.

3. **(Optional) Configure GitHub Credentials:**

    > **Note:** Only required to build the `core` or `dicomservice` packages.

    The native Java dependencies are hosted on GitHub Packages. Export your credentials:

    ```shell
    export GITHUB_USERNAME=<your-github-username>
    export GITHUB_PAT=<personal-access-token-with-read:packages-scope>
    ```

### Build

- **`core` or `dicomservice`** (Gradle build — includes native Java compilation):

  ```shell
  cd core   # or: cd dicomservice
  ./gradlew clean build
  ```

- **`dicomparser` or `dicomweb`** (pure Ballerina):

  ```shell
  cd dicomparser   # or: cd dicomweb
  bal build
  ```

### Publish

> **Note:** Build the `core` or `dicomservice` packages with Gradle before publishing.

Navigate to the package directory (`ballerina/` subdirectory for `core` and `dicomservice`) and follow the instructions for:

- [Publish to Ballerina Central](https://ballerina.io/learn/publish-packages-to-ballerina-central/#publish-a-package-to-ballerina-central)
- [Publish to local repository](https://ballerina.io/learn/manage-dependencies/#use-dependencies-from-the-local-repository)

---

## Contributing

As an open source project, Ballerina welcomes contributions from the community. For more information, see the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).
