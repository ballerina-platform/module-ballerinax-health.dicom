import ballerina/lang.regexp;
import ballerinax/health.dicom;

# Creates a DICOMweb attribute object value from the provided DICOM data element.
#
# + dataElement - The DICOM data element
# + return - The created `AttributeObjectValue` if successful, an `Error` if the value cannot be created, or
# `()` if the value length is 0
public isolated function createAttributeObjectValue(dicom:DataElement dataElement) returns AttributeObjectValue|Error? {
    do {
        // if value length is 0, that means no attribute object value
        if dataElement.vl == 0 {
            return;
        }
        match dataElement.vr {
            dicom:PN => {
                return check createPersonNameValue(dataElement);
            }
            dicom:SQ => {
                return check createSequenceValue(dataElement);
            }
        }
        return [dataElement.value];
    } on fail error e {
        string message = string `Failed creating attribute object value from data element: ${dataElement.toString()}`;
        return createInternalDicomwebError(message, cause = e);
    }
}

isolated function createPersonNameValue(dicom:DataElement personNameDataElement) returns PersonNameValue|Error {
    // Based off of Table 6.2-1 in Part 5 and Section F.2.2 in Part 18
    // Following name components should be included in the PN value response
    // - Alphabetic
    // - Ideographic
    // - Phonetic
    dicom:DataElementValue personNameValue = personNameDataElement.value;
    if personNameValue !is string {
        string message = string `Error creating person name value from: ${personNameDataElement.value.toString()}. ` +
                string `Value must be of 'string' type`;
        return createInternalDicomwebError(message);
    }
    PersonNameValue attributeObjectPersonNameValue = {};
    // Delimiter for component groups is "="
    string[] names = regexp:split(re `=`, personNameValue);
    foreach [int, string] [index, value] in names.enumerate() {
        match index {
            0 => {
                attributeObjectPersonNameValue.Alphabetic = value;
            }
            1 => {
                attributeObjectPersonNameValue.Ideographic = value;
            }
            2 => {
                attributeObjectPersonNameValue.Phonetic = value;
            }
        }
    }
    return attributeObjectPersonNameValue;
}

isolated function createSequenceValue(dicom:DataElement sequenceDataElement) returns ModelObject[]|Error {
    do {
        dicom:SequenceValue|error sequenceValue = sequenceDataElement.value.ensureType();
        if sequenceValue is error {
            fail error("Value must be of 'dicom:SequenceValue' type");
        }
        ModelObject[] attributeObjectSequenceValue = [];
        // Iterate sequence items and create model objects for each dataset
        foreach dicom:SequenceItem sequenceItem in sequenceValue {
            ModelObject sequenceModelObject = {};
            dicom:Dataset sequenceDataset = sequenceItem.valueDataset;
            // Add elements to sequence model object
            foreach dicom:DataElement dataElement in sequenceDataset {
                check addDataElement(sequenceModelObject, dataElement);
            }
            attributeObjectSequenceValue.push(sequenceModelObject);
        }
        return attributeObjectSequenceValue;
    } on fail error e {
        string message = string `Error creating sequence value from: ${sequenceDataElement.value.toString()}`;
        return createInternalDicomwebError(message, cause = e);
    }
}
