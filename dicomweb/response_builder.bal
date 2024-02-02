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

isolated function createModelObject(dicom:Dataset dataset, dicom:Tag[] resourceAttributes,
        QueryParameterMap processedQueryParams = {}) returns ModelObject|Error {
    do {
        // Model object construction is based off of Section F.2.2 in Part 18
        ModelObject modelObject = {};
        // Attribute matching should be handled first
        MatchParameterMap|error matchParams = trap processedQueryParams.get(MATCH).ensureType();
        if matchParams is MatchParameterMap {
            if !isMatchParamsMatching(dataset, matchParams) {  // Not matching
                return modelObject;
            }
        }
        // Add resource specific attributes
        check addResourceAttributes(modelObject, resourceAttributes, dataset);
        // Handle other query params
        // TODO: Implement fuzzymatching param support
        foreach [string, QueryParameterValue] [param, value] in processedQueryParams.entries() {
            match param {
                INCLUDEFIELD if value is IncludeFieldParameterValue => {
                    check addIncludeFieldParamAttributes(modelObject, value, dataset, resourceAttributes);
                }
            }
        }
        return getSortedModeObject(modelObject);
    } on fail error e {
        return createInternalDicomwebError("Failed to create model object from dataset", cause = e);
    }
}

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

isolated function addDataElement(ModelObject modelObject, dicom:DataElement dataElement) returns Error? {
    // Name of each attribute object is the eight character uppercase hexadecimal representation of the tag
    string attributeObjectName = dicom:tagToStr(dataElement.tag);
    AttributeObject|Error attributeObject = createAttributeObject(dataElement);
    if attributeObject is Error {
        return createInternalDicomwebError("Error adding data element to model object", cause = attributeObject);
    }
    modelObject[attributeObjectName] = attributeObject;
}

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
    }
    // InlineBinary
    if INLINE_BINARY_VRs.indexOf(vr) != () {
        // TODO: Implement
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

isolated function getSortedModeObject(ModelObject modelObject) returns ModelObject {
    // Attribute objects in a model object must be sorted by attribute name in ascending order
    // Section F.2.2 in Part 18
    string[] sortedKeys = modelObject.keys().sort();
    ModelObject sortedObject = {};
    foreach string key in sortedKeys {
        sortedObject[key] = modelObject.get(key);
    }
    return sortedObject;
}
