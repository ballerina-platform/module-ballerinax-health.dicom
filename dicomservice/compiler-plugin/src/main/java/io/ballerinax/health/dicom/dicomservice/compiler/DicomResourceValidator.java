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

    /**
     * Validates the given DICOM resource method.
     *
     * @param context     The syntax node analysis context.
     * @param node        The function definition node representing the DICOM resource method.
     * @param typeSymbols A map containing type symbols.
     */
    public static void validateResource(SyntaxNodeAnalysisContext context, FunctionDefinitionNode node,
                                        Map<String, TypeSymbol> typeSymbols) {
        validateInputParams(context, node);
        extractReturnTypeAndValidate(context, node, typeSymbols);
    }

    /**
     * Validates the input parameters of a DICOM resource method.
     *
     * @param context The syntax node analysis context.
     * @param node    The function node representing the DICOM resource method.
     */
    private static void validateInputParams(SyntaxNodeAnalysisContext context, FunctionDefinitionNode node) {
        Optional<Symbol> resourceMethodSymbolOptional = context.semanticModel().symbol(node);
        if (resourceMethodSymbolOptional.isEmpty()) {
            return;
        }

        ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) resourceMethodSymbolOptional.get();
        List<ParameterSymbol> parameters = getResourceMethodParameters(resourceMethodSymbol);

        // DICOM resource methods should have minimum 2 params: DICOM context and query params map
        // and maximum 3 params: DICOM context, query params map, and payload
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

        // TODO: Implement third param (payload) validation
        // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1545
    }

    /**
     * Retrieves the parameters of a DICOM resource method.
     *
     * @param resourceMethodSymbol The symbol representing the DICOM resource method.
     * @return A list of parameter symbols.
     */
    private static List<ParameterSymbol> getResourceMethodParameters(ResourceMethodSymbol resourceMethodSymbol) {
        return resourceMethodSymbol.typeDescriptor().params().orElse(Collections.emptyList());
    }

    /**
     * Checks if the number of parameters is valid for a DICOM resource method.
     *
     * @param parameters The list of parameter symbols.
     * @return true if the number of parameters is valid, false otherwise.
     */
    private static boolean isValidNumberOfParameters(List<ParameterSymbol> parameters) {
        return parameters.size() >= Constants.MIN_RESOURCE_PARAM_COUNT && parameters.size() <= Constants.MAX_RESOURCE_PARAM_COUNT;
    }

    /**
     * Validates the given DICOM resource method parameter.
     *
     * @param paramSymbol             The parameter symbol to validate.
     * @param expectedParamName       The expected name of the parameter.
     * @param expectedParamModuleName The expected module name of the parameter.
     * @param context                 The syntax node analysis context.
     * @param node                    The function definition node representing the resource method.
     * @param diagnosticCode          The diagnostic code to use for reporting validation errors.
     */
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

    /**
     * Extracts the return type of DICOM resource method and validates it.
     *
     * @param ctx         The syntax node analysis context.
     * @param member      The function definition node representing the DICOM resource method.
     * @param typeSymbols A map containing type symbols.
     */
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
        String returnTypeStringValue =
                DicomCompilerPluginUtils.getReturnTypeDescription(returnTypeDescriptorNode.get());
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
