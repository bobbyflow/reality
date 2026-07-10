#!/usr/bin/env bash
set -euo pipefail

: "${REALITY_DEVELOPER_ID:?Set REALITY_DEVELOPER_ID to a Developer ID Application identity}"
: "${REALITY_NOTARY_PROFILE:?Set REALITY_NOTARY_PROFILE to an xcrun notarytool Keychain profile}"
[[ "$REALITY_DEVELOPER_ID" == "Developer ID Application:"* ]] || {
  echo "REALITY_DEVELOPER_ID must name a Developer ID Application certificate" >&2
  exit 2
}
security find-identity -v -p codesigning | grep -F "\"$REALITY_DEVELOPER_ID\"" >/dev/null || {
  echo "Developer ID Application certificate is not available in this Keychain" >&2
  exit 2
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${REALITY_VERSION:-0.1.0}"
APP="$ROOT_DIR/dist/release/Reality.app"
ZIP="$ROOT_DIR/dist/release/Reality-$VERSION.zip"

REALITY_CODESIGN_IDENTITY="$REALITY_DEVELOPER_ID" "$ROOT_DIR/script/package_app.sh"
xcrun notarytool submit "$ZIP" --keychain-profile "$REALITY_NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"
codesign --verify --deep --strict "$APP"
spctl -a -vv --type execute "$APP"

rm -f "$ZIP" "$ZIP.sha256"
ditto -c -k --keepParent "$APP" "$ZIP"
shasum -a 256 "$ZIP" | tee "$ZIP.sha256"
echo "notarized and stapled: $APP"
