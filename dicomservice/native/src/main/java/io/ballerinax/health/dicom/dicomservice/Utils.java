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

import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

/**
 * This class includes utility functions related to DICOM service.
 */
public class Utils {

    public static final String PATH_PARAM_IDENTIFIER = "^";

    /**
     * Private constructor to prevent instantiation of this utility class.
     */
    private Utils() {
    }

    /**
     * Retrieves the resource method from the specified service object based on the request path and accessor.
     *
     * @param service     The service object from which the resource method will be retrieved.
     * @param requestPath The request path as an array of strings.
     * @param accessor    The accessor string used to identify the resource method.
     * @return The resource method corresponding to the request path and accessor.
     */
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

    /**
     * Checks if two paths match.
     *
     * @param resourcePath The resource path as an array of strings.
     * @param requestPath  The request path as an array of strings.
     * @return {@code true} if the paths match, {@code false} otherwise.
     */
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

    /**
     * Checks if the given resource method has path parameters.
     *
     * @param resourceMethod The resource method to be checked.
     * @return {@code true} if the resource method has path parameters, {@code false} otherwise.
     */
    public static boolean hasPathParam(ResourceMethodType resourceMethod) {
        for (String path : resourceMethod.getResourcePath()) {
            if (path.equals(PATH_PARAM_IDENTIFIER)) {
                return true;
            }
        }
        return false;
    }

}
