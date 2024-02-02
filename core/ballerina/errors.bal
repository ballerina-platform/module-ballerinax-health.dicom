# Base DICOM error type.
public type Error distinct error;

# Represents a DICOM validation related error.
public type ValidationError distinct Error;

# Represents a DICOM encoding related error.
public type EncodingError distinct Error;

# Represents a DICOM parsing related error.
public type ParsingError distinct Error;

# Represents a DICOM type related error.
public type TypeError distinct Error;
