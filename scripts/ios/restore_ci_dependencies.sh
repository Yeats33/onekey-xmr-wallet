#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"
download_dir="$(mktemp -d)"
trap 'rm -rf "$download_dir"' EXIT

restore_archive() {
  local url="$1"
  local destination="$2"
  local archive="$download_dir/$(basename "$url")"

  curl --fail --location --retry 3 --output "$archive" "$url"
  rm -rf "$destination"
  mkdir -p "$destination"
  tar -xzf "$archive" -C "$destination"
}

restore_archive \
  "https://github.com/MrCyjaneK/torch_dart/releases/download/v1.0.17/torch_dart-v1.0.17.tar.gz" \
  "$project_root/scripts/torch_dart"
restore_archive \
  "https://github.com/cake-tech/reown_flutter/releases/download/v0.0.4/reown_flutter-v0.0.4.tar.gz" \
  "$project_root/scripts/reown_flutter"

bitbox_dir="$project_root/scripts/bitbox_flutter"
rm -rf "$bitbox_dir"
git clone --filter=blob:none --no-checkout \
  https://github.com/konstantinullrich/bitbox_flutter "$bitbox_dir"
git -C "$bitbox_dir" checkout 5a6e6dd388ef64003f86094af80d5453518b601d

test -f "$project_root/scripts/torch_dart/pubspec.yaml"
test -f "$project_root/scripts/reown_flutter/packages/reown_walletkit/pubspec.yaml"
test -f "$project_root/scripts/bitbox_flutter/pubspec.yaml"

echo "Restored pinned iOS source dependencies."
