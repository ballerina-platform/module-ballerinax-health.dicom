package io.ballerinax.health.dicom.dicomservice.compiler;

import io.ballerina.compiler.api.symbols.*;
import io.ballerina.compiler.syntax.tree.*;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.List;
import java.util.Optional;

import static io.ballerinax.health.dicom.dicomservice.compiler.DicomCompilerPluginUtils.getCtxTypes;

/**
 * The {@code AnalysisTask} that validates a Ballerina DICOM service.
 * This task checks that the service meets the requirements of a DICOM service.
 */
public class DicomServiceAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {
    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        // Check for compilation errors
        if (hasCompilationErrors(syntaxNodeAnalysisContext)) {
            return;
        }

        // Check if a DICOM service (with a DICOM listener)
        if (!isDicomService(syntaxNodeAnalysisContext)) {
            return;
        }

        // Check the members of the service
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) syntaxNodeAnalysisContext.node();
        NodeList<Node> members = serviceDeclarationNode.members();
        for (Node member : members) {
            if (member.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION) {
                FunctionDefinitionNode node = (FunctionDefinitionNode) member;
                NodeList<Token> tokens = node.qualifierList();
                if (tokens.isEmpty()) {
                    continue;
                }
                for (Token token : tokens) {
                    if (token.text().equals(Constants.REMOTE_KEYWORD)) {
                        DicomCompilerPluginUtils.updateDiagnostic(syntaxNodeAnalysisContext, node.location(),
                                DicomDiagnosticCode.DICOM_101);
                    }
                }
            } else if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {  // Validate resource functions
                FunctionDefinitionNode node = (FunctionDefinitionNode) member;
                DicomResourceValidator.validateResource(syntaxNodeAnalysisContext, node,
                        getCtxTypes(syntaxNodeAnalysisContext));
            }
        }
    }

    private boolean hasCompilationErrors(SyntaxNodeAnalysisContext context) {
        List<Diagnostic> diagnosticList = context.semanticModel().diagnostics();
        for (Diagnostic diagnostic : diagnosticList) {
            if (diagnostic.diagnosticInfo().severity() == DiagnosticSeverity.ERROR) {
                return true;
            }
        }
        return false;
    }

    private boolean isDicomService(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) context.node();
        Optional<Symbol> serviceSymbolOptional = context.semanticModel().symbol(serviceDeclarationNode);
        if (serviceSymbolOptional.isEmpty()) {
            return false;
        }
        if (serviceSymbolOptional.get().kind() != SymbolKind.SERVICE_DECLARATION) {
            return false;
        }
        ServiceDeclarationSymbol symbol = (ServiceDeclarationSymbol) serviceSymbolOptional.get();
        return hasDicomListener(symbol);
    }

    private boolean hasDicomListener(ServiceDeclarationSymbol symbol) {
        for (TypeSymbol listener : symbol.listenerTypes()) {
            if (isDicomListener(listener)) {
                return true;
            }
        }
        return false;
    }

    private boolean isDicomListener(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            UnionTypeSymbol unionTypeSymbol = (UnionTypeSymbol) typeSymbol;
            for (TypeSymbol symbol : unionTypeSymbol.memberTypeDescriptors()) {
                if (isDicomModuleSymbol(symbol)) {
                    return true;
                }
            }
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            TypeReferenceTypeSymbol typeReferenceTypeSymbol = (TypeReferenceTypeSymbol) typeSymbol;
            return isDicomModuleSymbol(typeReferenceTypeSymbol);
        }
        return false;
    }

    private boolean isDicomModuleSymbol(Symbol symbol) {
        if (symbol.getModule().isEmpty()) {
            return false;
        }
        String module = symbol.getModule().get().id().moduleName();
        String org = symbol.getModule().get().id().orgName();
        return module.equals(Constants.DICOM_SERVICE_PKG) && org.equals(Constants.BALLERINAX);
    }

}
