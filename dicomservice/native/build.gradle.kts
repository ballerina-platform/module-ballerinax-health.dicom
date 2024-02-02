plugins {
    java
}

val ballerinaLangVersion: String by project

dependencies {
    implementation(group = "org.ballerinalang", name = "ballerina-runtime", version = ballerinaLangVersion)
    implementation(group = "org.ballerinalang", name = "ballerina-lang", version = ballerinaLangVersion)
    implementation(group = "org.ballerinalang", name = "ballerina-tools-api", version = ballerinaLangVersion)
    implementation(group = "org.ballerinalang", name = "ballerina-parser", version = ballerinaLangVersion)
}

// Set Java language version to 17
java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}