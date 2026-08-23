#!/bin/bash
set -x -e
cd "$(dirname "$0")"

../prepare_torch.sh

cd ../torch_dart

SKIP_XC=yes ./build.sh aarch64-apple-ios-simulator aarch64-apple-ios

"$(dirname "$0")/gen_torch_ios_framework.sh"
