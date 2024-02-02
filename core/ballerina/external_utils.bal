import ballerina/jballerina.java;

isolated function javaBytesToInt(byte[] bytes, ByteOrder byteOrder) returns int = @java:Method {
    name: "bytesToInt",
    'class: "io.ballerinax.health.dicom.ByteUtils"
} external;

isolated function javaBytesToFloat(byte[] bytes, ByteOrder byteOrder) returns float = @java:Method {
    name: "bytesToFloat",
    'class: "io.ballerinax.health.dicom.ByteUtils"
} external;

isolated function javaIntToBytes(int n, ByteOrder byteOrder) returns byte[] = @java:Method {
    name: "intToBytes",
    'class: "io.ballerinax.health.dicom.ByteUtils"
} external;

isolated function javaFloatToBytes(float n, ByteOrder byteOrder) returns byte[] = @java:Method {
    name: "floatToBytes",
    'class: "io.ballerinax.health.dicom.ByteUtils"
} external;

