# Architecture

## Decision

Reality v1 is a native macOS app built with SwiftUI and narrow AppKit/Core Graphics interop.

A native collector is lower risk than a hosted webpage plus localhost bridge: it keeps collection alive when the window is closed, uses macOS permission and lifecycle APIs directly, and avoids exposing a local network API.

```text
macOS signals
  NSWorkspace · Accessibility · idle time · lock/sleep
        │
        ▼
Collector → immutable short-lived samples → deterministic segmenter
                                                   │
                                                   ▼
                                  GRDB/SQLite source of truth
                                      │             │
                                      ▼             ▼
                              classification     projections
                                      │             │
                                      └──────┬──────┘
                                             ▼
                              SwiftUI timeline and reviews
```

## Boundaries

### Collector

Reads foreground application, idle duration, session lock, sleep, and wake. It does not assign productivity meaning. App activation notifications are reconciled with a five-second poll so a missed event cannot create a giant false block.

### Evidence store

Raw samples and system events are append-only and short-lived. Timestamps use UTC plus monotonic duration evidence. Gaps, crashes, permission loss, and clock changes become explicit unknown intervals.

### Segmenter

Builds non-overlapping half-open intervals `[start, end)`. It splits at application changes, idle thresholds, sleep/lock, pause/exclusion, timezone change, and excessive sample gaps.

### Classifier

Applies deterministic priority: user correction → user rule → default rule → unknown. Classification may evolve without rewriting raw evidence.

### Projection

Combines automatic evidence with manual entries without double-counting. Away, unknown, recovery, and drift remain separate concepts.

### Presentation

SwiftUI renders queries and issues validated commands. Views never write SQL directly and never own collection state.

## Native interfaces

- Foreground app: `NSWorkspace.shared.frontmostApplication`
- App changes and lifecycle: `NSWorkspace.notificationCenter`
- Optional focused title: Accessibility `AXUIElement`; disabled by default
- Idle duration: `CGEventSource.secondsSinceLastEventType`
- Start at login: `SMAppService.mainApp`
- Menu bar: `MenuBarExtra`
- Persistence: GRDB `DatabasePool`, WAL, foreign keys, transactional migrations
- Logging: `OSLog.Logger`, state transitions only; captured metadata remains private

## Permission model

App-only tracking works without Accessibility permission. Focused window titles are a separately enabled enhancement. Permission denial or revocation produces a visible degraded state; the app never claims full tracking is active.

No Screen Recording or Input Monitoring permission is required or requested.

## Storage

Database location: `~/Library/Application Support/Reality/reality.sqlite`.

Tables:

- `collector_runs`
- `raw_samples`
- `system_events`
- `activity_segments`
- `manual_entries`
- `away_annotations`
- `categories`
- `classification_rules`
- `classification_assignments`
- `corrections`
- `daily_intentions`
- `daily_reviews`
- `settings`

Raw samples default to 14-day retention. Derived records remain until user deletion. Excluded intervals contain no app/domain/title metadata.

## Distribution

Use direct Developer ID distribution, hardened runtime, and notarization. Do not enable App Sandbox for the Accessibility-enabled v1. Stabilize bundle identifier, signature, and installed path early because macOS privacy grants are identity-sensitive.
