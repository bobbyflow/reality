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

The Accessibility-enabled v1 is intended for direct Developer ID distribution with hardened runtime and notarization. Accessibility permission is explicit and user-controlled. The app must remain useful in degraded app-only mode when permission is denied.
