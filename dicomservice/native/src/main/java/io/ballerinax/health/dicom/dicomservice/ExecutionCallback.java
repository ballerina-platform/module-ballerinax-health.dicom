package io.ballerinax.health.dicom.dicomservice;

import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.values.BError;

/**
 * Callback class for executing dicomservice fields.
 */
public class ExecutionCallback implements Callback {
    private final Future future;

    ExecutionCallback(Future future) {
        this.future = future;
    }

    @Override
    public void notifySuccess(Object o) {
        this.future.complete(o);
    }

    @Override
    public void notifyFailure(BError bError) {
        this.future.complete(bError);
    }
}
