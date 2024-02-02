import org.apache.tools.ant.taskdefs.condition.Os

tasks.register<Exec>("build") {
    group = "build"
    dependsOn(":dicomservice-compiler-plugin:build")
    dependsOn(":dicomservice-native:build")
    if (Os.isFamily(Os.FAMILY_WINDOWS)) {
        commandLine("cmd", "/c", "bal build")
    } else {
        commandLine("sh", "-c", "bal build")
    }
}

tasks.register<Exec>("balPack") {
    group = "build"
    dependsOn(":dicomservice-compiler-plugin:build")
    dependsOn(":dicomservice-native:build")
    if (Os.isFamily(Os.FAMILY_WINDOWS)) {
        commandLine("cmd", "/c", "bal pack")
    } else {
        commandLine("sh", "-c", "bal pack")
    }
}

tasks.register<Exec>("balPushLocal") {
    group = "build"
    dependsOn(":dicomservice-ballerina:balPack")
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
