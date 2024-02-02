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

import ballerinax/health.dicom.dicomweb;

# DICOM context message direction.
public enum MessageDirection {
    IN,
    OUT
}

# DICOM request context property name.
public const DICOM_CONTEXT_PROP_NAME = "_OH_DICOM_REQUEST_CONTEXT_";

# Default API config
public final ApiConfig DEFAULT_API_CONFIG = {
    queryParameters: [
        {
            name: dicomweb:INCLUDEFIELD,
            active: true,
            preProcessor: includeFieldQueryParamPreProcessor
        },
        {
            name: dicomweb:LIMIT,
            active: true,
            preProcessor: limitQueryParamPreProcessor,
            postProcessor: limitQueryParamPostProcessor
        },
        {
            name: dicomweb:OFFSET,
            active: true,
            preProcessor: offsetQueryParamPreProcessor,
            postProcessor: offsetQueryParamPostProcessor
        },
        {
            name: dicomweb:FUZZYMATCHING,
            active: false
        }
    ]
};
