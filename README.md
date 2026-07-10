# Reality

> See where your time went. Decide what changes tomorrow.

Reality is a privacy-first macOS activity tracker for people whose work happens on a computer. It records a local timeline of active applications and away time, compares behaviour with daily intentions, and turns the gap into one concrete correction.

## Product thesis

People finish days feeling busy but cannot honestly explain whether their time served what mattered. Existing trackers often create more data, not better decisions. Reality closes one loop:

```text
intention → observed behaviour → honest review → one correction
```

## Safety boundary

Reality is designed to be useful without becoming surveillance.

- Local storage by default
- No account or cloud dependency
- No screenshots
- No keystroke or clipboard capture
- Window titles disabled by default
- Away time remains unknown until the user labels it
- Pause, exclusions, export, and permanent deletion are first-class controls
- AI is optional and never part of collection

Read [PRIVACY.md](PRIVACY.md) and [SECURITY.md](SECURITY.md) before contributing.

## Repository status

This repository currently contains:

- `Sources/Reality`: the native app, private evidence store, collector, and deterministic processor
- `Tests/RealityTests`: truthfulness and app-state tests
- [`script/build_and_run.sh`](script/build_and_run.sh): canonical build, bundle, sign, and launch entrypoint
- [`prototype/web`](prototype/web): the validated interaction prototype
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): native macOS architecture
- [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md): phased build plan and gates
- [`.agents/skills/grdb`](.agents/skills/grdb): project-local GRDB implementation guidance, pinned by `skills-lock.json`

The prototype intentionally starts empty. It does not present demonstration activity as real user data, and its automatic-tracking control does not claim collection is active.

## Planned stack

- Swift 6
- SwiftUI with narrow AppKit interop
- GRDB + SQLite/WAL
- Native macOS APIs: `NSWorkspace`, Accessibility, Core Graphics idle time, workspace lifecycle notifications
- SwiftPM and XCTest
- Direct Developer ID distribution; no App Sandbox for the Accessibility-enabled build

## Development

### Web prototype

```bash
cd prototype/web
npm install
npm test
npm run dev
```

### Native app

```bash
./script/build_and_run.sh
```

Run the complete Phase 1 gate with:

```bash
./script/verify.sh
```

The native app records private evidence, derives stable activity blocks, and exposes a complete daily timeline with intentions, manual capture, away labels, evidence-gated review, category patterns, one correction, CSV export, and deletion controls.

Privacy hardening, retention, safe export, threat modelling, release packaging, and notarization
automation are included. See [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md),
[`docs/SECURITY_REVIEW.md`](docs/SECURITY_REVIEW.md), and [`docs/RELEASE.md`](docs/RELEASE.md).

## Non-goals

Reality is not employee monitoring, project management, a public leaderboard, or a system for maximizing every minute. Rest and necessary personal time are not treated as failure.

## License

MIT. The project-local GRDB skill is copied from a separately licensed MIT source; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
