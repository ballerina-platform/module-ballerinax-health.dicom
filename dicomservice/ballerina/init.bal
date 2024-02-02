import ballerina/jballerina.java;

isolated function init() {
    setModule();
}

isolated function setModule() = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.ModuleUtils"
} external;
