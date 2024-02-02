import ballerina/http;

# Represents a DICOM service listener.
public isolated class Listener {

    private final http:Listener httpListener;
    private final ApiConfig apiConfig;
    private http:Service httpService = isolated service object {};

    public isolated function init(int port, ApiConfig apiConfig) returns error? {
        self.httpListener = check new (port);
        self.apiConfig = apiConfig;
    }

    public isolated function 'start() returns error? {
        return self.httpListener.'start();
    }

    public isolated function gracefulStop() returns error? {
        return self.httpListener.gracefulStop();
    }

    public isolated function immediateStop() returns error? {
        return self.httpListener.immediateStop();
    }

    public isolated function attach(Service dicomService, string[]|string? name = ()) returns error? {
        DicomServiceHolder dicomServiceHolder = new (dicomService);
        lock {
            self.httpService = getHttpService(dicomServiceHolder, self.apiConfig);
            check self.httpListener.attach(self.httpService, name.cloneReadOnly());
        }
    }

    public isolated function detach(Service dicomService) returns error? {
        lock {
            check self.httpListener.detach(self.httpService);
        }
    }
    
}
