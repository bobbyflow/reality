# Reality release runbook

## Cost and prerequisites

Local builds and ad-hoc dogfooding are free. Public direct distribution requires an active Apple
Developer Program membership, a `Developer ID Application` certificate, and notarization access.
Credentials stay in Keychain and environment variables; never place them in this repository.

Apple references: [Developer ID](https://developer.apple.com/developer-id/) and
[notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## 1. Validate an unsigned dogfood archive

```bash
./script/security_check.sh
./script/verify.sh
./script/package_app.sh
codesign -dvvv --entitlements - dist/release/Reality.app
codesign --verify --deep --strict dist/release/Reality.app
```

The default package is ad-hoc signed with hardened runtime. It is suitable only for this Mac and
will not pass Gatekeeper as a public download.

## 2. Configure notarization once

```bash
xcrun notarytool store-credentials REALITY_NOTARY \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

The command stores credentials in Keychain. Do not paste credentials into scripts, GitHub, logs,
or task messages.

## 3. Sign, notarize, staple, and verify

```bash
export REALITY_DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
export REALITY_NOTARY_PROFILE="REALITY_NOTARY"
export REALITY_VERSION="0.1.0"
export REALITY_BUILD_NUMBER="1"
./script/notarize_app.sh
```

Required proof:

```bash
codesign -dvvv --entitlements - dist/release/Reality.app
xcrun stapler validate dist/release/Reality.app
spctl -a -vv --type execute dist/release/Reality.app
shasum -a 256 dist/release/Reality-0.1.0.zip
```

## 4. Seven-day dogfood gate

Install the stapled app in `/Applications`. For seven continuous days verify:

- start at login and restart continuity
- active/away/unknown truthfulness across lock, sleep, and wake
- pause and resume boundaries
- denied/revoked Accessibility remains honest app-only tracking
- manual capture, away labels, review, and exactly one correction
- CSV export redaction and formula neutralization
- delete today and delete everything
- crash/relaunch produces unknown rather than false work
- no captured metadata in unified logs or Git

Do not begin browser-domain, AI, cloud, or team features until this gate completes.
