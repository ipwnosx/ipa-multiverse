#!/bin/bash
BASEDIR=$(dirname "$0")

IPAIN_FOLDER="$BASEDIR"'/in'
IPAOUT_FOLDER="$BASEDIR"'/out'
DYLIBS_FOLDER="$BASEDIR"'/dylibs'

DEVID=$1
DUPLICATE_NUMBER=$2

for FILE in ls "$BASEDIR/"*.mobileprovision; do
    if [ "$FILE" != "ls" ]
    then
        MOBILEPROV=$FILE
        break
    fi
done


if ! [[ "$DUPLICATE_NUMBER" =~ ^[0-9]+$ ]]; then
    DUPLICATE_NUMBER=0
fi

echo -e "\n\033[1mThis program made by Abdullah Alqudiry @xIPAStore\033[00m \n"

rm -rf "/tmp/SuperSign"
rm -rf $IPAOUT_FOLDER

mkdir -p "/tmp/SuperSign"
mkdir -p "$IPAOUT_FOLDER/duplicated"

find -d $IPAIN_FOLDER -type f -name "*.ipa" > "/tmp/SuperSign/ipa_files.txt" 2>/dev/null
while IFS='' read -r currentipa || [[ -n "$currentipa" ]]; do

    filename=$(basename "$currentipa" .ipa)

    echo "loading: '$filename.ipa' file."
    echo "unzipping: '$filename.ipa' file."

    TMP_FOLDER="/tmp/SuperSign/$filename"

    mkdir -p $TMP_FOLDER

    unzip -qo "$currentipa" -d $TMP_FOLDER

    APPLICATION_FOLDER=$(ls "$TMP_FOLDER"/Payload/)

    APPLICATION_BUBDLE_EXECUTABLE=$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/Info.plist")

    chmod +x "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/$APPLICATION_BUBDLE_EXECUTABLE"

    # moving the zip file that contains many dylib files
    find -d "$DYLIBS_FOLDER/$filename" -type f -maxdepth 1 -name "*.zip" > "/tmp/SuperSign/dylibs_zip_files.txt" 2>/dev/null
    while IFS='' read -r ZIP_FILE || [[ -n "$ZIP_FILE" ]]; do
        ZIP_NAME=$(basename "$ZIP_FILE" ".zip")
        echo "moving & unzipping '$ZIP_NAME.zip' file."
        unzip -qo "$ZIP_FILE" -d "$TMP_FOLDER/Payload/$APPLICATION_FOLDER"
    done < "/tmp/SuperSign/dylibs_zip_files.txt"
    # Done

    # moving the zip file that contains many dylib files
    find -d "$DYLIBS_FOLDER" -type f -maxdepth 1 -name "*.zip" > "/tmp/SuperSign/dylibs_zip_files.txt" 2>/dev/null
    while IFS='' read -r ZIP_FILE || [[ -n "$ZIP_FILE" ]]; do
        ZIP_NAME=$(basename "$ZIP_FILE" ".zip")
        echo "moving & unzipping '$ZIP_NAME.zip' file."
        unzip -qo "$ZIP_FILE" -d "$TMP_FOLDER/Payload/$APPLICATION_FOLDER"
    done < "/tmp/SuperSign/dylibs_zip_files.txt"
    # Done

    # Remove __MACOSX folder
    rm -rf "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/__MACOSX"
    # Done

    # Injecting dylib files
    find -d "$TMP_FOLDER/Payload/$APPLICATION_FOLDER" -type f -maxdepth 1 -name "*.dylib" > "/tmp/SuperSign/dylibs_files.txt"
    while IFS='' read -r DYLIB_FILE || [[ -n "$DYLIB_FILE" ]]; do
        DYLIB_NAME=$(basename "$DYLIB_FILE" ".dylib")
        echo "injecting '$DYLIB_NAME.dylib' file."
        "$BASEDIR"/optool install -c load -p "@executable_path/$DYLIB_NAME.dylib" -t "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/$APPLICATION_BUBDLE_EXECUTABLE" >/dev/null
    done < "/tmp/SuperSign/dylibs_files.txt"
    # Done

    # Copy mobileprovision file
    echo "copying mobileprovision file."
    cp "$MOBILEPROV" "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/embedded.mobileprovision"
    # Done

    # Resign ipa file
    echo "resigning '$filename.ipa' file."

    security cms -D -i "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/embedded.mobileprovision" >> "/tmp/SuperSign/mobileprovision_full.plist" 2>/dev/null
    /usr/libexec/PlistBuddy -x -c 'Print:Entitlements' "/tmp/SuperSign/mobileprovision_full.plist" >> "/tmp/SuperSign/mobileprovision.plist"

    find "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/libloader" -type f > "/tmp/SuperSign/libloader.txt" 2>/dev/null
    find -d $TMP_FOLDER \( -name "*.app" -o -name "*.appex" -o -name "*.framework" -o -name "*.dylib"  \) >> "/tmp/SuperSign/libloader.txt"
    while IFS='' read -r line || [[ -n "$line" ]]; do
        /usr/bin/codesign --continue -f -s "$DEVID" --entitlements "/tmp/SuperSign/mobileprovision.plist"  "$line" 2>/dev/null
    done < "/tmp/SuperSign/libloader.txt"
    # Done

    # Zipping folder
    echo "zipping '$APPLICATION_FOLDER' folder."
    cd $TMP_FOLDER
    zip -qry "$IPAOUT_FOLDER/$filename.ipa" *
    # Done

    echo -e "\033[01;32m'$filename.ipa' was created successfully.\033[00m\n"

    if [ $DUPLICATE_NUMBER -gt 0 ]; then
        echo -e "\033[01;31mcreating $DUPLICATE_NUMBER copies of '$filename.ipa'\033[00m";

        APP_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/Info.plist")
        BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/Info.plist")

        mkdir -p "$IPAOUT_FOLDER/duplicated/$filename"
    fi

    for (( dupNUM=1; dupNUM<=DUPLICATE_NUMBER; dupNUM++ )); do
        /usr/libexec/PlistBuddy -c "Add ::UIDeviceFamily:0 integer 1" "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/Info.plist"
        /usr/libexec/PlistBuddy -c "Add ::UIDeviceFamily:1 integer 2" "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/Info.plist"
        /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 8.0" "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/Info.plist"

        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME-$dupNUM" "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/Info.plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID-$dupNUM" "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/Info.plist"

        rm -rf "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/PlugIns"
        rm -rf "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/Watch"

        codesign -fs "$DEVID" --entitlements "/tmp/SuperSign/mobileprovision.plist" --timestamp=none "$TMP_FOLDER/Payload/$APPLICATION_FOLDER" >/dev/null 2>&1

        cd $TMP_FOLDER
        zip -qry "$IPAOUT_FOLDER/duplicated/$filename/$filename-$dupNUM.ipa" *

        echo -e "\033[01;32m'duplicated/$filename/$filename-$dupNUM.ipa' was created successfully.\033[00m"
    done

    rm -rf "/tmp/SuperSign/dylibs_zip_files.txt"
    rm -rf "/tmp/SuperSign/dylibs_files.txt"
    rm -rf "/tmp/SuperSign/libloader.txt"
    rm -rf "/tmp/SuperSign/mobileprovision.plist"
    rm -rf "/tmp/SuperSign/mobileprovision_full.plist"
    echo -e "\n";
done < "/tmp/SuperSign/ipa_files.txt"

rm -rf "/tmp/SuperSign"

echo -e "\033[1mDone .. Thank you for using SuperSign from Abdullah Alqudiry @xIPAStore :)\033[00m\n"
