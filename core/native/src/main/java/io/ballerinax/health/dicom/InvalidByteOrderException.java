package io.ballerinax.health.dicom;

public class InvalidByteOrderException extends IllegalArgumentException {
    public InvalidByteOrderException(String errorMessage) {
        super(errorMessage);
    }
}
