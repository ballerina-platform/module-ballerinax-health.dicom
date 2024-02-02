import ballerina/jballerina.java;
import ballerinax/health.dicom.dicomweb;

isolated function getResourceMethod(service object {} serviceObject, string[] requestPath, string accessor)
    returns handle? = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.Utils"
} external;

isolated function hasPathParam(handle resourceMethod)
    returns boolean = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.Utils"
} external;

isolated function getLastPath(handle resourceMethod)
    returns handle = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.Utils"
} external;

isolated function executeWithNoPathParams(DicomContext dicomContext, dicomweb:QueryParameterMap queryParams,
        service object {} serviceObject, handle resourceMethod) returns any|error = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.HttpToDicomwebAdaptor"
} external;

isolated function executeWithStudy(string study, DicomContext dicomContext, dicomweb:QueryParameterMap queryParams,
        service object {} serviceObject, handle resourceMethod) returns any|error = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.HttpToDicomwebAdaptor"
} external;

isolated function executeWithStudyAndSeries(string study, string series, DicomContext dicomContext,
        dicomweb:QueryParameterMap queryParams, service object {} serviceObject,
        handle resourceMethod) returns any|error = @java:Method {
    'class: "io.ballerinax.health.dicom.dicomservice.HttpToDicomwebAdaptor"
} external;
