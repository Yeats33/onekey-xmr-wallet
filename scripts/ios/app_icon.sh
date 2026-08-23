#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"
icon_composer_dir="$project_root/ios/AppIcon.icon"
source_dir="$project_root/assets/images/ios_icons"
legacy_appicon_dir="$project_root/ios/Runner/Assets.xcassets/AppIcon.appiconset"

case $APP_IOS_TYPE in
	"monero.com")
    ICON_DIRECTORY="monerocom-app.icon"
    LEGACY_SOURCE="monero.com_icon_1024.png"
    ;;
	"onekey-xmr")
    ICON_DIRECTORY="monerocom-app.icon"
    LEGACY_SOURCE="monero.com_icon_1024.png"
    ;;
	"onekey-zec"|"pwallet")
    # Dedicated product artwork is tracked separately from flavor plumbing.
    ICON_DIRECTORY="cakewallet-app.icon"
    LEGACY_SOURCE="cakewallet_icon_1024.png"
    ;;
	"cakewallet")
    ICON_DIRECTORY="cakewallet-app.icon"
    LEGACY_SOURCE="cakewallet_icon_1024.png"
    ;;
  *)
    echo "Unsupported APP_IOS_TYPE: $APP_IOS_TYPE" >&2
    exit 64
    ;;
esac

rm -rf "$icon_composer_dir"
cp -R "$source_dir/$ICON_DIRECTORY" "$icon_composer_dir"

# Xcode 26 consumes AppIcon.icon, while the macOS 15 CI image still uses an
# Xcode version that requires a classic AppIcon.appiconset. Generate both from
# the same source artwork so local and CI builds have identical branding.
legacy_source="$project_root/assets/images/$LEGACY_SOURCE"
rm -rf "$legacy_appicon_dir"
mkdir -p "$legacy_appicon_dir"
for pixels in 20 29 40 58 60 76 80 87 120 152 167 180; do
  sips -z "$pixels" "$pixels" "$legacy_source" \
    --out "$legacy_appicon_dir/AppIcon-${pixels}.png" >/dev/null
done
cp "$legacy_source" "$legacy_appicon_dir/AppIcon-1024.png"

cat > "$legacy_appicon_dir/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "AppIcon-40.png", "idiom" : "iphone", "scale" : "2x", "size" : "20x20" },
    { "filename" : "AppIcon-60.png", "idiom" : "iphone", "scale" : "3x", "size" : "20x20" },
    { "filename" : "AppIcon-58.png", "idiom" : "iphone", "scale" : "2x", "size" : "29x29" },
    { "filename" : "AppIcon-87.png", "idiom" : "iphone", "scale" : "3x", "size" : "29x29" },
    { "filename" : "AppIcon-80.png", "idiom" : "iphone", "scale" : "2x", "size" : "40x40" },
    { "filename" : "AppIcon-120.png", "idiom" : "iphone", "scale" : "3x", "size" : "40x40" },
    { "filename" : "AppIcon-120.png", "idiom" : "iphone", "scale" : "2x", "size" : "60x60" },
    { "filename" : "AppIcon-180.png", "idiom" : "iphone", "scale" : "3x", "size" : "60x60" },
    { "filename" : "AppIcon-20.png", "idiom" : "ipad", "scale" : "1x", "size" : "20x20" },
    { "filename" : "AppIcon-40.png", "idiom" : "ipad", "scale" : "2x", "size" : "20x20" },
    { "filename" : "AppIcon-29.png", "idiom" : "ipad", "scale" : "1x", "size" : "29x29" },
    { "filename" : "AppIcon-58.png", "idiom" : "ipad", "scale" : "2x", "size" : "29x29" },
    { "filename" : "AppIcon-40.png", "idiom" : "ipad", "scale" : "1x", "size" : "40x40" },
    { "filename" : "AppIcon-80.png", "idiom" : "ipad", "scale" : "2x", "size" : "40x40" },
    { "filename" : "AppIcon-76.png", "idiom" : "ipad", "scale" : "1x", "size" : "76x76" },
    { "filename" : "AppIcon-152.png", "idiom" : "ipad", "scale" : "2x", "size" : "76x76" },
    { "filename" : "AppIcon-167.png", "idiom" : "ipad", "scale" : "2x", "size" : "83.5x83.5" },
    { "filename" : "AppIcon-1024.png", "idiom" : "ios-marketing", "scale" : "1x", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
