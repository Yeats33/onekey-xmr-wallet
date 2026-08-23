#!/usr/bin/env bash

if [ -z "$APP_IOS_TYPE" ]; then
	echo "Please set APP_IOS_TYPE"
	exit 1
fi

DIR=$(dirname "$0")

$DIR/build_torch.sh

case $APP_IOS_TYPE in
	"monero.com") $DIR/restore_monero_prebuilt.sh ;;
	"onekey-xmr") $DIR/restore_monero_prebuilt.sh ;;
	"onekey-zec") $DIR/restore_monero_prebuilt.sh ;;
	"pwallet") $DIR/restore_monero_prebuilt.sh ;;
	"cakewallet") $DIR/restore_monero_prebuilt.sh && $DIR/build_mwebd.sh && $DIR/build_decred.sh ;;
esac
