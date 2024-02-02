import ballerina/http;
import ballerina/log;
import ballerinax/health.dicom.dicomweb;

# DICOM preprocessor implementation.
public isolated class DicomPreprocessor {
    final ApiConfig apiConfig;
    final map<QueryParamConfig> & readonly queryParamConfigMap;

    public isolated function init(ApiConfig apiConfig) {
        self.apiConfig = apiConfig;
        // Construct query param config map
        map<QueryParamConfig> queryParamConfigs = {};
        foreach QueryParamConfig paramConfig in apiConfig.queryParameters {
            queryParamConfigs[paramConfig.name] = paramConfig;
        }
        self.queryParamConfigMap = queryParamConfigs.cloneReadOnly();
    }

    public isolated function processSearchResource(http:Request httpRequest, http:RequestContext httpContext,
            dicomweb:ResourceType searchResourceType) returns dicomweb:Error? {
        log:printDebug("Preprocessing search resource");
        // Validate HTTP headers
        dicomweb:RequestMimeHeaders requestHeaders = check validateRequestHeaders(httpRequest);

        // Process query parameters
        dicomweb:QueryParameterMap processedQueryParams
            = check processQueryParams(httpRequest.getQueryParams(), searchResourceType, self.queryParamConfigMap);

        // Create HTTP request
        HttpRequest & readonly request = createHttpRequestRecord(httpRequest, ());

        // Create DICOM request
        DicomRequest dicomRequest
            = new (requestHeaders.acceptType, processedQueryParams.cloneReadOnly(), searchResourceType);

        // Create DICOM context
        DicomContext dicomContext = new (dicomRequest, request);

        // Set DICOM context inside HTTP context
        setDicomContext(dicomContext, httpContext);
    }

    public isolated function processRetrieveResource(http:Request httpRequest) returns dicomweb:Error? {
        log:printDebug("Preprocessing retrieve resource");
        // TODO:Implement
        return dicomweb:createDicomwebError("Retrieve transaction (WADO-RS) resources are not supported yet",
                httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    public isolated function processStoreResource(http:Request httpRequest) returns dicomweb:Error? {
        log:printDebug("Preprocessing store resource");
        // TODO:Implement
        return dicomweb:createDicomwebError("Store transaction (STOW-RS) resources are not supported yet",
                httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }
}

isolated function validateRequestHeaders(http:Request httpRequest) returns dicomweb:RequestMimeHeaders|dicomweb:Error {
    dicomweb:RequestMimeHeaders requestMimeHeaders = {};
    // TODO: Validate content type

    // Validate Accept header
    // Only search transaction media types are supported for now
    // Based off of Sections 8.7.7 and  10.6.4 in Part 18
    string|http:HeaderNotFoundError acceptHeader = httpRequest.getHeader("Accept");

    if acceptHeader is http:HeaderNotFoundError {
        string message = "Missing mandatory 'Accept' header in request";
        return dicomweb:createDicomwebError(message, dicomweb:VALIDATION_ERROR,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    match acceptHeader {
        ""|"*/*"|dicomweb:MIME_TYPE_JSON|dicomweb:MIME_TYPE_DICOM_JSON => {
            // Use default JSON type
            requestMimeHeaders.acceptType = dicomweb:MIME_TYPE_JSON;
        }
        _ => {
            string message = string `Unsupported 'Accept' header value in request: ${acceptHeader}`;
            string diagnostic = string `Supported values for 'Accept' header: ${joinWithComma(dicomweb:MIME_TYPE_JSON,
                    dicomweb:MIME_TYPE_DICOM_JSON)}`;
            return dicomweb:createDicomwebError(message, dicomweb:VALIDATION_ERROR,
                    diagnostic, httpStatusCode = http:STATUS_NOT_ACCEPTABLE);
        }
    }

    return requestMimeHeaders;
}

isolated function createHttpRequestRecord(http:Request request, json|xml? payload) returns HttpRequest & readonly {
    map<string[]> headers = {};
    foreach string headerName in request.getHeaderNames() {
        string[]|http:HeaderNotFoundError headerValues = request.getHeaders(headerName);
        if headerValues is string[] {
            headers[headerName] = headerValues;
        }
    }

    return {
        headers: headers.cloneReadOnly(),
        payload: payload.cloneReadOnly()
    };
}

isolated function setDicomContext(DicomContext dicomContext, http:RequestContext httpContext) {
    httpContext.set(DICOM_CONTEXT_PROP_NAME, dicomContext);
}

isolated function getNextService(http:RequestContext context) returns http:NextService?|dicomweb:Error {
    http:NextService|error? next = context.next();
    if next is error {
        string message = "Error occurred while retrieving next HTTP service";
        return dicomweb:createInternalDicomwebError(message, dicomweb:PROCESSING_ERROR);
    }
    return next;
}

isolated function processQueryParams(map<string[]> queryParams, dicomweb:ResourceType resourceType,
        map<QueryParamConfig> queryParamConfigMap) returns dicomweb:QueryParameterMap|dicomweb:Error {
    dicomweb:QueryParameterMap processedParams = {};

    // Dicom attribute/value pairs for match query parameter
    dicomweb:MatchParameterMap matchParameters = {};

    foreach [string, string[]] [param, value] in queryParams.entries() {
        if queryParamConfigMap.hasKey(param) { // If there's a pre-processor given in the param config
            QueryParamConfig paramConfig = queryParamConfigMap.get(param);
            if paramConfig.active {
                QueryParamPreProcessor? preProcessor = paramConfig.preProcessor;
                if preProcessor is QueryParamPreProcessor {
                    dicomweb:QueryParameterValue processedValue = check preProcessor(value);
                    processedParams[param] = processedValue;
                }
            } else {
                string message = string `Unsupported query parameter: ${paramConfig.name}`;
                string diagnostic = string `Supported query parameters: ` +
                        string `${joinWithComma(...extractActiveQueryParameterNames(queryParamConfigMap))}`;
                return dicomweb:createDicomwebError(message, diagnostic = diagnostic,
                        httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
            }
        } else if dicomweb:isValidResourceMatchAttribute(param, resourceType) { // Possible attribute matching
            // TODO: Multiple values are allowed if a UID list matching
            // Section 8.3.4.1 in Part 18
            if value.length() == 1 { // Only one value is allowed for match attributes
                matchParameters[param] = value[0];
            }
        }
    }

    if matchParameters.length() != 0 {
        processedParams[dicomweb:MATCH] = matchParameters;
    }

    return processedParams;
}

isolated function extractActiveQueryParameterNames(map<QueryParamConfig> paramConfigMap) returns string[] {
    string[] activeParams = [];
    foreach [string, QueryParamConfig] [param, paramConfig] in paramConfigMap.entries() {
        if paramConfig.active {
            activeParams.push(param);
        }
    }
    return activeParams;
}
