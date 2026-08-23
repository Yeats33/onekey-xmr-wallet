#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
torch_dir="$(cd "$script_dir/../torch_dart" && pwd)"
tmp_dir="$torch_dir/tmp_torch_ios_framework"
output="$torch_dir/ios/LibTorch.xcframework"

rm -rf "$tmp_dir" "$output"
mkdir -p "$tmp_dir" "$torch_dir/ios"

write_plist() {
  local destination="$1"
  local platform="$2"
  local minimum_os="$3"
  mkdir -p "$destination"
  printf '%s\n' \
    '<?xml version="1.0" encoding="UTF-8"?>' \
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
    '<plist version="1.0"><dict>' \
    '<key>CFBundleExecutable</key><string>LibTorch</string>' \
    '<key>CFBundleIdentifier</key><string>com.yeats33.privacywallet.LibTorch</string>' \
    '<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>' \
    '<key>CFBundleName</key><string>LibTorch</string>' \
    '<key>CFBundlePackageType</key><string>FMWK</string>' \
    '<key>CFBundleShortVersionString</key><string>1.0</string>' \
    '<key>CFBundleVersion</key><string>1</string>' \
    "<key>CFBundleSupportedPlatforms</key><array><string>$platform</string></array>" \
    "<key>MinimumOSVersion</key><string>$minimum_os</string>" \
    '<key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>' \
    '</dict></plist>' > "$destination/Info.plist"
}

create_framework() {
  local target="$1"
  local platform="$2"
  local out_dir="$3"
  local framework="$out_dir/LibTorch.framework"

  pushd "$torch_dir/simplybs" >/dev/null
  go run . -host "$target" -extract -package torch,native/_
  popd >/dev/null

  mkdir -p "$framework/Headers"
  cp "$torch_dir/simplybs/.buildlib/env/lib/libtorch.dylib" "$framework/LibTorch"
  install_name_tool -id '@rpath/LibTorch.framework/LibTorch' "$framework/LibTorch"
  write_plist "$framework" "$platform" "13.0"
}

device_dir="$tmp_dir/device"
simulator_dir="$tmp_dir/simulator"
create_framework aarch64-apple-ios iPhoneOS "$device_dir"
create_framework aarch64-apple-ios-simulator iPhoneSimulator "$simulator_dir"

xcodebuild -create-xcframework \
  -framework "$device_dir/LibTorch.framework" \
  -framework "$simulator_dir/LibTorch.framework" \
  -output "$output"

echo "Created iOS-only LibTorch XCFramework."
