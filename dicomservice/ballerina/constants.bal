import ballerinax/health.dicom.dicomweb;

# DICOM context message direction.
public enum MessageDirection {
    IN,
    OUT
}

# DICOM request context property name.
public const DICOM_CONTEXT_PROP_NAME = "_OH_DICOM_REQUEST_CONTEXT_";

# Default API config
public final ApiConfig DEFAULT_API_CONFIG = {
    queryParameters: [
        {
            name: dicomweb:INCLUDEFIELD,
            active: true,
            preProcessor: includeFieldQueryParamPreProcessor
        },
        {
            name: dicomweb:LIMIT,
            active: true,
            preProcessor: limitQueryParamPreProcessor,
            postProcessor: limitQueryParamPostProcessor
        },
        {
            name: dicomweb:OFFSET,
            active: true,
            preProcessor: offsetQueryParamPreProcessor,
            postProcessor: offsetQueryParamPostProcessor
        },
        {
            name: dicomweb:FUZZYMATCHING,
            active: false
        }
    ]
};
