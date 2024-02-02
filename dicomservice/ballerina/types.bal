import ballerina/http;
import ballerinax/health.dicom.dicomweb;

# Represents a DICOM service type.
public type Service distinct service object {};

# Holds HTTP request information.
#
# + headers - HTTP request headers  
# + payload - HTTp request payload
public type HttpRequest record {
    map<string[]> & readonly headers;
    json|xml|string? & readonly payload;
};

# Query parameter pre-processor function type.
public type QueryParamPreProcessor isolated function (string[]) returns dicomweb:QueryParameterValue|dicomweb:Error;

# Query parameter post-processor function type.
public type QueryParamPostProcessor isolated function (http:Response,
        dicomweb:QueryParameterValue) returns dicomweb:Error?;

# Query parameter configuration.
#
# + name - Name of the query parameter
# + active - Boolean flag indicating whether the query parameter should be active or not
# + preProcessor - Function to override the default pre-processing logic applied to the query parameter
# + postProcessor - Function to override the default post-processing logic applied to the query parameter
public type QueryParamConfig record {|
    readonly string name;
    readonly boolean active;
    readonly & QueryParamPreProcessor preProcessor?;
    readonly & QueryParamPostProcessor postProcessor?;
|};

# API configuration.
#
# + queryParameters - Query parameters supported by the API
public type ApiConfig record {|
    readonly QueryParamConfig[] queryParameters = [];
|};

# Dummy type used in the compiler plugin
type ResourceReturnType http:Response|http:StatusCodeResponse|anydata|error;
