import ballerinax/health.dicom;

# DICOMweb MIME types.
public enum MimeType {
    MIME_TYPE_XML = "application/xml",
    MIME_TYPE_DICOM_XML = "application/dicom+xml",
    MIME_TYPE_JSON = "application/json",
    MIME_TYPE_DICOM_JSON = "application/dicom+json"
}

# DICOMweb IE levels.
public enum IeLevel {
    STUDY,
    SERIES,
    INSTANCE
}

# DICOMweb query parameters.
public enum QueryParameter {
    MATCH = "match",
    FUZZYMATCHING = "fuzzymatching",
    INCLUDEFIELD = "includefield",
    LIMIT = "limit",
    OFFSET = "offset"
}

# DICOMweb resource types.
public enum ResourceType {
    RETRIEVE_STUDY_INSTANCES,
    RETRIEVE_SERIES_INSTANCES,
    RETRIEVE_INSTANCE,
    STORE_STUDIES,
    STORE_STUDY,
    SEARCH_ALL_STUDIES,
    SEARCH_STUDY_SERIES,
    SEARCH_STUDY_INSTANCES,
    SEARCH_ALL_SERIES,
    SEARCH_STUDY_SERIES_INSTANCES,
    SEARCH_ALL_INSTANCES
};

# Search transaction response attributes.
public final map<dicom:Tag[]> & readonly SEARCH_RESPONSE_ATTRIBUTES = {
    STUDY: [
        {group: 0x0008, element: 0x0020}, // StudyDate
        {group: 0x0008, element: 0x0030}, // StudyTime
        {group: 0x0008, element: 0x0050}, // AccessionNumber
        {group: 0x0008, element: 0x0056}, // InstanceAvailability
        {group: 0x0008, element: 0x0061}, // ModalitiesInStudy
        {group: 0x0008, element: 0x0090}, // Referring​Physician​Name
        {group: 0x0008, element: 0x0201}, // Timezone​Offset​From​UTC
        {group: 0x0008, element: 0x1190}, // RetrieveURL
        {group: 0x0010, element: 0x0010}, // Patient​Name
        {group: 0x0010, element: 0x0020}, // Patient​ID
        {group: 0x0010, element: 0x0030}, // Patient​Birth​Date
        {group: 0x0010, element: 0x0040}, // Patient​Sex
        {group: 0x0020, element: 0x000D}, // Study​Instance​UID
        {group: 0x0020, element: 0x0010}, // Study​ID
        {group: 0x0020, element: 0x1206}, // Number​Of​Study​Related​Series
        {group: 0x0020, element: 0x1208} // Number​Of​Study​Related​Instances
    ],
    SERIES: [
        {group: 0x0008, element: 0x0060}, // Modality
        {group: 0x0008, element: 0x0201}, // Timezone​Offset​From​UTC
        {group: 0x0008, element: 0x103E}, // SeriesDescription
        {group: 0x0008, element: 0x1190}, // RetrieveURL
        {group: 0x0020, element: 0x000E}, // SeriesInstanceUID
        {group: 0x0020, element: 0x0011}, // SeriesNumber
        {group: 0x0020, element: 0x1209}, // Number​Of​Series​Related​Instances
        {group: 0x0040, element: 0x0244}, // Performed​Procedure​Step​Start​Date
        {group: 0x0040, element: 0x0245}, // Performed​Procedure​Step​Start​Time
        {group: 0x0040, element: 0x0275}, // Request​Attributes​Sequence
        {group: 0x0040, element: 0x0009}, // Scheduled​Procedure​Step​ID
        {group: 0x0040, element: 0x1001} // Requested​Procedure​ID
    ],
    INSTANCE: [
        {group: 0x0008, element: 0x0016}, // SOP​Class​UID
        {group: 0x0008, element: 0x0018}, // SOPInstanceUID
        {group: 0x0008, element: 0x0056}, // Instance​Availability
        {group: 0x0008, element: 0x0201}, // Timezone​Offset​From​UTC
        {group: 0x0008, element: 0x1190}, // Retrieve​URL
        {group: 0x0020, element: 0x0013}, // Instance​Number
        {group: 0x0028, element: 0x0010}, // Rows
        {group: 0x0028, element: 0x0011}, // Columns
        {group: 0x0028, element: 0x0100}, // Bits​Allocated
        {group: 0x0028, element: 0x0008} // Number​Of​Frames
    ]
};

# Search transaction IE level attributes.
public final map<dicom:Tag[]> & readonly SEARCH_IE_LEVELS = {
    STUDY: [
        {group: 0x0008, element: 0x0020}, // StudyDate
        {group: 0x0008, element: 0x0030}, // StudyTime
        {group: 0x0008, element: 0x0050}, // AccessionNumber
        {group: 0x0008, element: 0x0061}, // ModalitiesInStudy
        {group: 0x0008, element: 0x0090}, // Referring​Physician​Name
        {group: 0x0010, element: 0x0010}, // Patient​Name
        {group: 0x0010, element: 0x0020}, // Patient​ID
        {group: 0x0020, element: 0x000D}, // Study​Instance​UID
        {group: 0x0020, element: 0x0010} // Study​ID
    ],
    SERIES: [
        {group: 0x0008, element: 0x0060}, // Modality
        {group: 0x0020, element: 0x000E}, // SeriesInstanceUID
        {group: 0x0020, element: 0x0011}, // SeriesNumber
        {group: 0x0040, element: 0x0244}, // Performed​Procedure​Step​Start​Date
        {group: 0x0040, element: 0x0245}, // Performed​Procedure​Step​Start​Time
        {group: 0x0040, element: 0x0275}, // Request​Attributes​Sequence
        {group: 0x0040, element: 0x0009}, // Scheduled​Procedure​Step​ID
        {group: 0x0040, element: 0x1001} // Requested​Procedure​ID
    ],
    INSTANCE: [
        {group: 0x0008, element: 0x0016}, // SOP​Class​UID
        {group: 0x0008, element: 0x0018}, // SOPInstanceUID
        {group: 0x0020, element: 0x0013} // Instance​Number
    ]
};

# BulkDataURI VRs.
public final string[] & readonly BULK_DATA_URI_VRs = [
    dicom:DS,
    dicom:FL,
    dicom:FD,
    dicom:IS,
    dicom:LT,
    dicom:OB,
    dicom:OD,
    dicom:OF,
    dicom:OL,
    dicom:OV,
    dicom:OW,
    dicom:SL,
    dicom:SS,
    dicom:ST,
    dicom:SV,
    dicom:UC,
    dicom:UL,
    dicom:UN,
    dicom:US,
    dicom:UT,
    dicom:UV
];

# InlineBinary VRs.
public final string[] & readonly INLINE_BINARY_VRs = [
    dicom:OB,
    dicom:OD,
    dicom:OF,
    dicom:OL,
    dicom:OV,
    dicom:OW,
    dicom:UN
];
