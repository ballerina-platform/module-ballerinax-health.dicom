package io.ballerinax.health.dicom.dicomservice;

import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

/**
 * Utility functions of DICOM service.
 */
public class Utils {

    public static final String PATH_PARAM_IDENTIFIER = "^";

    public static Object getResourceMethod(BObject service, BArray requestPath, BString accessor) {
        ServiceType serviceType = (ServiceType) service.getOriginalType();
        return getResourceMethod(serviceType, requestPath.getStringArray(), accessor.getValue());
    }

    private static ResourceMethodType getResourceMethod(
            ServiceType serviceType,
            String[] requestPath,
            String accessor
    ) {
        for (ResourceMethodType resourceMethod : serviceType.getResourceMethods()) {
            if (resourceMethod.getAccessor().equalsIgnoreCase(accessor)
                    && isPathsMatching(resourceMethod.getResourcePath(), requestPath)) {
                return resourceMethod;
            }
        }
        return null;
    }

    static boolean isPathsMatching(String[] resourcePath, String[] requestPath) {
        // Check if the array lengths are not equal, indicating a mismatch
        if (resourcePath.length != requestPath.length) {
            return false;
        }
        // Path params should match for paths to match
        for (int i = 0; i < resourcePath.length; i++) {
            String value1 = resourcePath[i];
            String value2 = requestPath[i];
            if (!value1.equals(value2) && !value1.equals(PATH_PARAM_IDENTIFIER)) {
                return false;
            }
        }
        return true;
    }

    public static boolean hasPathParam(ResourceMethodType resourceMethod) {
        for (String path : resourceMethod.getResourcePath()) {
            if (path.equals(PATH_PARAM_IDENTIFIER)) {
                return true;
            }
        }
        return false;
    }

    public static String getLastPath(ResourceMethodType resourceMethod) {
        String[] paths = resourceMethod.getResourcePath();
        return paths[paths.length - 1];
    }

}
