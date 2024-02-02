# Ballerina DICOM Packages

The Ballerina DICOM packages provide functionalities to work with Digital Imaging and Communications in Medicine (DICOM) standard in Ballerina programs.

These packages include DICOM structures and data types, encoders, validators, parsers, DICOMweb related utils and a DICOM service type for creating DICOMweb APIs, as well as other miscellaneous utilities for working with the DICOM standard.

**Note: These packages are currently in a work-in-progress state and are undergoing rapid changes to ensure their functionality and reliability.**

## Build from the source

### Set Up the prerequisites

1. **Install Ballerina:**

    - Download and install [Ballerina Swan Lake](https://ballerina.io/).

2. **(Optional) Install Java SE Development Kit (JDK) version 17:**

    > **Note:** Only necessary if you want to build the `core` or the `dicomservice` package.

    - Choose one of the following JDK distributions:

        - [Oracle](https://www.oracle.com/java/technologies/downloads/)

        - [OpenJDK](https://adoptium.net/)

    > **Note:** Set the **JAVA_HOME** to the path where you installed the JDK.

3. **(Optional) Configure GitHub Credentials:**

    > **Note:** Only necessary if you want to build the `core` or the `dicomservice` package.

    The `core` and the `dicomservice` packages use Java dependencies, which use Ballerina packages hosted on Github. To install them during the Gradle build, [a GitHub personal access token (PAT) with the `read:packages` scope is required](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-gradle-registry#authenticating-to-github-packages).

    Export your GitHub username and a personal access token,

    ```shell
    export GITHUB_USERNAME=<Username>
    export GITHUB_PAT=<PAT>
    ```

### Build the source

Execute the commands below to build from source.

- **To build the `core` or the `dicomservice` package:**

  Navigate to the respective package directory and execute,

  ```shell
  ./gradlew clean build
  ```

- **To build any other package (e.g., `dicomparser`):**

  Navigate to the respective package directory and execute,

  ```shell
  bal build
  ```

### Publish packages
> **Note:** If you want to publish the `core` or the `dicomservice` package, please make sure to build the package first.

Navigate to the package directory (inside `ballerina` directory for the `core` or the `dicomservice` package) and follow the following instructions,

- [Publish to Ballerina Central](https://ballerina.io/learn/publish-packages-to-ballerina-central/#publish-a-package-to-ballerina-central)

- [Publish to local repository](https://ballerina.io/learn/manage-dependencies/#use-dependencies-from-the-local-repository)

## Contribute to Ballerina

As an open source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links
- Discuss code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
- Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
- Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
