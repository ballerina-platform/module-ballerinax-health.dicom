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

import ballerina/lang.regexp;

// DICOM tags maps
public final map<json> & readonly standardTagsMap;
public final map<json> & readonly repeatingTagsMap;
public final map<json> & readonly privateTagsMap;
public final map<int[]> & readonly repeatingTagsMasks;

# Initializes the `core` package.
#
# + return - An `Error` if an error occurs during the initialization, `()` otherwise.
function init() returns Error? {
    do {
        // Initialize tags maps
        map<json> standardTags = check STANDARD_TAGS_DICT.fromJsonStringWithType();
        standardTagsMap = standardTags.cloneReadOnly();

        map<json> repeatingTags = check REPEATING_TAGS_DICT.fromJsonStringWithType();
        repeatingTagsMap = repeatingTags.cloneReadOnly();

        map<json> privateTags = check PRIVATE_TAGS_DICT.fromJsonStringWithType();
        privateTagsMap = privateTags.cloneReadOnly();

        // Generate repeating tags masks map
        // This map will be used to map a true bitwise mask to the DICOM mask with "x"s in it
        // "x" is used as a wildcard character in repeating groups
        // Section 7.6 in Part 5
        map<int[]> masks = {};
        foreach var tag in repeatingTagsMap.keys() {
            string mask1Str = regexp:replaceAll(re `x`, tag, "0");
            int mask1 = check int:fromHexString(mask1Str);
            string mask2Str = "";
            foreach var item in tag {
                mask2Str += item == "x" ? "0" : "F";
            }
            int mask2 = check int:fromHexString(mask2Str);
            masks[tag] = [mask1, mask2];
        }
        repeatingTagsMasks = masks.cloneReadOnly();
    } on fail error e {
        return error Error("Error initializing core package", e);
    }
}
