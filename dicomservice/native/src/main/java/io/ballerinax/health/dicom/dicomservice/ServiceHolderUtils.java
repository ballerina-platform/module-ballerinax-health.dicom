package io.ballerinax.health.dicom.dicomservice;

import io.ballerina.runtime.api.values.BObject;

/**
 * This class includes utility functions related to DICOM service holder class.
 */
public class ServiceHolderUtils {
    public static void addDicomService(BObject holder, BObject service) {
        holder.addNativeData("DICOM_SERVICE", service);
    }

    public static BObject getDicomService(BObject holder) {
        return (BObject) holder.getNativeData("DICOM_SERVICE");
    }
}
