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
 * Class responsible for mapping a DICOM service to its underlying HTTP service.
 */
public class HttpToDicomwebAdaptor {
    public static final StrandMetadata EXECUTE_WITH_NO_PATH_PARAMS = new StrandMetadata(
            getModule().getOrg(),
            getModule().getName(),
            getModule().getMajorVersion(),
            "executeWithNoPathParams"
    );

    public static final StrandMetadata EXECUTE_WITH_STUDY = new StrandMetadata(
            getModule().getOrg(),
            getModule().getName(),
            getModule().getMajorVersion(),
            "executeWithStudy"
    );

    public static final StrandMetadata EXECUTE_WITH_STUDY_AND_SERIES = new StrandMetadata(
            getModule().getOrg(),
            getModule().getName(),
            getModule().getMajorVersion(),
            "executeWithStudyAndSeries"
    );

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
