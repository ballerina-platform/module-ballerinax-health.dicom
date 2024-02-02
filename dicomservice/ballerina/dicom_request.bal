import ballerinax/health.dicom.dicomweb;

# Class representing a DICOM request.
public isolated class DicomRequest {
    private final dicomweb:MimeType acceptType;
    private final dicomweb:QueryParameterMap & readonly queryParams;
    private final dicomweb:ResourceType resourceType;

    public isolated function init(dicomweb:MimeType acceptType, dicomweb:QueryParameterMap & readonly queryParams,
            dicomweb:ResourceType resourceType) {
        self.acceptType = acceptType;
        self.queryParams = queryParams;
        self.resourceType = resourceType;
    }

    public isolated function getAcceptType() returns dicomweb:MimeType {
        return self.acceptType;
    }

    public isolated function getQueryParameters() returns dicomweb:QueryParameterMap & readonly {
        return self.queryParams;
    }

    public isolated function getMatchQueryParameters() returns dicomweb:MatchParameterMap? & readonly {
        dicomweb:MatchParameterMap|error matchParams = trap self.queryParams.get(dicomweb:MATCH).ensureType();
        if matchParams is dicomweb:MatchParameterMap {
            return matchParams.cloneReadOnly();
        }
        return;
    }

    public isolated function getResourceType() returns dicomweb:ResourceType {
        return self.resourceType;
    }
}
