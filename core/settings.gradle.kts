// Configure the root project and subproject settings
rootProject.name = "core"

include(":ballerina")
include(":native")

// Rename projects
project(":ballerina").name = "core-ballerina"
project(":native").name = "core-native"
