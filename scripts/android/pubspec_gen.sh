#!/bin/bash

MONERO_COM=monero.com
CAKEWALLET=cakewallet
ONEKEY_XMR=onekey-xmr
ONEKEY_ZEC=onekey-zec
PWALLET=pwallet
HAVEN=haven
CONFIG_ARGS=""

case $APP_ANDROID_TYPE in
        $MONERO_COM)
                CONFIG_ARGS="--monero"
                ;;
        $ONEKEY_XMR)
                CONFIG_ARGS="--monero"
                ;;
        $ONEKEY_ZEC)
                CONFIG_ARGS="--zcash"
                ;;
        $PWALLET)
                CONFIG_ARGS="--monero --zcash"
                ;;
        $CAKEWALLET)
                CONFIG_ARGS="--monero --bitcoin --ethereum --polygon --nano --bitcoinCash --solana --tron --wownero --zano --decred --dogecoin --base --zcash --arbitrum --bsc"
                ;;
esac

cd ../..
cp -rf pubspec_description.yaml pubspec.yaml
flutter pub get
dart run tool/generate_pubspec.dart
flutter pub get
dart run tool/configure.dart $CONFIG_ARGS
cd scripts/android
