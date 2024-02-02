package io.ballerinax.health.dicom.dicomservice;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Module;

/**
 * This class includes utility functions related to Ballerina DICOM module.
 */
public class ModuleUtils {
    private static Module module;

    private ModuleUtils() {
    }

    public static Module getModule() {
        return module;
    }

    public static void setModule(Environment environment) {
        module = environment.getCurrentModule();
    }
}
