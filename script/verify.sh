#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash -n script/build_and_run.sh
swift test
./script/build_and_run.sh --verify

APP_BUNDLE="$ROOT_DIR/dist/Reality.app"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
DATABASE="$HOME/Library/Application Support/Reality/reality.sqlite"

plutil -lint "$INFO_PLIST" >/dev/null
plutil -extract CFBundleIdentifier raw "$INFO_PLIST" | grep -Fx "com.bobbyflow.reality" >/dev/null
codesign --verify --deep --strict "$APP_BUNDLE"
test -f "$DATABASE"
test "$(stat -f '%Lp' "$DATABASE")" = "600"
test "$(sqlite3 "$DATABASE" 'PRAGMA journal_mode;')" = "wal"
test "$(sqlite3 "$DATABASE" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name IN ('activity_segments','categories','manual_entries','settings');")" = "4"

if rg -n 'CGEventTap|addGlobalMonitorForEvents|CGWindowListCopyWindowInfo|ScreenCaptureKit|SCShareableContent|NSPasteboard|AVCapture|URLSession' Sources; then
  echo "forbidden capture or network API found in Phase 1" >&2
  exit 1
fi

if rg -n --hidden --glob '!.git/**' --glob '!.build/**' --glob '!dist/**' \
  --glob '!.swiftpm/**' --glob '!prototype/web/node_modules/**' --glob '!script/verify.sh' \
  '(gh[opsu]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|/Users/bobbc|xox[baprs]-)' .; then
  echo "secret or machine-specific path found in tracked files" >&2
  exit 1
fi

echo "verification passed"
