import ballerina/io;
import ballerina/test;
import ballerinax/health.dicom;

@test:Config {groups: ["utils"]}
function readPreambleTest() {
    // Sample 1
    string sample1File = "sample_1.DCM";
    io:ReadableByteChannel|io:Error sample1FileByteChannel = io:openReadableFile(string `./tests/resources/${sample1File}`);
    if sample1FileByteChannel is io:Error {
        test:assertFail(string `Could not open a readable byte channel to the sample file: ${sample1File}`);
    }
    byte[]|dicom:Error sample1readPreamble = readPreamble(sample1FileByteChannel);
    test:assertEquals(sample1readPreamble, sample1Preamble);
}

@test:Config {groups: ["utils"]}
function isValidFileValidFileTest() {
    string sample1File = "sample_1.DCM";
    io:ReadableByteChannel|io:Error sample1FileByteChannel = io:openReadableFile(string `./tests/resources/${sample1File}`);
    if sample1FileByteChannel is io:Error {
        test:assertFail(string `Could not open a readable byte channel to the sample file: ${sample1File}`);
    }
    test:assertTrue(isValidFile(sample1FileByteChannel, false));
}

@test:Config {groups: ["utils"]}
function isValidFileInvalidFileTest() {
    string invalidFile = "invalid.DCM";
    io:ReadableByteChannel|io:Error invalidFileByteChannel = io:openReadableFile(string `./tests/resources/${invalidFile}`);
    if invalidFileByteChannel is io:Error {
        test:assertFail(string `Could not open a readable byte channel to the sample file: ${invalidFile}`);
    }
    test:assertFalse(isValidFile(invalidFileByteChannel, false));
}
