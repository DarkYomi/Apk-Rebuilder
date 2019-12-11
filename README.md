# Apk ReBuilder

A little script used to rebuild a modified apk.

## Prerequisite

To use this script, you need the following software installed and/or available on your computer:
*  Apktool : used to decompile and compile apk
*  Zipalign : used to align built and signed apk
*  Jarsigner : used to sign the apk with a certificate (mandatory to install the built apk on a real device)
*  Adb : used to install the apk on a connected device

## Usage

1.  Open apkbuild.cfg and set values to executable path
2.  Use the following line to execute the script :
`./apkbuilder.sh [--install] [smali_dir_path]`

**--install** have to be specified if you want the script to install the built apk to your device.
**smali_dir_path** stand for the path of your decompiled apk. If you're already in the directory, you don't have to specify this element.