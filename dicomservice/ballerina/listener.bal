// Copyright (c) 2024 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;

# Represents a DICOM service listener.
public isolated class Listener {

    private final http:Listener httpListener;
    private final ApiConfig apiConfig;
    private http:Service httpService = isolated service object {};

    # Initializes a new instance of the `Listener`.
    #
    # + int - Listening port
    # + apiConfig - The API config of the DICOM service
    public isolated function init(int port, ApiConfig apiConfig) returns error? {
        self.httpListener = check new (port);
        self.apiConfig = apiConfig;
    }

    # Starts the registered service of the listener programmatically.
    #
    # + return - An `error` if an error occurred during the listener starting process
    public isolated function 'start() returns error? {
        return self.httpListener.'start();
    }

    # Stops the listener gracefully.
    #
    # + return - An `error` if an error occurred during the listener stopping process
    public isolated function gracefulStop() returns error? {
        return self.httpListener.gracefulStop();
    }

    # Stops the listener immediately.
    #
    # + return - An `error` if an error occurred during the listener stop process
    public isolated function immediateStop() returns error? {
        return self.httpListener.immediateStop();
    }

    # Attaches a DICOM service to the listener.
    #
    # + dicomService - The DICOM service that needs to be attached
    # + name - Name of the service
    # + return - An `error` if an error occurred during the service attachment process or else `()`
    public isolated function attach(Service dicomService, string[]|string? name = ()) returns error? {
        DicomServiceHolder dicomServiceHolder = new (dicomService);
        lock {
            self.httpService = getHttpService(dicomServiceHolder, self.apiConfig);
            check self.httpListener.attach(self.httpService, name.cloneReadOnly());
        }
    }

    # Detaches a DICOM service from the listener.
    #
    # + dicomService - The DICOM service to be detached
    # + return - An `error` if one occurred during detaching of a service or else `()`
    public isolated function detach(Service dicomService) returns error? {
        lock {
            check self.httpListener.detach(self.httpService);
        }
    }

}
