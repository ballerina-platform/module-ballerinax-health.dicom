import ballerina/jballerina.java;

# DICOM service holder class.
isolated class DicomServiceHolder {
    isolated function init(Service dicomService) {
        self.addDicomService(dicomService);
    }

    isolated function addDicomService(Service dicomService) = @java:Method {
        'class: "io.ballerinax.health.dicom.dicomservice.ServiceHolderUtils"
    } external;

    isolated function getDicomService() returns Service = @java:Method {
        'class: "io.ballerinax.health.dicom.dicomservice.ServiceHolderUtils"
    } external;
}
