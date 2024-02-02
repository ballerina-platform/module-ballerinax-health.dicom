import ballerina/lang.regexp;

// DICOM tags maps
public final map<json> & readonly standardTagsMap;
public final map<json> & readonly repeatingTagsMap;
public final map<json> & readonly privateTagsMap;
public final map<int[]> & readonly repeatingTagsMasks;

function init() returns Error? {
    do {
        // Initialize tags maps
        map<json> standardTags = check STANDARD_TAGS_DICT.fromJsonStringWithType();
        standardTagsMap = standardTags.cloneReadOnly();

        map<json> repeatingTags = check REPEATING_TAGS_DICT.fromJsonStringWithType();
        repeatingTagsMap = repeatingTags.cloneReadOnly();

        map<json> privateTags = check PRIVATE_TAGS_DICT.fromJsonStringWithType();
        privateTagsMap = privateTags.cloneReadOnly();

        // Generate repeating tags masks map
        // This map will be used to map a true bitwise mask to the DICOM mask with "x"s in it
        // "x" is used as a wildcard character in repeating groups
        // Section 7.6 in Part 5
        map<int[]> masks = {};
        foreach var tag in repeatingTagsMap.keys() {
            string mask1Str = regexp:replaceAll(re `x`, tag, "0");
            int mask1 = check int:fromHexString(mask1Str);
            string mask2Str = "";
            foreach var item in tag {
                mask2Str += item == "x" ? "0" : "F";
            }
            int mask2 = check int:fromHexString(mask2Str);
            masks[tag] = [mask1, mask2];
        }
        repeatingTagsMasks = masks.cloneReadOnly();
    } on fail error e {
        return error Error("Error initializing core package", e);
    }
}
