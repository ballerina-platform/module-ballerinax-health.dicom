// Copyright (c) 2024 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerinax/health.dicom;

# Generates a DICOMweb response.
#
# + datasets - An array of DICOM datasets to be included in the response 
# + processedQueryParams - A map of processed query parameters 
# + resourceType - The DICOMweb resource type the response belongs to
# + return - A `Response` representing the DICOMweb response, or an `Error` if the response cannot be generated
public isolated function generateResponse(dicom:Dataset[] datasets, ResourceType resourceType,
        QueryParameterMap processedQueryParams = {}) returns Response|Error {
    Response response = [];
    do {
        // Get resource specific response attributes
        dicom:Tag[]? resourceAttributes = getResourceResponseAttributes(resourceType);
        if resourceAttributes == () {
            fail error(string `Could not get resource specific response attributes for resource: ${resourceType}`);
        }
        // Response construction
        foreach dicom:Dataset dataset in datasets {
            ModelObject modelObject = check createModelObject(dataset, resourceAttributes, processedQueryParams);
            if modelObject.length() != 0 {
                response.push(modelObject);
            }
        }
        return response;
    } on fail error e {
        return createInternalDicomwebError("Error generating DICOMweb response from datasets", cause = e);
    }
}

# Creates a DICOMweb model object from a dataset.
#
# + dataset - The dataset to be used for the model object construction
# + resourceAttributes - The resource specific attributes that should be included in the model object
# + processedQueryParams - The processed query parameters map
# + return - The constructed `ModelObject` if the construction is successful, or an `Error` otherwise
isolated function createModelObject(dicom:Dataset dataset, dicom:Tag[] resourceAttributes,
        QueryParameterMap processedQueryParams = {}) returns ModelObject|Error {
    do {
        // Model object construction is based off of Section F.2.2 in Part 18
        ModelObject modelObject = {};
        // Attribute matching should be handled first
        MatchParameterMap|error matchParams = trap processedQueryParams.get(MATCH).ensureType();
        if matchParams is MatchParameterMap && !isMatchParamsMatching(dataset, matchParams) {
            return modelObject; // Not matching
        }
        // Add resource specific attributes
        check addResourceAttributes(modelObject, resourceAttributes, dataset);
        // Handle other query params
        // TODO: Implement fuzzymatching param support
        // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1376
        foreach [string, QueryParameterValue] [param, value] in processedQueryParams.entries() {
            match param {
                INCLUDEFIELD if value is IncludeFieldParameterValue => {
                    check addIncludeFieldParamAttributes(modelObject, value, dataset, resourceAttributes);
                }
            }
        }
        return getSortedModelObject(modelObject);
    } on fail error e {
        return createInternalDicomwebError("Failed to create model object from dataset", cause = e);
    }
}

# Adds resource specific attributes to a given model object.
#
# + modelObject - The model object to which the resource attributes should be added
# + resourceAttributes - The resource specific attributes that should be added to the model object
# + dataset - The dataset from which the resource attributes should be extracted
# + return - An `Error` if the resource attributes cannot be added to the model object, or `()` otherwise
isolated function addResourceAttributes(ModelObject modelObject, dicom:Tag[] resourceAttributes,
        dicom:Dataset dataset) returns Error? {
    foreach dicom:Tag tag in resourceAttributes {
        error? addToModelObjectResult = addTag(modelObject, tag, dataset);
        if addToModelObjectResult is error {
            return createInternalDicomwebError(string `Failed to add resource attribute: ${dicom:tagToStr(tag)}`,
                    cause = addToModelObjectResult);
        }
    }
}

