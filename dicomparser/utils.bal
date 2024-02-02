import ballerina/io;
import ballerinax/health.dicom;

# Reads the preamble from a DICOM file.
#
# + fileByteChannel - The byte channel containing the DICOM file data
# + return - A `byte[]` containing the preamble data, or a `dicom:Error` if the reading fails
public isolated function readPreamble(io:ReadableByteChannel fileByteChannel) returns byte[]|dicom:Error {
    // First 128 bytes of the file is the preamble
    // From Section 7.1 in Part 10
    byte[]|io:Error preamble = fileByteChannel.read(128);
    if preamble is byte[] {
        if preamble.length() == 128 {
            return preamble;
        }
        return error dicom:Error(string `Invalid preamble length: Expected 128 bytes, Found ${preamble.length()} bytes`);
    } else {
        return error dicom:Error("Error reading preamble", preamble);
    }
}

# Checks if a file is a valid DICOM file
#
# + fileByteChannel - The byte channel containing the DICOM file data 
# + preambleRead - A flag indicating whether the preamble has already been read
# + return - `true` if the file is a valid DICOM file, `false` otherwise
public isolated function isValidFile(io:ReadableByteChannel fileByteChannel,
        boolean preambleRead = false) returns boolean {
    // DICOM prefix is the 4 bytes after the preamble
    // Based off of Section 7.1 in Part 10
    // If the preamble has not been read yet, attempt to read it now
    if !preambleRead {
        byte[]|error preamble = readPreamble(fileByteChannel);
        if preamble is error {
            return false;
        }
    }
    return fileByteChannel.read(4) == DICOM_PREFIX;
}

isolated function isSupportedTransferSyntax(dicom:TransferSyntax transferSyntax) returns boolean
        => SUPPORTED_TRANSFER_SYNTAXES.indexOf(transferSyntax) != ();
