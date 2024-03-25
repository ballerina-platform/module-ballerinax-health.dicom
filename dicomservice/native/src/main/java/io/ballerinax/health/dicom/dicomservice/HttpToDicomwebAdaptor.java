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
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.async.StrandMetadata;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import static io.ballerinax.health.dicom.dicomservice.ModuleUtils.getModule;

/**
 * The class responsible for mapping a DICOM service to its underlying HTTP service.
 */
public class HttpToDicomwebAdaptor {

    /**
     * Strand metadata for the method "executeWithNoPathParams".
     */
    public static final StrandMetadata EXECUTE_WITH_NO_PATH_PARAMS = new StrandMetadata(
            getModule().getOrg(),
            getModule().getName(),
            getModule().getMajorVersion(),
            "executeWithNoPathParams"
    );

    /**
     * Strand metadata for the method "executeWithStudy".
     */
    public static final StrandMetadata EXECUTE_WITH_STUDY = new StrandMetadata(
            getModule().getOrg(),
            getModule().getName(),
            getModule().getMajorVersion(),
            "executeWithStudy"
    );

    /**
     * Strand metadata for the method "executeWithStudyAndSeries".
     */
    public static final StrandMetadata EXECUTE_WITH_STUDY_AND_SERIES = new StrandMetadata(
            getModule().getOrg(),
            getModule().getName(),
            getModule().getMajorVersion(),
            "executeWithStudyAndSeries"
    );

    /**
     * Executes the given DICOM service method with no path parameters.
     *
     * @param environment    The Ballerina environment.
     * @param dicomContext   The DICOM context.
     * @param queryParams    The query parameters.
     * @param service        The DICOM service object.
     * @param resourceMethod The resource method to be executed.
     * @return Null value.
     */
    public static Object executeWithNoPathParams(
            Environment environment, BObject dicomContext,
            BMap<Object, Object> queryParams, BObject service,
            ResourceMethodType resourceMethod
    ) {
        Future future = environment.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(future);
        ServiceType serviceType = (ServiceType) service.getType();
        Type returnType = TypeCreator.createUnionType(PredefinedTypes.TYPE_ANY, PredefinedTypes.TYPE_ERROR);
        if (resourceMethod != null) {
            if (serviceType.isIsolated() && serviceType.isIsolated(resourceMethod.getName())) {
                environment.getRuntime().invokeMethodAsyncConcurrently(service, resourceMethod.getName(), null,
                        EXECUTE_WITH_NO_PATH_PARAMS, executionCallback,
                        null, returnType, dicomContext, true, queryParams, true);
            } else {
                environment.getRuntime().invokeMethodAsyncSequentially(service, resourceMethod.getName(), null,
                        EXECUTE_WITH_NO_PATH_PARAMS, executionCallback,
                        null, returnType, dicomContext, true, queryParams, true);
            }
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
     * @return Null value.
     */
    public static Object executeWithStudy(
            Environment environment,
            BString study,
            BObject dicomContext,
            BMap<Object, Object> queryParams,
            BObject service,
            ResourceMethodType resourceMethod
    ) {
        Future future = environment.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(future);
        ServiceType serviceType = (ServiceType) service.getType();
        Type returnType = TypeCreator.createUnionType(PredefinedTypes.TYPE_ANY, PredefinedTypes.TYPE_ERROR);
        if (resourceMethod != null) {
            if (serviceType.isIsolated() && serviceType.isIsolated(resourceMethod.getName())) {
                environment.getRuntime().invokeMethodAsyncConcurrently(service, resourceMethod.getName(), null,
                        EXECUTE_WITH_STUDY, executionCallback,
                        null, returnType, study, true, dicomContext, true, queryParams, true);
            } else {
                environment.getRuntime().invokeMethodAsyncSequentially(service, resourceMethod.getName(), null,
                        EXECUTE_WITH_STUDY, executionCallback,
                        null, returnType, study, true, dicomContext, true, queryParams, true);
            }
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
     * @return Null value.
     */
    public static Object executeWithStudyAndSeries(
            Environment environment, BString study, BString series,
            BObject dicomContext, BMap<Object, Object> queryParams,
            BObject service,
            ResourceMethodType resourceMethod
    ) {
        Future future = environment.markAsync();
        ExecutionCallback executionCallback = new ExecutionCallback(future);
        ServiceType serviceType = (ServiceType) service.getType();
        Type returnType = TypeCreator.createUnionType(PredefinedTypes.TYPE_ANY, PredefinedTypes.TYPE_ERROR);
        if (resourceMethod != null) {
            if (serviceType.isIsolated() && serviceType.isIsolated(resourceMethod.getName())) {
                environment.getRuntime().invokeMethodAsyncConcurrently(service, resourceMethod.getName(), null,
                        EXECUTE_WITH_STUDY_AND_SERIES, executionCallback,
                        null, returnType, study, true, series, true, dicomContext, true, queryParams, true);
            } else {
                environment.getRuntime().invokeMethodAsyncSequentially(service, resourceMethod.getName(), null,
                        EXECUTE_WITH_STUDY_AND_SERIES, executionCallback,
                        null, returnType, study, true, series, true, dicomContext, true, queryParams, true);
            }
        }
        return null;
    }

}
