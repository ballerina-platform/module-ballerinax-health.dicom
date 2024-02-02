package io.ballerinax.health.dicom.dicomservice.compiler;

import io.ballerina.compiler.api.symbols.*;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Validator class that is used to validate a DICOM resource.
 */
public class DicomResourceValidator {

    public static void validateResource(SyntaxNodeAnalysisContext context, FunctionDefinitionNode node,
                                        Map<String, TypeSymbol> typeSymbols) {
        validateInputParams(context, node);
        extractReturnTypeAndValidate(context, node, typeSymbols);
    }

    private static void validateInputParams(SyntaxNodeAnalysisContext context, FunctionDefinitionNode node) {
        Optional<Symbol> resourceMethodSymbolOptional = context.semanticModel().symbol(node);
        if (resourceMethodSymbolOptional.isEmpty()) {
            return;
        }

        ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) resourceMethodSymbolOptional.get();
        List<ParameterSymbol> parameters = getResourceMethodParameters(resourceMethodSymbol);

        // Resource functions should have minimum 2 params: context and query params map
        // and maximum 3 params: context, query params map, and payload
        if (!isValidNumberOfParameters(parameters)) {
            DicomCompilerPluginUtils.updateDiagnostic(context, node.location(), DicomDiagnosticCode.DICOM_102);
            return;
        }

        // Validate first param
        validateParam(parameters.get(0), Constants.DICOM_CONTEXT, Constants.DICOM_SERVICE_PKG, context, node,
                DicomDiagnosticCode.DICOM_103);

        // Validate second param
        validateParam(parameters.get(1), Constants.QUERY_PARAMETER_MAP, Constants.DICOM_WEB_PKG, context, node,
                DicomDiagnosticCode.DICOM_104);

        //TODO: Implement third param validation
    }

    private static List<ParameterSymbol> getResourceMethodParameters(ResourceMethodSymbol resourceMethodSymbol) {
        return resourceMethodSymbol.typeDescriptor().params().orElse(Collections.emptyList());
    }

    private static boolean isValidNumberOfParameters(List<ParameterSymbol> parameters) {
        return parameters.size() >= 2 && parameters.size() <= 3;
    }

    private static void validateParam(
            ParameterSymbol paramSymbol,
            String expectedParamName,
            String expectedParamModuleName,
            SyntaxNodeAnalysisContext context,
            FunctionDefinitionNode node,
            DicomDiagnosticCode diagnosticCode
    ) {
        TypeSymbol typeSymbol = paramSymbol.typeDescriptor();
        String paramName = typeSymbol.getName().orElse("");
        String paramModuleName = typeSymbol.getModule().flatMap(Symbol::getName).orElse("");
        if (!(paramName.equals(expectedParamName) && paramModuleName.equals(expectedParamModuleName))) {
            DicomCompilerPluginUtils.updateDiagnostic(context, node.location(), diagnosticCode,
                    paramSymbol.typeDescriptor().signature());
        }
    }

    private static void extractReturnTypeAndValidate(
            SyntaxNodeAnalysisContext ctx,
            FunctionDefinitionNode member,
            Map<String, TypeSymbol> typeSymbols
    ) {
        Optional<ReturnTypeDescriptorNode> returnTypeDescriptorNode = member.functionSignature().returnTypeDesc();
        if (returnTypeDescriptorNode.isEmpty()) {
            return;
        }
        Node returnTypeNode = returnTypeDescriptorNode.get().type();
        String returnTypeStringValue = DicomCompilerPluginUtils.getReturnTypeDescription(returnTypeDescriptorNode.get());
        Optional<Symbol> functionSymbol = ctx.semanticModel().symbol(member);
        if (functionSymbol.isEmpty()) {
            return;
        }
        FunctionTypeSymbol functionTypeSymbol = ((FunctionSymbol) functionSymbol.get()).typeDescriptor();
        Optional<TypeSymbol> returnTypeSymbol = functionTypeSymbol.returnTypeDescriptor();
        if (returnTypeSymbol.isEmpty()) {
            return;
        }
        DicomCompilerPluginUtils.validateResourceReturnType(ctx, returnTypeNode, typeSymbols, returnTypeStringValue,
                returnTypeSymbol.get(), DicomDiagnosticCode.DICOM_105, false);
    }

}
