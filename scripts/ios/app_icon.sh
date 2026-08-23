#!/usr/bin/env bash

DEST_DIR_PATH="`pwd`/../../ios/AppIcon.icon"
SRC_DIR_PATH="`pwd`/../../assets/images/ios_icons"
mkdir -p "$DEST_DIR_PATH"

case $APP_IOS_TYPE in
	"monero.com")
    ICON_DIRECTORY="monerocom-app.icon"
    ;;
	"onekey-xmr")
    ICON_DIRECTORY="monerocom-app.icon"
    ;;
	"onekey-zec"|"pwallet")
    # Dedicated product artwork is tracked separately from flavor plumbing.
    ICON_DIRECTORY="cakewallet-app.icon"
    ;;
	"cakewallet")
    ICON_DIRECTORY="cakewallet-app.icon"
    ;;
esac

rm -rf $DEST_DIR_PATH
cp -r "$SRC_DIR_PATH/$ICON_DIRECTORY" "$DEST_DIR_PATH"
