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

import org.apache.tools.ant.taskdefs.condition.Os

tasks.register<Exec>("build") {
    group = "build"
    dependsOn(":dicom-native:build")
    if (Os.isFamily(Os.FAMILY_WINDOWS)) {
        commandLine("cmd", "/c", "bal build")
    } else {
        commandLine("sh", "-c", "bal build")
    }
}

tasks.register<Exec>("balPack") {
    group = "build"
    dependsOn(":dicom-native:build")
    if (Os.isFamily(Os.FAMILY_WINDOWS)) {
        commandLine("cmd", "/c", "bal pack")
    } else {
        commandLine("sh", "-c", "bal pack")
    }
}

tasks.register<Exec>("balPushLocal") {
    group = "build"
    dependsOn(":dicom-ballerina:balPack")
    if (Os.isFamily(Os.FAMILY_WINDOWS)) {
        commandLine("cmd", "/c", "bal push --repository=local")
    } else {
        commandLine("sh", "-c", "bal push --repository=local")
    }
}

tasks.register<Delete>("clean") {
    group = "build"
    delete("target")
}
