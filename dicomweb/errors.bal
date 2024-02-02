# Represents a DICOMweb related error.
public type Error distinct error<ErrorDetails>;

# Represents a DICOMweb processing related error.
public type ProcessingError distinct Error;

# Represents a DICOMweb validation related error.
public type ValidationError distinct Error;

# DICOMweb error details.
#
# + httpStatusCode - The HTTP status code associated with the error
# + internalError - Boolean flag to indicate if the error is an internal error
# + uuid - The unique identifier of the error  
# + diagnostic - Diagnostic information about the error. This is an optional parameter.
public type ErrorDetails record {
    int httpStatusCode;
    boolean internalError;
    string uuid;
    string? diagnostic;
};

# Represents a DICOMweb status report.
#
# + errorDetails - Specific details about the error
# + uri - The resource path of the request
public type StatusReport record {
    StatusReportErrorDetails errorDetails;
    string uri;
};

# DICOMweb status report error details.
#
# + message - The message describing the error 
# + diagnostic - Diagnostic information about the error. This is an optional parameter.
# + trackingId - The unique identifier of the error
public type StatusReportErrorDetails record {
    string message;
    string diagnostic?;
    string trackingId;
};

# DICOMweb error types
public enum ErrorType {
    PROCESSING_ERROR,
    VALIDATION_ERROR
}
