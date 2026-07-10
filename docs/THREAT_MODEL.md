# Reality threat model

## Security objective

Reality must reconstruct time without becoming surveillance software. Captured application
identity and timestamps are sensitive personal data even when content is never collected.

## Trust boundaries

```text
macOS signals (untrusted availability)
        │
        ▼
collector ──validated evidence──► private SQLite
        │                              │
        ▼                              ▼
health state                    deterministic processor
                                       │
                                       ▼
SwiftUI commands ──validated──► projection / export / deletion
```

- Trusted: signed Reality process, validated domain services, GRDB transactions.
- Untrusted: macOS notification timing, foreground application metadata, user-entered text,
  export destinations, filesystem state, and database bytes after external tampering.
- Out of scope: a user or administrator with full access to the macOS account or a compromised
  operating system.

## Assets

- Raw activity evidence, derived timeline, intentions, away labels, and corrections.
- The truthfulness of tracking, pause, deletion, retention, and health claims.
- Signing identity, notarization credentials, and release integrity.

## Threats and controls

| Threat | Failure mode | Control | Residual risk |
|---|---|---|---|
| Permission spoofing | UI claims full tracking after Accessibility denial/revocation | Permission checked on every reconciliation; app-only mode is visibly degraded | macOS API itself may lag briefly |
| Misleading health | Timer, provider, or persistence fails while UI says tracking | Health comes from the running collector; persistence failures degrade status | Process termination cannot update UI |
| Notification loss | Missed activation or wake extends false work | Five-second reconciliation and >20-second unknown gaps | Up to five seconds of boundary uncertainty |
| Malicious metadata | Application names or user text corrupt storage/UI | Typed models, interval/title validation, SwiftUI text rendering, parameterized SQL | Legitimate names can still disclose sensitive context |
| Exclusion leakage | Excluded application identity survives in DB/export | State-boundary redaction plus SQLite CHECK and export redaction | Existing pre-exclusion evidence remains until deleted |
| CSV injection | Exported title executes a spreadsheet formula | Formula-leading fields are apostrophe-neutralized and CSV-escaped | Importers with nonstandard parsing may differ |
| Export leakage | Data is written through a symlink or without explicit action | User-selected file, file-only CSV, symlink rejection, mode 600, atomic rename | User can intentionally export to a synced folder |
| SQLite corruption | Damaged/tampered DB yields fabricated activity | GRDB migration/open failure makes the app unavailable; no fallback fabrication | Recovery UI is deferred |
| Symlink/path traversal | Application Support path redirects private data | Database and directory must be regular, non-symlink filesystem objects | Parent components are trusted macOS directories |
| Incomplete deletion | Derived rows disappear but raw evidence silently remains | Range/all deletion covers raw and derived repositories; tests verify both | New evidence begins again if tracking remains enabled |
| Retention failure | Raw samples exceed the 14-day contract | Startup retention service deletes by end timestamp transactionally | A continuously running app prunes on next restart |
| Accidental logging | Captured identity enters unified logs | Only fixed lifecycle/status strings; CI rejects dynamic logger payloads | Third-party framework logs remain outside our control |
| Dependency compromise | GRDB, Swift Testing, or npm dependency changes unexpectedly | Exact/revision pins, lockfiles, Dependabot, CI resolution-diff and audit | Upstream source compromise before pinning remains possible |
| Release substitution | User installs an altered build | Developer ID hardened-runtime signature, notarization, staple, Gatekeeper checks | Requires protected signing credentials and trusted download channel |

## Privacy invariants

1. No screenshots, keystrokes, clipboard, browser domains, or content capture.
2. Window titles remain unavailable and off by default.
3. Excluded intervals contain duration only.
4. AI and networking are absent from the collection and review path.
5. Conclusions require at least 30 minutes of active evidence.
6. Signing credentials never enter the repository or build artifacts.

## Verification

- Unit tests: state machine, redaction, deletion, retention, export, corruption, symlink defense.
- CI: tests, release build, formatter, forbidden-API scan, secret scan, lockfile integrity, npm audit.
- Release: signature details, entitlements, hardened runtime, notarization result, staple, Gatekeeper.
- Dogfood: seven days covering sleep/wake, restart, pause, exclusion, export, and deletion.
