// Configure the root project and subproject settings
rootProject.name = "dicom"

include(":ballerina")
include(":native")

// Rename projects
project(":ballerina").name = "dicom-ballerina"
project(":native").name = "dicom-native"
