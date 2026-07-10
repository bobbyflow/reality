#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash -n script/*.sh
plutil -lint Config/Reality.entitlements >/dev/null

forbidden_api='CGEventTap|addGlobalMonitorForEvents|CGWindowListCopyWindowInfo|ScreenCaptureKit|SCShareableContent|NSPasteboard|AVCapture|URLSession|WKWebView'
if rg -n "$forbidden_api" Sources; then
  echo "forbidden capture, clipboard, or network API found" >&2
  exit 1
fi

if rg -n 'logger\.(debug|info|notice|warning|error|fault)\([^"[:space:]]' Sources; then
  echo "dynamic unified-log payload found" >&2
  exit 1
fi

if rg -n --hidden --glob '!.git/**' --glob '!.build/**' --glob '!dist/**' \
  --glob '!.swiftpm/**' --glob '!prototype/web/node_modules/**' \
  --glob '!script/security_check.sh' --glob '!script/verify.sh' \
  '(gh[opsu]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|/Users/[^/[:space:]]+|xox[baprs]-)' .; then
  echo "secret or machine-specific path found" >&2
  exit 1
fi

test -f Package.resolved
test "$(git ls-files '*.sqlite' '*.sqlite3' '*.db' '*.db-wal' '*.db-shm' '*.csv' '*.jsonl' | wc -l | tr -d ' ')" = "0"
git diff --check

echo "security checks passed"
