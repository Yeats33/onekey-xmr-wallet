#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"
release_tag="v0.18.4.6-RC2"
expected_sha256="94ae3d99f878d1e392b9c49d4c5431e4d0b7780c6177081df5369d05e68cea70"
archive="$(mktemp)"
trap 'rm -f "$archive"' EXIT

curl --fail --location --retry 3 --output "$archive" \
  "https://github.com/MrCyjaneK/monero_c/releases/download/$release_tag/release-bundle.zip"
actual_sha256="$(shasum -a 256 "$archive" | awk '{print $1}')"
if [[ "$actual_sha256" != "$expected_sha256" ]]; then
  echo "monero_c release bundle checksum mismatch" >&2
  exit 1
fi

release_root="$project_root/scripts/monero_c/release"
rm -rf "$release_root/$release_tag"
mkdir -p "$release_root"
unzip -q "$archive" -d "$release_root"

MONERO_C_TAG="$release_tag" "$script_dir/gen_framework.sh"
echo "Restored verified monero_c iOS frameworks for $release_tag."
