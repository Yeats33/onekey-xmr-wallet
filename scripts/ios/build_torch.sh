#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
torch_dir="$(cd "$script_dir/../torch_dart" && pwd)"
framework="$torch_dir/ios/LibTorch.xcframework"
device_binary="$framework/ios-arm64/LibTorch.framework/LibTorch"
simulator_binary="$framework/ios-arm64-simulator/LibTorch.framework/LibTorch"

# The pinned torch_dart v1.0.17 release already contains the two iOS slices.
# Rebuilding simplybs/LLVM here takes several hours and makes every product
# repeat identical work, so validate and reuse the release XCFramework.
if [[ -s "$device_binary" && -s "$simulator_binary" ]]; then
  plutil -lint "$framework/Info.plist" >/dev/null
  grep -q '<string>ios-arm64</string>' "$framework/Info.plist"
  grep -q '<string>ios-arm64-simulator</string>' "$framework/Info.plist"
  [[ "$(xcrun lipo -archs "$device_binary")" == "arm64" ]]
  [[ "$(xcrun lipo -archs "$simulator_binary")" == "arm64" ]]
  echo "Using verified prebuilt iOS LibTorch XCFramework."
  exit 0
fi

cd "$script_dir"

../prepare_torch.sh

cd ../torch_dart

SKIP_XC=yes ./build.sh aarch64-apple-ios-simulator aarch64-apple-ios

"$(dirname "$0")/gen_torch_ios_framework.sh"
