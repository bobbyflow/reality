#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Reality"
BUNDLE_ID="com.bobbyflow.reality"
VERSION="${REALITY_VERSION:-0.1.0}"
BUILD_NUMBER="${REALITY_BUILD_NUMBER:-1}"
IDENTITY="${REALITY_CODESIGN_IDENTITY:--}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/dist/release"
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
ZIP_PATH="$OUTPUT_DIR/$APP_NAME-$VERSION.zip"

[[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || { echo "invalid REALITY_VERSION" >&2; exit 2; }
[[ "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]] || { echo "invalid REALITY_BUILD_NUMBER" >&2; exit 2; }

cd "$ROOT_DIR"
swift build -c release --product "$APP_NAME"
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE" "$ZIP_PATH"
mkdir -p "$APP_MACOS" "$APP_CONTENTS/Resources"
install -m 755 "$BUILD_BINARY" "$APP_MACOS/$APP_NAME"
for resource_bundle in "$(dirname "$BUILD_BINARY")"/*.bundle; do
  [[ -e "$resource_bundle" ]] || continue
  cp -R "$resource_bundle" "$APP_CONTENTS/Resources/"
done

cat >"$APP_CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$BUILD_NUMBER</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

plutil -lint "$APP_CONTENTS/Info.plist" >/dev/null
test -f "$APP_CONTENTS/Resources/GRDB_GRDB.bundle/PrivacyInfo.xcprivacy"
SIGN_ARGS=(--force --sign "$IDENTITY" --options runtime --entitlements "$ROOT_DIR/Config/Reality.entitlements")
if [[ "$IDENTITY" == "-" ]]; then
  SIGN_ARGS+=(--timestamp=none)
else
  SIGN_ARGS+=(--timestamp)
fi
codesign "${SIGN_ARGS[@]}" "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" | tee "$ZIP_PATH.sha256"
echo "packaged: $APP_BUNDLE"
echo "archive: $ZIP_PATH"
