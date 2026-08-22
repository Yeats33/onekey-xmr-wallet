#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pushd "$project_root/scripts/android" >/dev/null
source ./app_env.sh onekey-xmr
./app_config.sh
popd >/dev/null

pushd "$project_root" >/dev/null
flutter pub get
dart run tool/generate_localization.dart
dart run tool/generate_new_secrets.dart
./compile_graphics.sh
popd >/dev/null

echo "Configured XMR Wallet for Android (${APP_ANDROID_PACKAGE})."
