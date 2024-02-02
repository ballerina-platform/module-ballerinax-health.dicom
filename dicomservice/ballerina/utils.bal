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

# Concatenates multiple strings into a single string separated with a comma and a space.
#
# + strs - The strings to be concatenated
# + return - The concatenated string
isolated function joinWithComma(string... strs) returns string {
    return string:'join(", ", ...strs);
}

# Extracts the base path from a raw path string.
#
# + path - The raw path
# + return - The extracted base path
isolated function getBasePath(string path) returns string => regexp:split(re `\?`, path)[0];
