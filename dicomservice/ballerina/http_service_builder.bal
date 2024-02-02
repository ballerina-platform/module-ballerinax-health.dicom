import ballerina/http;
import ballerina/jballerina.java;
import ballerinax/health.dicom.dicomweb;

// Construct an http service for a DICOM service.
isolated function getHttpService(DicomServiceHolder dicomServiceHolder, ApiConfig apiConfig) returns http:Service {
    http:InterceptableService httpService = isolated service object {

        private final DicomServiceHolder dicomServiceHolder = dicomServiceHolder;
        private final DicomPreprocessor dicomPreprocessor = new DicomPreprocessor(apiConfig);

        public function createInterceptors() returns [DicomResponseErrorInterceptor, DicomResponseInterceptor] {
            return [new DicomResponseErrorInterceptor(), new DicomResponseInterceptor(apiConfig)];
        }

        isolated resource function get [string... path](http:Request req, http:RequestContext ctx) returns any|error {
            // GET could be Query or Retrieve transaction

            // Get DICOM service from the holder
            Service dicomService = self.dicomServiceHolder.getDicomService();
            // Get matching method in the DICOM service
            handle? resourceMethod = getResourceMethod(dicomService, path, http:GET);

            if resourceMethod == () { // No matching method
                string message = string `Path not found: ${req.extraPathInfo}`;
                return dicomweb:createDicomwebError(message, httpStatusCode = http:STATUS_NOT_FOUND);
            }

            DicomContext? dicomContext;
            any|error executionResult = ();

            // Get the last path of the resource method
            handle resourceLastPath = getLastPath(resourceMethod);
            string lastPath = java:toString(resourceLastPath) ?: "";

            // If the last path is "^" (path parameter), it can be a Retrieve transaction resource
            // Else, it can be either a Search or Retrieve transaction resource
            if lastPath == "^" { // Path param
                // This means the resource can't be a Search transaction resource
                // Process as a Retrieve transaction resource
                check self.dicomPreprocessor.processRetrieveResource(req);
            } else {
                match lastPath {
                    // If last path is metadata/rendered/thumbnail/bulkdata/pixeldata, it's a retrieve transaction
                    "metadata"|"rendered"|"thumbnail"|"bulkdata"|"pixeldata" => {
                        // Process as a retrieve transaction instance resource
                        check self.dicomPreprocessor.processRetrieveResource(req);
                    }
                    _ => {
                        // Process as a search transaction resource
                        dicomweb:ResourceType? searchResourceType = getSearchResourceFromPath(path);
                        if searchResourceType is dicomweb:ResourceType {
                            // Get path params from the path
                            map<string> pathParams = getResourcePathParams(searchResourceType, path);
                            // Process search resource
                            check self.dicomPreprocessor.processSearchResource(req, ctx, searchResourceType);
                            // Get DICOM context from HTTP context
                            dicomContext = getDicomContext(ctx);
                            if dicomContext != () {
                                executionResult = executeSearchTransactionResource(searchResourceType, pathParams,
                                    dicomContext, dicomService, resourceMethod);
                                // If execution is erroneous, update DICOM context accordingly
                                if executionResult is error {
                                    dicomContext.setInErrorState(true);
                                    dicomContext.setErrorCode(getErrorCode(executionResult));
                                }
                            }
                        }
                    }
                }
            }
            return executionResult;
        }
    };
    return httpService;
}

isolated function getSearchResourceFromPath(string[] path) returns dicomweb:ResourceType? {
    // Determine the search transaction resource from path length and path parts
    match path.length() {
        1 => { // Could be /studies, /series, or /instances
            match path[0] {
                "studies" => {
                    return dicomweb:SEARCH_ALL_STUDIES;
                }
                "series" => {
                    return dicomweb:SEARCH_ALL_SERIES;
                }
                "instances" => {
                    return dicomweb:SEARCH_ALL_INSTANCES;
                }
            }
        }
        3 => { // could be /studies/{study}/series{?search*} or /studies/{study}/instances{?search*}
            match path[2] {
                "series" => {
                    return dicomweb:SEARCH_STUDY_SERIES;
                }
                "instances" => {
                    return dicomweb:SEARCH_STUDY_INSTANCES;
                }
            }
        }
        _ => { // should be /studies/{study}/series/{series}/instances{?search*}
            return dicomweb:SEARCH_STUDY_SERIES_INSTANCES;
        }
    }
    return;
}

isolated function executeSearchTransactionResource(dicomweb:ResourceType searchResource, map<string> pathParams,
        DicomContext dicomContext, Service dicomService, handle resourceMethod) returns any|error {
    match searchResource {
        dicomweb:SEARCH_STUDY_SERIES|dicomweb:SEARCH_STUDY_INSTANCES => {
            return executeWithStudy(pathParams.get("study"), dicomContext,
                dicomContext.getRequestQueryParameters(), dicomService, resourceMethod);
        }
        dicomweb:SEARCH_STUDY_SERIES_INSTANCES => {
            return executeWithStudyAndSeries(pathParams.get("study"), pathParams.get("series"),
                dicomContext, dicomContext.getRequestQueryParameters(), dicomService,
                resourceMethod);
        }
        _ => { // No path param resources
            // dicomweb:SEARCH_ALL_STUDIES, dicomweb:SEARCH_ALL_SERIES or dicomweb:SEARCH_ALL_INSTANCES
            return executeWithNoPathParams(dicomContext, dicomContext.getRequestQueryParameters(),
                dicomService, resourceMethod);
        }
    }
}

isolated function getResourcePathParams(dicomweb:ResourceType resourceType, string[] path) returns map<string> {
    // Match and extract path parameter values from the path
    match resourceType {
        dicomweb:SEARCH_STUDY_SERIES|dicomweb:SEARCH_STUDY_INSTANCES => {
            return {"study": path[1]};
        }
        dicomweb:SEARCH_STUDY_SERIES_INSTANCES => {
            return {"study": path[1], "series": path[3]};
        }
        _ => {
            return {};
        }
    }
}

isolated function getDicomContext(http:RequestContext httpContext) returns DicomContext? {
    if httpContext.hasKey(DICOM_CONTEXT_PROP_NAME) {
        http:ReqCtxMember dicomContext = httpContext.get(DICOM_CONTEXT_PROP_NAME);
        if dicomContext is DicomContext {
            return dicomContext;
        }
    }
    return;
}

isolated function getErrorCode(error err) returns int {
    if err is dicomweb:Error {
        dicomweb:ErrorDetails errorDetails = err.detail();
        if !errorDetails.internalError {
            return errorDetails.httpStatusCode;
        }
    }
    return http:STATUS_INTERNAL_SERVER_ERROR;
}