# Adds attributes to a model object based on the `includefield` query parameter value.
#
# + modelObject - The model object to which the attributes should be added
# + includeFieldParameterValue - The value of the `includefield` query parameter
# + dataset - The dataset from which the attributes should be extracted
# + tagsToIgnore - The tags that should be ignored when adding attributes to the model object
# + return - An `Error` if the attributes cannot be added to the model object, or `()` otherwise
isolated function addIncludeFieldParamAttributes(ModelObject modelObject,
        IncludeFieldParameterValue includeFieldParameterValue,
        dicom:Dataset dataset, dicom:Tag[] tagsToIgnore) returns Error? {
    do {
        // Based off of Section 8.3.4.3 in Part 18
        // Includefield param value could be a comma-separated list of attributes(tags/keywords), or the single keyword "all".
        // "all" means that all available attributes of the object should be included in the response.
        if includeFieldParameterValue is string && includeFieldParameterValue == "all" {
            foreach dicom:DataElement dataElement in dataset {
                if tagsToIgnore.indexOf(dataElement.tag) == () { // Only add if not an ignored tag
                    Error? addDataElementRes = addDataElement(modelObject, dataElement);
                    if addDataElementRes is Error {
                        fail error(string `Failed to add 'includefield' value: all`);
                    }
                }
            }
        } else if includeFieldParameterValue is dicom:Tag[] { // Tags
            foreach dicom:Tag tag in includeFieldParameterValue {
                if tagsToIgnore.indexOf(tag) == () {
                    Error? addTagRes = addTag(modelObject, tag, dataset);
                    if addTagRes is Error {
                        fail error(string `Failed to add 'includefield' attribute: ${dicom:tagToStr(tag)}`);
                    }
                }
            }
        } else if includeFieldParameterValue is string[] { // Keywords
            foreach string keyword in includeFieldParameterValue {
                dicom:Tag? tag = dicom:getTagFromKeyword(keyword);
                if tag is dicom:Tag && tagsToIgnore.indexOf(tag) == () {
                    Error? addTagRes = addTag(modelObject, tag, dataset);
                    if addTagRes is Error {
                        fail error(string `Failed to add 'includefield' attribute: ${keyword}`);
                    }
                }
            }
        }
    } on fail error e {
        return createInternalDicomwebError(e.message(), cause = e);
    }
}

# Adds a tag to a model object.
#
# This is a convenience function that adds a data element to a model object using the tag.
#
# + modelObject - The model object to which the data element should be added
# + tag - The tag of the data element to be added
# + dataset - The dataset from which the data element should be extracted
# + return - An `Error` if the data element cannot be added to the model object, or `()` otherwise
isolated function addTag(ModelObject modelObject, dicom:Tag tag, dicom:Dataset dataset) returns Error? {
    do {
        // Get data element from the database
        dicom:DataElement|error dataElement = trap dataset.get(tag);
        if dataElement is dicom:DataElement {
            // Add to model object
            check addDataElement(modelObject, dataElement);
        }
    } on fail error e {
        string message = string `Error adding tag to model object: ${dicom:tagToStr(tag)}`;
        return createInternalDicomwebError(message, cause = e);
    }
}

# Adds a data element to a model object.
#
# + modelObject - The model object to which the data element should be added
# + dataElement - The data element to be added to the model object
# + return - An `Error` if the data element cannot be added to the model object, or `()` otherwise
isolated function addDataElement(ModelObject modelObject, dicom:DataElement dataElement) returns Error? {
    // Name of each attribute object is the eight character uppercase hexadecimal representation of the tag
    string attributeObjectName = dicom:tagToStr(dataElement.tag);
    AttributeObject|Error attributeObject = createAttributeObject(dataElement);
    if attributeObject is Error {
        return createInternalDicomwebError("Error adding data element to model object", cause = attributeObject);
    }
    modelObject[attributeObjectName] = attributeObject;
}

# Creates a DICOMweb attribute object from a data element.
#
# + dataElement - The data element to be used for the attribute object construction
# + return - The constructed `AttributeObject` if the construction is successful, or an `Error` otherwise
isolated function createAttributeObject(dicom:DataElement dataElement) returns AttributeObject|Error {
    // Based off of Section F.2.2 in Part 18
    // An attribute object contains the following,
    // - vr
    // - At most one of - Value, BulkDataURI, or InlineBinary
    string vr = dataElement.vr ?: "";
    // Attribute object
    AttributeObject attributeObject = {
        vr: vr
    };
    // BulkDataURI
    if BULK_DATA_URI_VRs.indexOf(vr) != () {
        // TODO: Implement
        // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1541
    }
    // InlineBinary
    if INLINE_BINARY_VRs.indexOf(vr) != () {
        // TODO: Implement
        // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/1542
    }
    // Value
    AttributeObjectValue|Error? attributeObjectValue = createAttributeObjectValue(dataElement);
    if attributeObjectValue is AttributeObjectValue {
        attributeObject.Value = attributeObjectValue;
    } else if attributeObjectValue is Error {
        string message = string `Error creating attribute object from data element: ${dataElement.toString()}`;
        return createInternalDicomwebError(message, cause = attributeObjectValue);
    }
    return attributeObject;
}

# Sorts a model object by attribute name in ascending order.
#
# + modelObject - The model object to be sorted
# + return - The sorted `ModelObject`
isolated function getSortedModelObject(ModelObject modelObject) returns ModelObject {
    // Attribute objects in a model object must be sorted by attribute name in ascending order
    // Section F.2.2 in Part 18
    string[] sortedKeys = modelObject.keys().sort();
    ModelObject sortedObject = {};
    foreach string key in sortedKeys {
        sortedObject[key] = modelObject.get(key);
    }
    return sortedObject;
}
