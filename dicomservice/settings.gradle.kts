dependencyResolutionManagement {
    repositories {
        mavenCentral()
        maven {
            url = uri("https://maven.pkg.github.com/ballerina-platform/*")
            credentials {
                username = System.getenv("GITHUB_USERNAME")
                password = System.getenv("GITHUB_PAT")
            }
        }
    }
}

// Configure the root project and subproject settings
rootProject.name = "dicomservice"

include(":compiler-plugin")
include(":ballerina")
include(":native")

// Rename projects
project(":compiler-plugin").name = "dicomservice-compiler-plugin"
project(":ballerina").name = "dicomservice-ballerina"
project(":native").name = "dicomservice-native"
