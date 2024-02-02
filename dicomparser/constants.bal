import ballerinax/health.dicom;

final byte[] & readonly DICOM_PREFIX = "DICM".toBytes().cloneReadOnly();

const PRIVATE_CREATOR_TAG_INFO = {
    vr: dicom:LO,
    vm: "1",
    name: "Private Creator",
    retired: "",
    keyword: "PrivateCreator"
};

const EMPTY_TAG_INFO = {
    vm: "",
    name: "",
    retired: "",
    keyword: ""
};

// DICOM transfer syntaxes supported by the parser
final dicom:TransferSyntax[] & readonly SUPPORTED_TRANSFER_SYNTAXES = [dicom:EXPLICIT_VR_LITTLE_ENDIAN];
