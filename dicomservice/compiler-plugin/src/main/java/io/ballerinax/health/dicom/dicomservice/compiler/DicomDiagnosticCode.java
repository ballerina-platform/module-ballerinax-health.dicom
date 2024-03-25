/*
 * Copyright (c) 2024 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerinax.health.dicom.dicomservice.compiler;

import io.ballerina.tools.diagnostics.DiagnosticSeverity;


/**
 * DICOM diagnostic codes.
 */
public enum DicomDiagnosticCode {

    DICOM_101("DICOM_101", "remote methods are not allowed in dicomservice:Service", DiagnosticSeverity.ERROR),
    DICOM_102("DICOM_102", "invalid number of parameters", DiagnosticSeverity.ERROR),
    DICOM_103("DICOM_103",
            String.format("invalid resource method first parameter type: expected \"%s\", but found \"%s\"",
                    Constants.ALLOWED_RESOURCE_FIRST_PARAM, "%s"), DiagnosticSeverity.ERROR),
    DICOM_104("DICOM_104",
            String.format("invalid resource method second parameter type: expected \"%s\", but found \"%s\"",
                    Constants.ALLOWED_RESOURCE_SECOND_PARAM, "%s"), DiagnosticSeverity.ERROR),
    DICOM_105("DICOM_105", String.format("invalid resource method return type: expected \"%s\", but found \"%s\"",
            Constants.ALLOWED_RESOURCE_RETURN_UNION, "%s"), DiagnosticSeverity.ERROR);

    private final String code;
    private final String message;
    private final DiagnosticSeverity severity;

    /**
     * Constructs a new {@code DicomDiagnosticCode}.
     *
     * @param code     The diagnostic code.
     * @param message  The diagnostic message.
     * @param severity The severity of the diagnostic.
     */
    DicomDiagnosticCode(String code, String message, DiagnosticSeverity severity) {
        this.code = code;
        this.message = message;
        this.severity = severity;
    }

    /**
     * Gets the diagnostic code.
     *
     * @return The diagnostic code.
     */
    public String getCode() {
        return code;
    }

    /**
     * Gets the diagnostic message.
     *
     * @return The diagnostic message.
     */
    public String getMessage() {
        return message;
    }

    /**
     * Gets the severity of the diagnostic.
     *
     * @return The severity of the diagnostic.
     */
    public DiagnosticSeverity getSeverity() {
        return severity;
    }

}
