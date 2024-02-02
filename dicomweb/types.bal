import ballerinax/health.dicom;

# Represents a DICOMweb resource.
#
# + resourceType - Type of the resource  
# + pathParams - Path parameters of the resource  
# + queryParams - Query parameters of the resource
public type Resource record {|
    ResourceType resourceType;
    string[] pathParams;
    map<string[]> queryParams;
|};

# Holds DICOMweb request MIME headers.
#
# + contentType - MIME content type used for the request 
# + acceptType - MIME type accepted
public type RequestMimeHeaders record {|
    MimeType? contentType = ();
    MimeType acceptType = MIME_TYPE_JSON;
|};

# Represents a DICOMweb model object person name value.
#
# + Alphabetic - Alphabetic name if available
# + Ideographic - Ideographic name if available
# + Phonetic - Phonetic name if available
public type PersonNameValue record {|
    string Alphabetic?;
    string Ideographic?;
    string Phonetic?;
|};

// Types for DICOMweb query parameter values
# Represents a DICOMweb match query parameter value.
public type MatchParameterValue string|dicom:Tag;

# Represents a match query parameter map
public type MatchParameterMap map<MatchParameterValue>;

# Represents a DICOMweb fuzzymatching query parameter value.
public type FuzzyMatchingParameterValue boolean;

# Represents a DICOMweb includefield query parameter value. 
public type IncludeFieldParameterValue string|string[]|dicom:Tag[];

# Represents a DICOMweb limit query parameter value.
public type LimitParameterValue int;

# Represents a DICOMweb offset query parameter value.
public type OffsetParameterValue int;

# Represents a DICOMweb query parameter value.
public type QueryParameterValue FuzzyMatchingParameterValue|IncludeFieldParameterValue|LimitParameterValue
    |OffsetParameterValue|anydata;

# Type to hold query parameters
public type QueryParameterMap map<QueryParameterValue>;

# Represents a DICOMweb attribute object value.
public type AttributeObjectValue dicom:DataElementValue[]|ModelObject[]|PersonNameValue;

# Represents a DICOMweb attribute object.
#
# + vr - Value representation 
# + Value - Value if available 
# + BulkDataURI - BulkDataURI if available
# + InlineBinary - InlineBinary data if available
public type AttributeObject record {|
    string vr;
    AttributeObjectValue Value?;
    string BulkDataURI?;
    string InlineBinary?;
|};

# Represents a DICOMweb model object.
# Map key is the attribute object name.
# Map value is the attribute object.
public type ModelObject map<AttributeObject>;

# Represents a DICOMweb Response.
public type Response ModelObject[];
