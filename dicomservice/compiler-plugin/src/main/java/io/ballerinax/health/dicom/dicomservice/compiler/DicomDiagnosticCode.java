package io.ballerinax.health.dicom.dicomservice.compiler;

import io.ballerina.tools.diagnostics.DiagnosticSeverity;


/**
 * DICOM diagnostic codes.
 */
public enum DicomDiagnosticCode {
    DICOM_101("DICOM_101", "remote methods are not allowed in dicomservice:Service", DiagnosticSeverity.ERROR),
    DICOM_102("DICOM_102", "invalid number of parameters", DiagnosticSeverity.ERROR),
    DICOM_103("DICOM_103",
            "invalid resource method first parameter type: expected \"" + Constants.ALLOWED_RESOURCE_FIRST_PARAM
                    + "\", but found \"%s\"", DiagnosticSeverity.ERROR),
    DICOM_104("DICOM_104",
            "invalid resource method second parameter type: expected \"" + Constants.ALLOWED_RESOURCE_SECOND_PARAM
                    + "\", but found \"%s\"", DiagnosticSeverity.ERROR),
    DICOM_105("DICOM_105", "invalid resource method return type: expected \""
            + Constants.ALLOWED_RESOURCE_RETURN_UNION + "\", but found \"%s\"", DiagnosticSeverity.ERROR);

    private final String code;
    private final String message;
    private final DiagnosticSeverity severity;

    DicomDiagnosticCode(String code, String message, DiagnosticSeverity severity) {
        this.code = code;
        this.message = message;
        this.severity = severity;
    }

    public String getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }

    public DiagnosticSeverity getSeverity() {
        return severity;
    }
}
