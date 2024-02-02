import ballerinax/health.dicom.dicomweb;

# Class representing a DICOM context.
public isolated class DicomContext {
    private MessageDirection direction = IN;
    private final DicomRequest dicomRequest;
    private final HttpRequest & readonly httpRequest;
    private boolean inErrorState = false;
    private int errorCode = 500;

    public isolated function init(DicomRequest dicomRequest, HttpRequest & readonly httpRequest) {
        self.dicomRequest = dicomRequest;
        self.httpRequest = httpRequest;
    }

    public isolated function setDirection(MessageDirection direction) {
        lock {
            self.direction = direction;
        }
    }

    public isolated function getDirection() returns MessageDirection {
        lock {
            return self.direction;
        }
    }

    public isolated function isInErrorState() returns boolean {
        lock {
            return self.inErrorState;
        }
    }

    public isolated function setInErrorState(boolean inErrorState) {
        lock {
            self.inErrorState = inErrorState;
        }
    }

    public isolated function getErrorCode() returns int {
        lock {
            return self.errorCode;
        }
    }

    public isolated function setErrorCode(int errorCode) {
        lock {
            self.errorCode = errorCode;
        }
    }

    public isolated function getDicomRequest() returns DicomRequest? {
        return self.dicomRequest;
    }

    public isolated function getHttpRequest() returns HttpRequest? & readonly {
        return self.httpRequest;
    }

    public isolated function getDicomRequestResourceType() returns dicomweb:ResourceType {
        return self.dicomRequest.getResourceType();
    }

    public isolated function getClientAcceptFormat() returns dicomweb:MimeType {
        return self.dicomRequest.getAcceptType();
    }

    public isolated function getRequestQueryParameters() returns dicomweb:QueryParameterMap & readonly {
        return self.dicomRequest.getQueryParameters();
    }

    public isolated function getRequestQueryParameterValue(string param) returns dicomweb:QueryParameterValue? {
        dicomweb:QueryParameterMap & readonly queryParams = self.dicomRequest.getQueryParameters();
        if queryParams.hasKey(param) {
            return queryParams.get(param);
        } else if queryParams.hasKey(dicomweb:MATCH) {  // Check match parameters
            dicomweb:MatchParameterMap|error matchParams = queryParams.get(dicomweb:MATCH).ensureType();
            if matchParams is dicomweb:MatchParameterMap && matchParams.hasKey(param) {
                return matchParams.get(param);
            }
        }
        return;
    }

}
