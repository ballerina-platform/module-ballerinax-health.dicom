package io.ballerinax.health.dicom.dicomservice.compiler;

import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.CodeAnalysisContext;
import io.ballerina.projects.plugins.CodeAnalyzer;

/**
 * The {@code CodeAnalyzer} for Ballerina DICOM services.
 */
public class DicomCodeAnalyzer extends CodeAnalyzer {
    @Override
    public void init(CodeAnalysisContext codeAnalysisContext) {
        codeAnalysisContext.addSyntaxNodeAnalysisTask(new DicomServiceAnalysisTask(), SyntaxKind.SERVICE_DECLARATION);
    }
}
