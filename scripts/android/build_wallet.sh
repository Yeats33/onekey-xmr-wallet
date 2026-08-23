#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <onekey-xmr|onekey-zec|pwallet>" >&2
  exit 64
fi

app_type="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"

pushd "$script_dir" >/dev/null
source ./app_env.sh "$app_type"
./app_config.sh
popd >/dev/null

required_files=(
  "$project_root/scripts/bitbox_flutter/android/libs/api.aar"
  "$project_root/scripts/reown_flutter/scripts/yttrium/crates/kotlin-ffi/android/src/main/kotlin/com/reown/yttrium/uniffi_yttrium.kt"
)

package_dirs=(cw_core)
case "$app_type" in
  onekey-xmr)
    package_dirs+=(cw_monero)
    ;;
  onekey-zec)
    package_dirs+=(cw_zcash)
    ;;
  pwallet)
    package_dirs+=(cw_monero cw_zcash)
    ;;
esac

if [[ "$app_type" == "onekey-xmr" || "$app_type" == "pwallet" ]]; then
  for abi in arm64-v8a armeabi-v7a x86_64; do
    required_files+=("$project_root/android/app/src/main/jniLibs/$abi/libmonero_wallet2_api_c.so")
  done
fi

for required_file in "${required_files[@]}"; do
  if [[ ! -e "$required_file" ]]; then
    echo "Missing native dependency: $required_file" >&2
    echo "Restore or build Cake's Android native dependencies before packaging." >&2
    exit 1
  fi
done

version="$APP_ANDROID_VERSION"
output_dir="$project_root/dist/android/$APP_ANDROID_ARTIFACT/v$version"

pushd "$project_root" >/dev/null
flutter pub get

for package_dir in "${package_dirs[@]}"; do
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

flutter build apk \
  --release \
  --split-per-abi \
  --dart-define="PRODUCT_FLAVOR=$app_type"

mkdir -p "$output_dir"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  "$output_dir/$APP_ANDROID_ARTIFACT-$version-arm64-v8a.apk"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
  "$output_dir/$APP_ANDROID_ARTIFACT-$version-armeabi-v7a.apk"
cp build/app/outputs/flutter-apk/app-x86_64-release.apk \
  "$output_dir/$APP_ANDROID_ARTIFACT-$version-x86_64.apk"
pushd "$output_dir" >/dev/null
sha256sum ./*.apk | tee SHA256SUMS
popd >/dev/null
popd >/dev/null
