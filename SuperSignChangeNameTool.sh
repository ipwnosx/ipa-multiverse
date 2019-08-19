#!/bin/bash
BASEDIR=$(dirname "$0")

APP_PATH=$1
APP_NAME=$2
IPAIN_FOLDER="$BASEDIR"'/in'
TMP_FOLDER="/tmp/SuperSignChangeNameTool"

echo -e "\n\033[1mThis program made by Abdullah Alqudiry @xIPAStore\033[00m \n"


echo "loading: '$APP_PATH' file."

mkdir -p $TMP_FOLDER

unzip -qo "$1" -d $TMP_FOLDER

APPLICATION_FOLDER=$(ls "$TMP_FOLDER"/Payload/)

echo "renaming app"

/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $2" "$TMP_FOLDER/Payload/$APPLICATION_FOLDER/Info.plist"

cd $TMP_FOLDER
zip -qry "$TMP_FOLDER/$2.ipa" *

rm -rf "$BASEDIR/in/$2.ipa"

cp "$TMP_FOLDER/$2.ipa" "$BASEDIR/in"

rm -rf $TMP_FOLDER


echo -e "\033[01;32m'$BASEDIR/in/$2.ipa' was created successfully.\033[00m\n"

echo -e "\033[1mDone .. Thank you for using SuperSignChangeNameTool from Abdullah Alqudiry @xIPAStore :)\033[00m\n"
