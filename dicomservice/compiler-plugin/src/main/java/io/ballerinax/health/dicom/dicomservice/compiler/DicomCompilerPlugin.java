package io.ballerinax.health.dicom.dicomservice.compiler;

import io.ballerina.projects.plugins.CompilerPlugin;
import io.ballerina.projects.plugins.CompilerPluginContext;

/**
 * The compiler plugin implementation for Ballerina {@code dicomservice} package.
 */
public class DicomCompilerPlugin extends CompilerPlugin {
    @Override
    public void init(CompilerPluginContext context) {
        context.addCodeAnalyzer(new DicomCodeAnalyzer());
    }
}
