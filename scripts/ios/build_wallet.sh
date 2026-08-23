#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <onekey-xmr|onekey-zec|pwallet>" >&2
  exit 64
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "IPA builds require macOS and Xcode." >&2
  exit 69
fi

app_type="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"

"$project_root/configure_wallet_ios.sh" "$app_type"

pushd "$script_dir" >/dev/null
source ./app_env.sh "$app_type"
popd >/dev/null

APP_IOS_TYPE="$app_type" "$script_dir/build_all.sh"

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

pushd "$project_root" >/dev/null
for package_dir in "${package_dirs[@]}"; do
  pushd "$package_dir" >/dev/null
  flutter pub get
  dart run build_runner build
  popd >/dev/null
done
dart run build_runner build

build_args=(
  ipa
  --release
  --dart-define="PRODUCT_FLAVOR=$app_type"
)
if [[ "${IOS_NO_CODESIGN:-0}" == "1" ]]; then
  build_args+=(--no-codesign)
fi
flutter build "${build_args[@]}"

output_dir="$project_root/dist/ios/$APP_IOS_ARTIFACT/v$APP_IOS_VERSION"
mkdir -p "$output_dir"
if compgen -G "build/ios/ipa/*.ipa" >/dev/null; then
  cp build/ios/ipa/*.ipa "$output_dir/$APP_IOS_ARTIFACT-$APP_IOS_VERSION.ipa"
elif [[ "${IOS_NO_CODESIGN:-0}" == "1" ]]; then
  app_bundle="build/ios/iphoneos/Runner.app"
  test -d "$app_bundle"
  ipa_stage="$(mktemp -d)"
  trap 'rm -rf "$ipa_stage"' EXIT
  mkdir -p "$ipa_stage/Payload"
  ditto "$app_bundle" "$ipa_stage/Payload/Runner.app"
  (
    cd "$ipa_stage"
    ditto -c -k --sequesterRsrc --keepParent Payload \
      "$output_dir/$APP_IOS_ARTIFACT-$APP_IOS_VERSION-unsigned.ipa"
  )
else
  echo "Xcode archive did not export an IPA." >&2
  exit 1
fi
pushd "$output_dir" >/dev/null
shasum -a 256 ./*.ipa | tee SHA256SUMS
popd >/dev/null
popd >/dev/null
