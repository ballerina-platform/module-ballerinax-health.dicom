import ballerina/http;
import ballerina/lang.regexp;
import ballerinax/health.dicom.dicomweb;

# Response interceptor to post-process DICOM responses.
public isolated service class DicomResponseInterceptor {
    *http:ResponseInterceptor;

    final ApiConfig apiConfig;
    final map<QueryParamConfig> & readonly queryParamConfigMap;

    public function init(ApiConfig apiConfig) {
        self.apiConfig = apiConfig;
        map<QueryParamConfig> queryParamConfigs = {};
        foreach QueryParamConfig paramConfig in apiConfig.queryParameters {
            queryParamConfigs[paramConfig.name] = paramConfig;
        }
        self.queryParamConfigMap = queryParamConfigs.cloneReadOnly();
    }

    isolated remote function interceptResponse(http:RequestContext httpContext,
            http:Response response) returns http:NextService|dicomweb:Error? {
        // Only application/dicom+json is supported
        error? setContentTypeRes = response.setContentType(dicomweb:MIME_TYPE_DICOM_JSON);
        if setContentTypeRes is error {
            // Ignore
        }
        DicomContext? dicomContext = getDicomContext(httpContext);
        if dicomContext is DicomContext {
            check self.postProcessResponse(dicomContext, response);
        }
        return getNextService(httpContext);
    }

    isolated function postProcessResponse(DicomContext dicomContext, http:Response response) returns dicomweb:Error? {
        dicomweb:QueryParameterMap & readonly queryParams = dicomContext.getRequestQueryParameters();
        foreach [string, dicomweb:QueryParameterValue] [param, value] in queryParams.entries() {
            if self.queryParamConfigMap.hasKey(param) { // If there's a post-processor given in the param config
                QueryParamConfig paramConfig = self.queryParamConfigMap.get(param);
                check postProcessQueryParam(response, paramConfig, value);
            }
        }
    }
}

# Response error interceptor to handle errors.
public isolated service class DicomResponseErrorInterceptor {
    *http:ResponseErrorInterceptor;

    isolated remote function interceptResponseError(error err, http:Request request)
            returns http:BadRequest|http:NotFound|http:InternalServerError|http:NotAcceptable|http:NotImplemented {
        return constructHttpStatusCodeResponse(err, getBasePath(request.rawPath), dicomweb:MIME_TYPE_JSON);
    }
}

isolated function constructHttpStatusCodeResponse(error err, string uri,
        string mediaType) returns http:BadRequest|http:NotFound|http:InternalServerError
                |http:NotAcceptable|http:NotImplemented {
    if err is dicomweb:Error {
        match err.detail().httpStatusCode {
            http:STATUS_BAD_REQUEST => {
                http:BadRequest badRequest = {
                    body: dicomweb:constructStatusReport(err, uri),
                    mediaType: mediaType
                };
                return badRequest;
            }
            http:STATUS_NOT_FOUND => {
                http:NotFound notFound = {
                    body: dicomweb:constructStatusReport(err, uri),
                    mediaType: mediaType
                };
                return notFound;
            }
            http:STATUS_INTERNAL_SERVER_ERROR => {
                http:InternalServerError internalServerError = {
                    body: dicomweb:constructStatusReport(err, uri),
                    mediaType: mediaType
                };
                return internalServerError;
            }
            http:STATUS_NOT_ACCEPTABLE => {
                http:NotAcceptable notAcceptable = {
                    body: dicomweb:constructStatusReport(err, uri),
                    mediaType: mediaType
                };
                return notAcceptable;
            }
            http:STATUS_NOT_IMPLEMENTED => {
                http:NotImplemented notImplemented = {
                    body: dicomweb:constructStatusReport(err, uri),
                    mediaType: mediaType
                };
                return notImplemented;
            }
            _ => {
                http:InternalServerError internalServerError = {
                    body: dicomweb:constructStatusReport(err, uri),
                    mediaType: mediaType
                };
                return internalServerError;
            }
        }
    }
    http:InternalServerError internalServerError = {
        body: dicomweb:constructStatusReport(err, uri),
        mediaType: mediaType
    };
    return internalServerError;
}

isolated function getBasePath(string path) returns string => regexp:split(re `\?`, path)[0];
