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

# Represents a DICOM tag.
#
# + group - Group number of the tag
# + element - Element number of the tag
public type Tag readonly & record {|
    int:Unsigned16 group;
    int:Unsigned16 element;
|};

# Holds information about a Tag.
#
# + vr - Value representation of the data element
# + vm - Value multiplicity of the data element
# + name - Name of the data element
# + keyword - Keyword of the data element
# + retired - Indicates whether the data element is retired
public type TagInfo record {|
    Vr vr?;
    string vm;
    string name;
    // Retired data elements are elements that are not supported in the current standard.
    string retired;
    string keyword;
|};

# Represents a DICOM sequence item.
#
# + tag - Tag of the item data element 
# + length - Length of the item in bytes
# + valueDataset - Item value dataset
public type SequenceItem record {|
    readonly Tag tag;
    int length;
    Dataset valueDataset;
|};

# Represents a DICOM sequence value.
public type SequenceValue table<SequenceItem> key(tag);

# Represents a DICOM data element value.
public type DataElementValue string|int|float|SequenceValue|byte[]|Tag?;

# Represents a DICOM data element.
#
# + tag - Tag of the data element
# + vr - Value representation of the data element
# + vl - Value length of the data element
# + value - Value of the data element
public type DataElement record {|
    readonly Tag tag;
    Vr vr?;
    int vl?;
    DataElementValue value;
|};

# Represents a DICOM dataset.
public type Dataset table<DataElement> key(tag);

# Holds information of a DICOM file.
#
# + preamble - The Preamble of the file
# + dataset - The Parsed dataset
public type File record {|
    byte[] preamble;
    Dataset dataset;
|};

# Represents a VR value format validator function
type ValueFormatValidatorFn isolated function (Vr vr, string value) returns ValidationError?;

# Represents a VR value format validation regex string
type ValueFormatValidatorRegex string;

# Represents a VR value format validator type
type ValueFormatValidator ValueFormatValidatorFn|ValueFormatValidatorRegex;
