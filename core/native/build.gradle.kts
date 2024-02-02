plugins {
    java
}

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

val ballerinaLangVersion: String by project

dependencies {
    implementation(group = "org.ballerinalang", name = "ballerina-runtime", version = ballerinaLangVersion)
}

// Set Java language version to 17
java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}