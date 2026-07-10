# Security policy

## Reporting

Please report security issues privately through GitHub Security Advisories rather than public issues.

## Repository safety rules

- Never commit captured activity, local databases, exports, logs, `.env` files, signing certificates, tokens, or provisioning profiles.
- Never write captured window titles, domains, or personal notes to unified logs.
- Treat the renderer/UI as untrusted input to the persistence layer.
- Validate all category, rule, date-range, and deletion commands before database writes.
- Keep collection deterministic and independent from AI/network availability.
- Pin dependencies and review their licenses before release.

## Distribution model

V1 is intended for direct Developer ID distribution with hardened runtime and notarization. App-only tracking does not require Accessibility permission; denial remains visible and collection stays in degraded app-only mode. Focused titles are not implemented.
