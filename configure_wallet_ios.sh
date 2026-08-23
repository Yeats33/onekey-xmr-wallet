#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <onekey-xmr|onekey-zec|pwallet>" >&2
  exit 64
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS configuration requires macOS and Xcode." >&2
  exit 69
fi

app_type="$1"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pushd "$project_root/scripts/ios" >/dev/null
source ./app_env.sh "$app_type"
./app_config.sh
popd >/dev/null

pushd "$project_root" >/dev/null
flutter pub get
dart run tool/generate_localization.dart
dart run tool/generate_new_secrets.dart
./compile_graphics.sh
popd >/dev/null

echo "Configured $APP_IOS_NAME for iOS ($APP_IOS_BUNDLE_ID)."
