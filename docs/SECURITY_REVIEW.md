# Phase 6 security review

Date: 2026-07-10

Revision reviewed: Phase 6 working tree after `342f5cf`

Scope: 54 application source files, 5 project scripts, dependency manifests, CI, privacy and
release configuration.

## Result

No open high, medium, or low severity repository findings remain from this focused single-pass
review. Three concrete hardening gaps were found and fixed before release preparation:

1. **Export symlink and CSV-formula exposure** — exports now reject symbolic-link destinations,
   use a mode-600 temporary file plus atomic rename, neutralize formula-leading fields including
   leading whitespace, and re-redact excluded blocks.
2. **Database path redirection** — Application Support database and immediate directory must be
   regular non-symlink filesystem objects before GRDB opens them.
3. **Orphaned private labels after deletion** — deleting a day now removes its away-label keys as
   well as raw and derived database rows.

## Evidence

- `swift test`: retention, export, corruption, symlink, redaction, deletion, collector-health,
  clock/gap, and projection contracts.
- `script/security_check.sh`: forbidden capture/network APIs, dynamic logging, secrets,
  machine-specific paths, tracked private artifacts, lockfile presence, and diff hygiene.
- `swift build -c release --product Reality`: release compiler gate.
- `npm audit --audit-level=high`: zero known prototype vulnerabilities at review time.
- `swift package resolve` produced no `Package.resolved` drift.
- Git history filename scan found no SQLite, CSV, JSONL, certificate, or provisioning artifacts.
- Unified-log inspection contained no captured application metadata.

## Failure-mode validation

| Scenario | Verified behavior |
|---|---|
| Accessibility denied | app-only tracking remains active and visibly degraded |
| Persistence unavailable | collector health becomes degraded rather than claiming health |
| Corrupt SQLite | initialization fails closed; no fabricated fallback timeline |
| Reconciliation gap | interval becomes Unknown |
| Clock change | monotonic duration is retained and quality degrades |
| Excluded activity | database, projection, and export remove identity |
| Delete range/all | raw and derived evidence are removed; all-data deletion clears local reflection keys |
| Export attack strings | CSV quoting and spreadsheet-formula neutralization apply |

## Residual/external risks

- A compromised macOS user account can read that user's local data.
- Continuously running instances prune expired raw evidence on next app start; background daily
  pruning can be added after dogfood if restarts prove too infrequent.
- Public-download trust still requires a Developer ID Application certificate, notarization,
  staple, and Gatekeeper acceptance.
- Seven-day behavioral and continuous-runtime evidence cannot be compressed into an automated
  test and remains a release gate.
