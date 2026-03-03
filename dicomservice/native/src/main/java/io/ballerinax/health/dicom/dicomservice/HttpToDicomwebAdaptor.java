/*
 * Copyright (c) 2024 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerinax.health.dicom.dicomservice;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.concurrent.StrandMetadata;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import static io.ballerinax.health.dicom.dicomservice.ModuleUtils.getModule;

/**
 * The class responsible for mapping a DICOM service to its underlying HTTP service.
 */
public class HttpToDicomwebAdaptor {

    /**
     * Executes the given DICOM service method with no path parameters.
     *
     * @param environment    The Ballerina environment.
     * @param dicomContext   The DICOM context.
     * @param queryParams    The query parameters.
     * @param service        The DICOM service object.
     * @param resourceMethod The resource method to be executed.
     * @return Execution response payload object
     */
    public static Object executeWithNoPathParams(
            Environment environment, BObject dicomContext,
            BMap<Object, Object> queryParams, BObject service,
            ResourceMethodType resourceMethod
    ) {
        if (resourceMethod != null) {
            return environment.yieldAndRun(() -> {
                ServiceType serviceType = (ServiceType) service.getType();
                boolean isConcurrentSafe = serviceType.isIsolated() && serviceType.isIsolated(resourceMethod.getName());
                StrandMetadata metadata = new StrandMetadata(isConcurrentSafe, null);
                // Call method directly via yield context
                return environment.getRuntime().callMethod(service, resourceMethod.getName(), metadata, dicomContext, queryParams);
            });
        }
        return null;
    }

    /**
     * Executes the given DICOM service method with the study path parameter.
     *
     * @param environment    The Ballerina environment.
     * @param study          The study path parameter value.
     * @param dicomContext   The DICOM context.
     * @param queryParams    The query parameters.
     * @param service        The DICOM service object.
     * @param resourceMethod The resource method to be executed.
     * @return Execution response payload object
     */
    public static Object executeWithStudy(
            Environment environment,
            BString study,
            BObject dicomContext,
            BMap<Object, Object> queryParams,
            BObject service,
            ResourceMethodType resourceMethod
    ) {
        if (resourceMethod != null) {
            return environment.yieldAndRun(() -> {
                ServiceType serviceType = (ServiceType) service.getType();
                boolean isConcurrentSafe = serviceType.isIsolated() && serviceType.isIsolated(resourceMethod.getName());
                StrandMetadata metadata = new StrandMetadata(isConcurrentSafe, null);
                return environment.getRuntime().callMethod(service, resourceMethod.getName(), metadata, study, dicomContext, queryParams);
            });
        }
        return null;
    }

    /**
     * Executes the given DICOM service method with study and series path parameters.
     *
     * @param environment    The Ballerina environment.
     * @param study          The study path parameter value.
     * @param series         The series path parameter value.
     * @param dicomContext   The DICOM context.
     * @param queryParams    The query parameters.
     * @param service        The DICOM service object.
     * @param resourceMethod The resource method to be executed.
     * @return Execution response payload object
     */
    public static Object executeWithStudyAndSeries(
            Environment environment, BString study, BString series,
            BObject dicomContext, BMap<Object, Object> queryParams,
            BObject service,
            ResourceMethodType resourceMethod
    ) {
        if (resourceMethod != null) {
            return environment.yieldAndRun(() -> {
                ServiceType serviceType = (ServiceType) service.getType();
                boolean isConcurrentSafe = serviceType.isIsolated() && serviceType.isIsolated(resourceMethod.getName());
                StrandMetadata metadata = new StrandMetadata(isConcurrentSafe, null);
                return environment.getRuntime().callMethod(service, resourceMethod.getName(), metadata, study, series, dicomContext, queryParams);
            });
        }
        return null;
    }

}
