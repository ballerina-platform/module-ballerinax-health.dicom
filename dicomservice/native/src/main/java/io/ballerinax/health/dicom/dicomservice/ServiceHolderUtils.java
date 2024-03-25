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

import io.ballerina.runtime.api.values.BObject;

/**
 * This class includes utility functions related to DICOM service holder class.
 */
public class ServiceHolderUtils {

    private static final String DICOM_SERVICE_KEY = "DICOM_SERVICE";

    /**
     * Private constructor to prevent instantiation of this utility class.
     */
    private ServiceHolderUtils() {
    }

    /**
     * Adds a DICOM service to the specified holder object.
     *
     * @param holder  The holder object to which the DICOM service will be added.
     * @param service The DICOM service object to be added.
     */
    public static void addDicomService(BObject holder, BObject service) {
        holder.addNativeData(DICOM_SERVICE_KEY, service);
    }

    /**
     * Retrieves the DICOM service from the specified holder object.
     *
     * @param holder The holder object from which the DICOM service will be retrieved.
     * @return The DICOM service object retrieved from the holder.
     */
    public static BObject getDicomService(BObject holder) {
        return (BObject) holder.getNativeData(DICOM_SERVICE_KEY);
    }

}
