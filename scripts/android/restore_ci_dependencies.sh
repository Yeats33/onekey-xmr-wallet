#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"
app_type="${1:-onekey-xmr}"
registry="${CAKE_ANDROID_DEPS_REGISTRY:-ghcr.io/cake-tech/cake_wallet}"

bitbox_image="$registry:android-deps-bitbox-ffa82d-204f93@sha256:64d59905dc849c48c3628fe67a164002ec4b767694c91ff8286b3ed903f77918"
reown_image="$registry:android-deps-reown-104452-b54685@sha256:3470a73c1988f8c35c0aee2870adcd2dc0a1d396fbde41f69fb6b8aecda4bdce"
monero_image="$registry:android-deps-monero-1acea7-7e5d13@sha256:3f9352e2db21c008350df608f9f4ddd712643c52591ea9122c7c5784fb1b7e93"
torch_image="$registry:android-deps-torch-ccee27-0dce3e@sha256:29afd1500399b9b4db14a385523fc94768446ea799c6b878fe6e30ad901e1220"

create_container() {
  local name="$1"
  local image="$2"
  docker pull "$image" >&2
  local container="privacy-wallet-${name}-$$"
  docker create --name "$container" "$image" >/dev/null
  printf '%s' "$container"
}

bitbox_container="$(create_container bitbox "$bitbox_image")"
mkdir -p "$project_root/scripts/bitbox_flutter"
docker cp "$bitbox_container:/w/scripts/bitbox_flutter/." \
  "$project_root/scripts/bitbox_flutter/"
docker rm "$bitbox_container" >/dev/null

reown_container="$(create_container reown "$reown_image")"
mkdir -p "$project_root/scripts/reown_flutter"
docker cp "$reown_container:/w/scripts/reown_flutter/." \
  "$project_root/scripts/reown_flutter/"
docker rm "$reown_container" >/dev/null

torch_container="$(create_container torch "$torch_image")"
mkdir -p "$project_root/scripts/torch_dart"
docker cp "$torch_container:/w/scripts/torch_dart/." \
  "$project_root/scripts/torch_dart/"
docker rm "$torch_container" >/dev/null

if [[ "$app_type" == "onekey-xmr" || "$app_type" == "pwallet" ]]; then
  monero_container="$(create_container monero "$monero_image")"
  for abi in arm64-v8a armeabi-v7a x86_64; do
    destination="$project_root/android/app/src/main/jniLibs/$abi"
    mkdir -p "$destination"
    docker cp \
      "$monero_container:/w/android/app/src/main/jniLibs/$abi/libmonero_wallet2_api_c.so" \
      "$destination/libmonero_wallet2_api_c.so"
  done
  docker rm "$monero_container" >/dev/null
fi

if command -v sudo >/dev/null 2>&1; then
  ownership_paths=(
    "$project_root/scripts/bitbox_flutter"
    "$project_root/scripts/reown_flutter"
    "$project_root/scripts/torch_dart"
  )
  if [[ -d "$project_root/android/app/src/main/jniLibs" ]]; then
    ownership_paths+=("$project_root/android/app/src/main/jniLibs")
  fi
  sudo chown -R "$(id -u):$(id -g)" "${ownership_paths[@]}"
fi

echo "Restored pinned Android native dependencies."
