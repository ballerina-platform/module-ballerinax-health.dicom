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

import io.ballerina.compiler.api.Types;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.Location;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import static io.ballerinax.health.dicom.dicomservice.compiler.Constants.*;

/**
 * Utility class providing DICOM compiler plugin utility methods.
 */
public class DicomCompilerPluginUtils {

    /**
     * Private constructor to prevent instantiation of this utility class.
     */
    private DicomCompilerPluginUtils() {
    }

    /**
     * Updates the diagnostic information.
     *
     * @param context             The syntax node analysis context
     * @param location            The location of the diagnostic
     * @param dicomDiagnosticCode The DICOM diagnostic code
     */
    public static void updateDiagnostic(
            SyntaxNodeAnalysisContext context,
            Location location,
            DicomDiagnosticCode dicomDiagnosticCode
    ) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(dicomDiagnosticCode);
        context.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }

    /**
     * Updates the diagnostic information.
     *
     * @param context             The syntax node analysis context
     * @param location            The location of the diagnostic
     * @param dicomDiagnosticCode The DICOM diagnostic code
     * @param args                The arguments to be passed to the diagnostic message
     */
    public static void updateDiagnostic(
            SyntaxNodeAnalysisContext context,
            Location location,
            DicomDiagnosticCode dicomDiagnosticCode,
            Object... args
    ) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(dicomDiagnosticCode, args);
        context.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location, args));
    }

    /**
     * Returns the diagnostic information.
     *
     * @param diagnostic The DICOM diagnostic code
     * @return The diagnostic information
     */
    public static DiagnosticInfo getDiagnosticInfo(DicomDiagnosticCode diagnostic, Object... args) {
        return new DiagnosticInfo(diagnostic.getCode(), String.format(diagnostic.getMessage(), args),
                diagnostic.getSeverity());
    }

    /**
     * Reports an invalid return type.
     *
     * @param ctx            The syntax node analysis context
     * @param node           The node
     * @param returnType     The return type
     * @param diagnosticCode The diagnostic code
     */
    private static void reportInvalidReturnType(
            SyntaxNodeAnalysisContext ctx, Node node,
            String returnType,
            DicomDiagnosticCode diagnosticCode
    ) {
        updateDiagnostic(ctx, node.location(), diagnosticCode, returnType);
    }

    /**
     * Returns the return type description.
     *
     * @param returnTypeDescriptorNode The return type descriptor node
     * @return The return type description
     */
    public static String getReturnTypeDescription(ReturnTypeDescriptorNode returnTypeDescriptorNode) {
        return returnTypeDescriptorNode.type().toString().trim();
    }

    /**
     * Validates the resource return type.
     *
     * @param ctx                   The syntax node analysis context
     * @param node                  The node
     * @param typeSymbols           The type symbols
     * @param returnTypeStringValue The return type string value
     * @param returnTypeSymbol      The return type symbol
     * @param diagnosticCode        The diagnostic code
     * @param isInterceptorType     Whether the return type is an interceptor type
     */
    public static void validateResourceReturnType(
            SyntaxNodeAnalysisContext ctx, Node node,
            Map<String, TypeSymbol> typeSymbols, String returnTypeStringValue,
            TypeSymbol returnTypeSymbol, DicomDiagnosticCode diagnosticCode,
            boolean isInterceptorType
    ) {
        if (subtypeOf(typeSymbols, returnTypeSymbol,
                isInterceptorType ? INTERCEPTOR_RESOURCE_RETURN_TYPE : RESOURCE_RETURN_TYPE)) {
            return;
        }
        reportInvalidReturnType(ctx, node, returnTypeStringValue, diagnosticCode);
    }

    /**
     * Checks if the given type symbol is a subtype of the target type.
     *
     * @param typeSymbols    The type symbols
     * @param typeSymbol     The type symbol to be checked
     * @param targetTypeName The target type name
     * @return {@code true} if the given type symbol is a subtype of the target type, {@code false} otherwise
     */
    public static boolean subtypeOf(
            Map<String, TypeSymbol> typeSymbols,
            TypeSymbol typeSymbol,
            String targetTypeName
    ) {
        TypeSymbol targetTypeSymbol = typeSymbols.get(targetTypeName);
        if (targetTypeSymbol != null) {
            return typeSymbol.subtypeOf(targetTypeSymbol);
        }
        return false;
    }

    /**
     * Retrieves the context types from the provided syntax node analysis context.
     * <p>
     * This method creates and returns a map of type symbols, populates it with HTTP module types and required
     * Ballerina lang types.
     * </p>
     * @param ctx The syntax node analysis context
     * @return The context types
     */
    public static Map<String, TypeSymbol> getCtxTypes(SyntaxNodeAnalysisContext ctx) {
        Map<String, TypeSymbol> typeSymbols = new HashMap<>();
        populateHttpModuleTypes(ctx, typeSymbols);
        populateRequiredLangTypes(ctx, typeSymbols);
        return typeSymbols;
    }

    /**
     * Populates a type symbols map with HTTP module types.
     *
     * @param ctx         The syntax node analysis context
     * @param typeSymbols The type symbols map to be populated
     */
    private static void populateHttpModuleTypes(SyntaxNodeAnalysisContext ctx, Map<String, TypeSymbol> typeSymbols) {
        String[] requiredTypeNames = {RESOURCE_RETURN_TYPE, CALLER_OBJ_NAME,
                REQUEST_OBJ_NAME, REQUEST_CONTEXT_OBJ_NAME, HEADER_OBJ_NAME, RESPONSE_OBJ_NAME};
        Optional<Map<String, Symbol>> optionalMap = ctx.semanticModel().types().typesInModule(BALLERINA, HTTP, EMPTY);
        if (optionalMap.isPresent()) {
            Map<String, Symbol> symbolMap = optionalMap.get();
            for (String typeName : requiredTypeNames) {
                Symbol symbol = symbolMap.get(typeName);
                if (symbol instanceof TypeSymbol) {
                    typeSymbols.put(typeName, (TypeSymbol) symbol);
                } else if (symbol instanceof TypeDefinitionSymbol) {
                    typeSymbols.put(typeName, ((TypeDefinitionSymbol) symbol).typeDescriptor());
                }
            }
        }
    }

    /**
     * Populates a type symbols map with required Ballerina lang types.
     *
     * @param ctx         The syntax node analysis context
     * @param typeSymbols The type symbols map to be populated
     */
    private static void populateRequiredLangTypes(SyntaxNodeAnalysisContext ctx, Map<String, TypeSymbol> typeSymbols) {
        Types types = ctx.semanticModel().types();
        populateBasicTypes(typeSymbols, types);
        populateNilableBasicTypes(typeSymbols, types);
        populateBasicArrayTypes(typeSymbols, types);
        populateNilableBasicArrayTypes(typeSymbols, types);
    }

    /**
     * Populates a type symbols map with Ballerina basic array types.
     *
     * @param typeSymbols The type symbols map to be populated
     * @param types       The types
     */
    private static void populateBasicArrayTypes(Map<String, TypeSymbol> typeSymbols, Types types) {
        typeSymbols.put(STRING_ARRAY, types.builder().ARRAY_TYPE.withType(types.STRING).build());
        typeSymbols.put(BOOLEAN_ARRAY, types.builder().ARRAY_TYPE.withType(types.BOOLEAN).build());
        typeSymbols.put(INT_ARRAY, types.builder().ARRAY_TYPE.withType(types.INT).build());
        typeSymbols.put(FLOAT_ARRAY, types.builder().ARRAY_TYPE.withType(types.FLOAT).build());
        typeSymbols.put(DECIMAL_ARRAY, types.builder().ARRAY_TYPE.withType(types.DECIMAL).build());
        typeSymbols.put(ARRAY_OF_MAP_OF_ANYDATA, types.builder().ARRAY_TYPE.withType(
                types.builder().MAP_TYPE.withTypeParam(types.ANYDATA).build()).build());
        typeSymbols.put(STRUCTURED_ARRAY, types.builder().ARRAY_TYPE
                .withType(
                        types.builder().UNION_TYPE
                                .withMemberTypes(
                                        typeSymbols.get(MAP_OF_ANYDATA),
                                        typeSymbols.get(TABLE_OF_ANYDATA_MAP),
                                        typeSymbols.get(TUPLE_OF_ANYDATA)).build()).build());
        typeSymbols.put(BYTE_ARRAY, types.builder().ARRAY_TYPE.withType(types.BYTE).build());
    }

    /**
     * Populates a type symbols map with Ballerina basic types.
     *
     * @param typeSymbols The type symbols map to be populated
     * @param types       The types
     */
    private static void populateBasicTypes(Map<String, TypeSymbol> typeSymbols, Types types) {
        typeSymbols.put(ANYDATA, types.ANYDATA);
        typeSymbols.put(JSON, types.JSON);
        typeSymbols.put(ERROR, types.ERROR);
        typeSymbols.put(STRING, types.STRING);
        typeSymbols.put(BOOLEAN, types.BOOLEAN);
        typeSymbols.put(INT, types.INT);
        typeSymbols.put(FLOAT, types.FLOAT);
        typeSymbols.put(DECIMAL, types.DECIMAL);
        typeSymbols.put(XML, types.XML);
        typeSymbols.put(NIL, types.NIL);
        typeSymbols.put(OBJECT, types.builder().OBJECT_TYPE.build());
        typeSymbols.put(MAP_OF_ANYDATA, types.builder().MAP_TYPE.withTypeParam(types.ANYDATA).build());
        typeSymbols.put(TABLE_OF_ANYDATA_MAP, types.builder().TABLE_TYPE.withRowType(
                typeSymbols.get(MAP_OF_ANYDATA)).build());
        typeSymbols.put(TUPLE_OF_ANYDATA, types.builder().TUPLE_TYPE.withRestType(types.ANYDATA).build());
    }

    /**
     * Populates a type symbols map with Ballerina nilable basic types.
     *
     * @param typeSymbols The type symbols map to be populated
     * @param types       The types
     */
    private static void populateNilableBasicTypes(Map<String, TypeSymbol> typeSymbols, Types types) {
        typeSymbols.put(NILABLE_STRING, types.builder().UNION_TYPE.withMemberTypes(types.STRING, types.NIL).build());
        typeSymbols.put(NILABLE_BOOLEAN, types.builder().UNION_TYPE.withMemberTypes(types.BOOLEAN, types.NIL).build());
        typeSymbols.put(NILABLE_INT, types.builder().UNION_TYPE.withMemberTypes(types.INT, types.NIL).build());
        typeSymbols.put(NILABLE_FLOAT, types.builder().UNION_TYPE.withMemberTypes(types.FLOAT, types.NIL).build());
        typeSymbols.put(NILABLE_DECIMAL, types.builder().UNION_TYPE.withMemberTypes(types.DECIMAL, types.NIL).build());
        typeSymbols.put(NILABLE_MAP_OF_ANYDATA, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(MAP_OF_ANYDATA), types.NIL).build());
    }

    /**
     * Populates a type symbols map with Ballerina nilable basic array types.
     *
     * @param typeSymbols The type symbols map to be populated
     * @param types       The types
     */
    private static void populateNilableBasicArrayTypes(Map<String, TypeSymbol> typeSymbols, Types types) {
        typeSymbols.put(NILABLE_STRING_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(STRING_ARRAY), types.NIL).build());
        typeSymbols.put(NILABLE_BOOLEAN_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(BOOLEAN_ARRAY), types.NIL).build());
        typeSymbols.put(NILABLE_INT_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(INT_ARRAY), types.NIL).build());
        typeSymbols.put(NILABLE_FLOAT_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(FLOAT_ARRAY), types.NIL).build());
        typeSymbols.put(NILABLE_DECIMAL_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(DECIMAL_ARRAY), types.NIL).build());
        typeSymbols.put(NILABLE_MAP_OF_ANYDATA_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(ARRAY_OF_MAP_OF_ANYDATA), types.NIL).build());
    }
}
