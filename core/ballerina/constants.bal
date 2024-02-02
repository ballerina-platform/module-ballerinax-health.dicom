# Represents DICOM VRs.
public enum Vr {
    AE,
    AS,
    AT,
    CS,
    DA,
    DS,
    DT,
    FD,
    FL,
    IS,
    LO,
    LT,
    OB,
    OD,
    OF,
    OL,
    OW,
    OV,
    PN,
    SH,
    SL,
    SQ,
    SS,
    ST,
    SV,
    TM,
    UC,
    UI,
    UL,
    UN,
    UR,
    US,
    UT,
    UV,
    # Ambiguous/other VRs from Tables 6-1, 7-1 and 8-1 in Part 6.
    US_SS_OW = "US or SS or OW",
    US_SS = "US or SS",
    US_OW = "US or OW",
    OB_OW = "OB or OW"
}

# Standard VRs.
public final string[] & readonly STANDARD_VRs = [
    AE,
    AS,
    AT,
    CS,
    DA,
    DS,
    DT,
    FD,
    FL,
    IS,
    LO,
    LT,
    OB,
    OD,
    OF,
    OL,
    OW,
    OV,
    PN,
    SH,
    SL,
    SQ,
    SS,
    ST,
    SV,
    TM,
    UC,
    UI,
    UL,
    UN,
    UR,
    US,
    UT,
    UV
];

# Ambiguous/other VRs.
public final string[] & readonly OTHER_VRs = [US_SS_OW, US_SS, US_OW, OB_OW];

// Explicit length VRs from Table 7.1.2 in Part 5
# Explicit length 32-bt VRs.
public final string[] & readonly EXPLICIT_LENGTH_32_VRs = [
    OB,
    OD,
    OF,
    OL,
    OW,
    OV,
    SQ,
    SV,
    UC,
    UN,
    UR,
    UT,
    UV
];

# Explicit length 16-bit VRs.
public final string[] & readonly EXPLICIT_LENGTH_16_VRs = [
    AE,
    AS,
    AT,
    CS,
    DA,
    DS,
    DT,
    FL,
    FD,
    IS,
    LO,
    LT,
    PN,
    SH,
    SL,
    SS,
    ST,
    TM,
    UI,
    UL,
    US
];

// Character Repertoires for VRs 
// Based off of Section 6.1.2 and Table 6.2-1 in Part 5
# Default character repertoire VRs.
public final string[] & readonly DEFAULT_CHARSET_VRs = [AE, AS, CS, DA, DS, DT, IS, TM, UI, UR];

# Default character repertoire extended/replaced VRs.
# Extended or replaced by the character set defined by Specific Character Set (0008,0005) attribute.
public final string[] & readonly CUSTOMIZABLE_CHARSET_VRs = [LO, LT, PN, SH, ST, UC, UT];

// Ballerina built-in types for VRs
# String VRs 
public final string[] & readonly STR_VRs = [...DEFAULT_CHARSET_VRs, ...CUSTOMIZABLE_CHARSET_VRs];

# Bytes VRs.
public final string[] & readonly BYTES_VRs = [OB, OD, OF, OL, OV, OW, UN];

# Float VRs.
public final string[] & readonly FLOAT_VRs = [DS, FD, FL];

# Integer VRs.
public final string[] & readonly INT_VRs = [AT, IS, SL, SS, SV, UL, US, UV];

# List VRs.
public final string[] & readonly LIST_VRs = [SQ];

# VRs that may contain backslash character in the value.
# Bytes VRs and Other VRs (that uses byte values) may also contain the backslash character.
public final string[] & readonly ALLOW_BACKLASH_VRs = [
    LT,
    ST,
    UT,
    ...BYTES_VRs,
    US_SS_OW,
    US_OW,
    OB_OW
];

# VRs that may contain leading and/or trailing spaces that can be ignored.
public final string[] & readonly SPACE_INSIGNIFICANT_VRs = [AE, CS, PN, UR];

# VRs with fixed value lengths.
public final map<int> & readonly FIXED_LENGTH_VALUE_BYTES = {
    AS: 4,
    AT: 4,
    DA: 8,
    FL: 4,
    FD: 8,
    SL: 4,
    SS: 2,
    SV: 8,
    UL: 4,
    US: 2,
    UV: 8
};

# VRs with variable (up to maximum) value lengths.
public final map<int> & readonly VARIABLE_LENGTH_VALUE_BYTES = {
    AE: 16,
    CS: 16,
    DS: 16,
    DT: 26,
    IS: 12,
    LO: 64, // Chars
    LT: 10240, // Chars
    OD: 4294967288, // 2^32-8
    OF: 4294967292, // 2^32-4
    PN: 64, // Chars
    SH: 16, // Chars
    ST: 1024, // Chars
    TM: 14,
    UC: 4294967294, // 2^32-2
    UI: 64,
    UR: 4294967294, // 2^32-2
    UT: 4294967294 // 2^32-2
};

# Pixel data tags.
public final Tag[] & readonly PIXEL_DATA_TAGS = [
    {group: 0x7fe0, element: 0x0010},
    {group: 0x7fe0, element: 0x0009},
    {group: 0x7fe0, element: 0x0008}
];

// Sequence (SQ) related tags
# Constant for sequence item tag.
public const ITEM_TAG = {group: 0xFFFE, element: 0xE000};

# Constant for item delimiter tag.
public const ITEM_DELIMITER_TAG = {group: 0xFFFE, element: 0xE00D};

# Constant for sequence delimiter item.
public const SEQUENCE_DELIMITER_TAG = {group: 0xFFFE, element: 0xE0DD};

# Represents numeric byte orders.
public enum ByteOrder {
    LITTLE_ENDIAN,
    BIG_ENDIAN
}

# Represents DICOM transfer syntaxes.
public enum TransferSyntax {
    IMPLICIT_VR_LITTLE_ENDIAN,
    EXPLICIT_VR_LITTLE_ENDIAN,
    EXPLICIT_VR_BIG_ENDIAN
}

# Constant for undefined value length bytes.
public const UNDEFINED_VL_BYTES = [0xFF, 0xFF, 0xFF, 0xFF];

# Constant for space byte.
public const SPACE_BYTE = 0x20;

final map<string> & readonly VALUE_CHARSET_VALIDATORS = {
    AE: string `^[^\p{Cc}\\]*$`, // Cc - Control category (ASCII [\x00-\x1F] or Latin-1 [\x80-\x9F] control character)
    AS: string `^[0-9DWMY]*$`,
    CS: string `^[A-Z0-9 _\\"]*$`,
    DA: string `^[\\"0-9]*$`,
    DS: string `^[0-9+\-Ee. ]*$`
};

final map<ValueFormatValidator> & readonly VALUE_FORMAT_VALIDATORS = {
    AS: string `^\d{3}(D|W|M|Y)$`,
    DA: string `^\d{4}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])$`,
    DS: string `^\s*[\+\-]?\d+(\.\d+)?([Ee][\+\-]?\d+)?\s*$`
};

final map<string> & readonly VALUE_VALID_FORMATS = {
    AS: "nnnD, nnnW, nnnM, nnnY",
    DA: "YYYYMMDD"
};
