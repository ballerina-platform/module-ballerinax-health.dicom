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

/**
 * Constants related to the DICOM compiler plugin.
 */
public class Constants {
    public static final String DICOM_SERVICE_PKG = "health.dicom.dicomservice";
    public static final String DICOM_WEB_PKG = "health.dicom.dicomweb";
    public static final String BALLERINA = "ballerina";
    public static final String HTTP = "http";
    public static final String BALLERINAX = "ballerinax";
    public static final String DICOM_CONTEXT = "DicomContext";
    public static final String QUERY_PARAMETER_MAP = "QueryParameterMap";
    public static final String ALLOWED_RESOURCE_FIRST_PARAM = "dicomservice:DicomContext";
    public static final String ALLOWED_RESOURCE_SECOND_PARAM = "dicomweb:QueryParameterMap";
    public static final String ALLOWED_RESOURCE_RETURN_UNION = "anydata|http:Response|http:StatusCodeResponse|error";
    public static final String RESOURCE_RETURN_TYPE = "ResourceReturnType";
    public static final String INTERCEPTOR_RESOURCE_RETURN_TYPE = "InterceptorResourceReturnType";
    public static final int MIN_RESOURCE_PARAM_COUNT = 2;
    public static final int MAX_RESOURCE_PARAM_COUNT = 3;

    public static final String REMOTE_KEYWORD = "remote";
    public static final String RESPONSE_OBJ_NAME = "Response";
    public static final String ANYDATA = "anydata";
    public static final String JSON = "json";
    public static final String ERROR = "error";
    public static final String STRING = "string";
    public static final String STRING_ARRAY = "string[]";
    public static final String INT = "int";
    public static final String INT_ARRAY = "int[]";
    public static final String FLOAT = "float";
    public static final String FLOAT_ARRAY = "float[]";
    public static final String DECIMAL = "decimal";
    public static final String DECIMAL_ARRAY = "decimal[]";
    public static final String BOOLEAN = "boolean";
    public static final String BOOLEAN_ARRAY = "boolean[]";
    public static final String ARRAY_OF_MAP_OF_ANYDATA = "map<anydata>[]";
    public static final String NIL = "nil";
    public static final String BYTE_ARRAY = "byte[]";
    public static final String XML = "xml";
    public static final String MAP_OF_ANYDATA = "map<anydata>";
    public static final String TABLE_OF_ANYDATA_MAP = "table<anydata>";
    public static final String TUPLE_OF_ANYDATA = "[anydata...]";
    public static final String STRUCTURED_ARRAY = "(map<anydata>|table<map<anydata>>|[anydata...])[]";
    public static final String NILABLE_STRING = "string?";
    public static final String NILABLE_INT = "int?";
    public static final String NILABLE_FLOAT = "float?";
    public static final String NILABLE_DECIMAL = "decimal?";
    public static final String NILABLE_BOOLEAN = "boolean?";
    public static final String NILABLE_MAP_OF_ANYDATA = "map<anydata>?";
    public static final String NILABLE_STRING_ARRAY = "string[]?";
    public static final String NILABLE_INT_ARRAY = "int[]?";
    public static final String NILABLE_FLOAT_ARRAY = "float[]?";
    public static final String NILABLE_DECIMAL_ARRAY = "decimal[]?";
    public static final String NILABLE_BOOLEAN_ARRAY = "boolean[]?";
    public static final String NILABLE_MAP_OF_ANYDATA_ARRAY = "map<anydata>[]?";
    public static final String CALLER_OBJ_NAME = "Caller";
    public static final String REQUEST_OBJ_NAME = "Request";
    public static final String REQUEST_CONTEXT_OBJ_NAME = "RequestContext";
    public static final String OBJECT = "object";
    public static final String HEADER_OBJ_NAME = "Headers";

    public static final String EMPTY = "";
}
