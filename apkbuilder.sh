#!/bin/bash

# Load configuration file

CONFIG_FILE=`dirname "$0"`"/apkbuilder.cfg"
INSTALL_REQUIRED=false
APK_SMALI_DIR_PATH=`pwd`

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Unable to find the configuration file, please check the file exists."
    exit -1
fi

source "$CONFIG_FILE"

# Check given parameters

for param in $@; do
    if [[ $param == "--install" || $param == "-i" ]]; then
        INSTALL_REQUIRED=true
    elif [[ $param == "-"* ]]; then
        echo "Invalid param, only --install or -i can be used with this script."
        exit -2
    elif [[ -d $param ]]; then
        APK_SMALI_DIR_PATH="$param"
    elif [[ -f $param ]]; then
        echo $param" is a file, you have to specify a folder."
        exit -2
    else
        echo "The given folder does not exists."
        exit -2
    fi
done

# Build the APK
echo "Building APK..."
cd "$APK_SMALI_DIR_PATH"
build_result=$(yes | "$APKTOOL_PATH" b 2>/tmp/Error)
build_error=$(</tmp/Error)

if [[ "$build_error" != "" && "$build_error" == *"error"* ]]; then
    echo "An error occured while building apk. Please check logs."
    echo "$build_error" > apktool_build.log
    exit -3
fi

# Apk signature
echo "Sign apk..."
cd "dist"
APK_NAME=`ls *.apk | tail -1`
jarsigner_result=$(yes "$PASSPHRASE" | "$JARSIGNER_PATH" -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore "$CERTIFICATE_PATH" "$APK_NAME" alias_name 3>/tmp/SignError)
jarsigner_error=$(</tmp/SignError)

# TODO : check other conditions... 2> seems to be input and not error descriptor
if [[ "$jarsigner_error" != "" ]]; then
    echo "An error occured while signing apk. Please check logs."
    echo "$jarsigner_error" > jarsigner.log
    exit -4
fi

# Verify apk
echo "Verify signature..."
jarsigner_verify_result=$("$JARSIGNER_PATH" -verify -verbose -certs "$APK_NAME" 2>/tmp/VerifyError)
jarsigner_verify_error=$(</tmp/VerifyError)

if [[ "$jarsigner_verify_error" != "" ]]; then
    echo "Signature verification results with errors. Please check logs."
    echo "$jarsigner_verify_error" > jarsigner_verify.log
    exit -5
fi

# Align apk
echo "Align apk..."
zipalign_result=$("$ZIPALIGN_PATH" -v 4 "$APK_NAME" "$APK_NAME"-aligned.apk 2> /tmp/AlignError)
zipalign_error=$(</tmp/AlignError)

if [[ "$zipalign_error" != "" ]]; then
    echo "An error occured while aligning the apk file. Please check logs."
    echo "$zipalign_error" > zipalign.log
    exit -6
fi

# Install apk
if [[ $INSTALL_REQUIRED == true ]]; then
    echo "Installing apk..."
    adb_result=$("$ADB_PATH" install "$APK_NAME"-aligned.apk 2>/tmp/InstallError)
    adb_error=$(</tmp/InstallError)

    if [[ "$adb_error" != "" ]]; then
        echo "An error occures while installing the apk. Please check logs."
        echo "$adb_error" > adb.log
        exit -7
    fi
fi



