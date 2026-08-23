#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
expected_version="${1:-1.3.0}"
products=(onekey-xmr onekey-zec pwallet)

android_metadata() {
  local product="$1"
  (
    cd "$project_root/scripts/android"
    source ./app_env.sh "$product"
    printf '%s\t%s\t%s\t%s\t%s\n' \
      "$APP_ANDROID_VERSION" \
      "$APP_ANDROID_BUILD_NUMBER" \
      "$APP_ANDROID_PACKAGE" \
      "$APP_ANDROID_ARTIFACT" \
      "$APP_ANDROID_TAG_PREFIX"
  )
}

ios_metadata() {
  local product="$1"
  (
    cd "$project_root/scripts/ios"
    source ./app_env.sh "$product"
    printf '%s\t%s\t%s\t%s\t%s\n' \
      "$APP_IOS_VERSION" \
      "$APP_IOS_BUILD_NUMBER" \
      "$APP_IOS_BUNDLE_ID" \
      "$APP_IOS_ARTIFACT" \
      "$APP_IOS_TAG_PREFIX"
  )
}

for product in "${products[@]}"; do
  case "$product" in
    onekey-xmr)
      expected_build=5
      expected_package="com.yeats33.xmrwallet"
      expected_artifact="xmr-wallet"
      expected_prefix="xmr-v"
      ;;
    onekey-zec)
      expected_build=2
      expected_package="com.yeats33.zecwallet"
      expected_artifact="zec-wallet"
      expected_prefix="zec-v"
      ;;
    pwallet)
      expected_build=2
      expected_package="com.yeats33.pwallet"
      expected_artifact="pwallet"
      expected_prefix="pwallet-v"
      ;;
  esac

  IFS=$'\t' read -r android_version android_build android_package \
    android_artifact android_prefix < <(android_metadata "$product")
  IFS=$'\t' read -r ios_version ios_build ios_package ios_artifact ios_prefix \
    < <(ios_metadata "$product")

  [[ "$android_version" == "$expected_version" ]]
  [[ "$ios_version" == "$expected_version" ]]
  [[ "$android_build" == "$expected_build" ]]
  [[ "$ios_build" == "$expected_build" ]]
  [[ "$android_package" == "$expected_package" ]]
  [[ "$ios_package" == "$expected_package" ]]
  [[ "$android_artifact" == "$expected_artifact" ]]
  [[ "$ios_artifact" == "$expected_artifact" ]]
  [[ "$android_prefix" == "$expected_prefix" ]]
  [[ "$ios_prefix" == "$expected_prefix" ]]

  release_tag="${expected_prefix}${expected_version}"
  test -s "$project_root/docs/releases/${release_tag}.md"
  echo "Validated $product $expected_version+$expected_build ($release_tag)."
done

grep -Fq "## [$expected_version]" "$project_root/CHANGELOG.md"
grep -Eq "\| XMR Wallet .*\| \`$expected_version\` \|" "$project_root/README.md"
grep -Eq "\| ZEC Wallet .*\| \`$expected_version\` \|" "$project_root/README.md"
grep -Eq "\| PWallet .*\| \`$expected_version\` \|" "$project_root/README.md"

echo "Release metadata is consistent for version $expected_version."
