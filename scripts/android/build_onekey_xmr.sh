#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"
required_files=(
  "$project_root/scripts/bitbox_flutter/android/libs/api.aar"
  "$project_root/scripts/reown_flutter/scripts/yttrium/crates/kotlin-ffi/android/src/main/kotlin/com/reown/yttrium/uniffi_yttrium.kt"
  "$project_root/android/app/src/main/jniLibs/arm64-v8a/libmonero_wallet2_api_c.so"
  "$project_root/android/app/src/main/jniLibs/armeabi-v7a/libmonero_wallet2_api_c.so"
  "$project_root/android/app/src/main/jniLibs/x86_64/libmonero_wallet2_api_c.so"
)

for required_file in "${required_files[@]}"; do
  if [[ ! -e "$required_file" ]]; then
    echo "Missing native dependency: $required_file" >&2
    echo "Build/extract Cake's Android native dependencies before packaging." >&2
    exit 1
  fi
done

pushd "$script_dir" >/dev/null
source ./app_env.sh onekey-xmr
version="$APP_ANDROID_VERSION"
output_dir="$project_root/dist/android/v$version"
./app_config.sh
popd >/dev/null

pushd "$project_root" >/dev/null
flutter pub get

for package_dir in cw_core cw_monero; do
  pushd "$package_dir" >/dev/null
  flutter pub get
  dart run build_runner build
  popd >/dev/null
done

dart run build_runner build
dart run tool/generate_localization.dart
dart run tool/generate_new_secrets.dart
./compile_graphics.sh

if [[ ! -f android/app/key.jks || ! -f android/key.properties ]]; then
  echo "Missing Android signing key or android/key.properties." >&2
  echo "Create and protect a release key before running this script." >&2
  exit 1
fi

flutter build apk --release --split-per-abi

mkdir -p "$output_dir"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  "$output_dir/xmr-wallet-$version-arm64-v8a.apk"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
  "$output_dir/xmr-wallet-$version-armeabi-v7a.apk"
cp build/app/outputs/flutter-apk/app-x86_64-release.apk \
  "$output_dir/xmr-wallet-$version-x86_64.apk"
pushd "$output_dir" >/dev/null
sha256sum ./*.apk | tee SHA256SUMS
popd >/dev/null
popd >/dev/null
