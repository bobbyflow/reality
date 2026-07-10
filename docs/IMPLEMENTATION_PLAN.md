# Reality Native macOS Tracker Implementation Plan

**Goal:** Ship a truthful, local-first macOS tracker that automatically records active applications and away time, then turns each day into one evidence-based correction.

**Architecture:** A native Swift collector writes immutable evidence to GRDB/SQLite. Deterministic services segment and classify evidence; SwiftUI queries projections and never owns collection or persistence logic. AI and networking are absent from v1.

**Tech stack:** Swift 6, SwiftUI, AppKit, ApplicationServices Accessibility, Core Graphics, ServiceManagement, GRDB, SQLite/WAL, OSLog, SwiftPM, XCTest.

## Global constraints

- Minimum target: macOS 14.
- Stable bundle ID: `com.bobbyflow.reality`.
- No screenshots, keystrokes, clipboard capture, hidden monitoring, or network dependency.
- Window-title collection is disabled by default.
- Automatic tracking must never appear active unless collector health is current.
- All personal data lives outside the repository under Application Support.
- Raw evidence uses 14-day default retention.
- Intervals are half-open `[start, end)` and durations use monotonic evidence.

## Phase 1 — Native shell and truthful empty state

**Status:** Complete and locally verified on 2026-07-09.

**Deliverable:** A launchable SwiftPM `.app` with main window, menu bar control, Settings scene, stable bundle identity, and no fabricated activity.

**Create:**

- `Package.swift`
- `Sources/Reality/App/RealityApp.swift`
- `Sources/Reality/App/AppDelegate.swift`
- `Sources/Reality/Views/RootView.swift`
- `Sources/Reality/Views/Today/TodayView.swift`
- `Sources/Reality/Views/Settings/SettingsView.swift`
- `Sources/Reality/Models/NavigationSection.swift`
- `Sources/Reality/Stores/AppModel.swift`
- `script/build_and_run.sh`
- `.codex/environments/environment.toml`
- `Tests/RealityTests/AppModelTests.swift`

**Design:** `WindowGroup(id: "main")` for the primary window, `MenuBarExtra` for Open/Pause/Add Activity/Quit, and a dedicated `Settings` scene. SwiftUI owns view state; `AppModel` coordinates services.

**Automated gate:** `swift test` passes; build script stages and validates `Reality.app`; `codesign -dvv` shows the expected bundle.

**Manual gate:** app opens in foreground, menu bar commands work, Settings opens, and the timeline says no activity recorded.

## Phase 2 — GRDB source of truth

**Status:** Complete and locally verified on 2026-07-09.

**Deliverable:** Versioned local SQLite database with repository contracts and deletion guarantees.

**Create:**

- `Sources/Reality/Database/DatabaseManager.swift`
- `Sources/Reality/Database/Migrations.swift`
- `Sources/Reality/Database/Records/*.swift`
- `Sources/Reality/Repositories/ActivityRepository.swift`
- `Sources/Reality/Repositories/GRDBActivityRepository.swift`
- `Tests/RealityTests/DatabaseMigrationTests.swift`
- `Tests/RealityTests/ActivityRepositoryContractTests.swift`

**Rules:** use `DatabasePool`; enable WAL, foreign keys, busy timeout, and secure deletion; keep SQL behind repositories; migrations are append-only. Store UTC timestamps, local timezone ID, source, state, quality, and derivation version.

**Automated gate:** migrations apply to empty and prior-version fixtures; repository contract tests cover insert/query/update/cascade deletion; `EXPLAIN QUERY PLAN` confirms day-range queries use indexes.

**Manual gate:** database appears only in Application Support and no database/log/export is tracked by Git.

## Phase 3 — Deterministic collector

**Status:** Complete and locally verified on 2026-07-10.

**Deliverable:** Background collection of foreground application, idle, lock, sleep, wake, pause, and permission health.

**Create:**

- `Sources/Reality/Services/Collector/ActivityCollector.swift`
- `Sources/Reality/Services/Collector/ForegroundApplicationProvider.swift`
- `Sources/Reality/Services/Collector/IdleStateProvider.swift`
- `Sources/Reality/Services/Collector/WorkspaceEventMonitor.swift`
- `Sources/Reality/Services/Collector/CollectorHealth.swift`
- `Sources/Reality/Services/Permissions/AccessibilityPermissionService.swift`
- `Tests/RealityTests/CollectorStateMachineTests.swift`

**Behaviour:** observe `NSWorkspace` activation and lifecycle notifications; reconcile every five seconds; idle after configurable 300 seconds; lock/sleep closes active work immediately; gaps over 20 seconds become unknown; app-only tracking remains available without Accessibility.

**Automated gate:** injected clock/provider tests cover activation, idle backdating, lock/wake, missed notification, clock change, crash gap, pause, exclusion, and permission loss.

**Manual gate:** switching apps creates correct evidence; locking/sleeping creates no false work; menu-bar pause is immediate; denied Accessibility produces an honest degraded state.

## Phase 4 — Segmentation, exclusions, and classification

**Status:** Complete and locally verified on 2026-07-10.

**Deliverable:** Reproducible activity blocks that can be corrected without corrupting raw evidence.

**Create:**

- `Sources/Reality/Domain/ActivitySegment.swift`
- `Sources/Reality/Domain/Category.swift`
- `Sources/Reality/Services/Segmentation/Segmenter.swift`
- `Sources/Reality/Services/Classification/RuleEngine.swift`
- `Sources/Reality/Services/Projection/TimelineProjector.swift`
- `Tests/RealityTests/SegmenterTests.swift`
- `Tests/RealityTests/RuleEngineTests.swift`
- `Tests/RealityTests/TimelineProjectionTests.swift`

**Categories:** Focus, Collaboration, Admin, Learning, Drift, Recovery, Unknown. Away remains a state, not a productivity category.

**Invariants:** automatic segments never overlap; same evidence/settings/version produces identical output; excluded activity persists only duration; manual records override automatic display without double-counting; corrections outrank every rule.

**Automated gate:** fixtures cover boundary changes, idle, overlap, midnight, DST fallback, timezone change, exclusion redaction, rule priority, and byte-equivalent reprocessing.

**Manual gate:** changing a classification offers “this block” or “future matches”; excluded apps disappear without leaving identifying metadata.

## Phase 5 — Daily experience

**Status:** Complete and locally verified on 2026-07-10.

**Deliverable:** Real Today, Review, Patterns, intentions, Away labelling, corrections, and deletion UI.

**Create:**

- `Sources/Reality/Views/Today/{TodayView,TimelineView,CaptureView,RealityCheckView}.swift`
- `Sources/Reality/Views/Review/ReviewView.swift`
- `Sources/Reality/Views/Patterns/PatternsView.swift`
- `Sources/Reality/Views/Away/AwayAnnotationSheet.swift`
- `Sources/Reality/Views/Settings/{PrivacySettingsView,RulesSettingsView,DataSettingsView}.swift`
- `Sources/Reality/Stores/{TodayStore,ReviewStore,SettingsStore}.swift`
- `Tests/RealityTests/{DailyAggregationTests,ReviewStoreTests}.swift`

**Experience:** morning essential outcome plus two optional outcomes; automatic timeline; return-from-away prompt; planned-vs-actual review; largest recoverable leak; exactly one correction for tomorrow. No conclusions appear without enough evidence.

**Automated gate:** aggregation tests cover empty state, partial day, manual overlap, away/recovery distinction, midnight/DST, and deletion recomputation.

**Manual gate:** one complete day can be recorded, corrected, reviewed, exported, and deleted; restarting preserves state; deleting all data leaves a truthful empty app.

## Phase 6 — Privacy hardening and threat model

**Status:** Complete and locally verified on 2026-07-10.

**Deliverable:** Security-reviewed local product suitable for dogfooding.

**Create:**

- `docs/THREAT_MODEL.md`
- `Sources/Reality/Services/RetentionService.swift`
- `Sources/Reality/Services/ExportService.swift`
- `Tests/RealityTests/{RetentionTests,ExportTests,RedactionTests}.swift`
- `.github/workflows/ci.yml`

**Review:** permission spoofing, renderer/input validation, SQLite corruption, symlink/path traversal, accidental logging, export leakage, deletion completeness, dependency compromise, and misleading collector health.

**Automated gate:** CI runs `swift test`, release build, secret scan, dependency audit, and forbidden-API grep; retention and deletion tests verify cascades and redaction.

**Manual gate:** inspect unified logs and Git history for captured metadata; revoke permission mid-session; simulate disk full/corrupt DB; verify the app stops claiming collection.

## Phase 7 — Signed dogfood release

**Status:** Release tooling and ad-hoc hardened-runtime package complete on 2026-07-10. Developer
ID notarization and the seven-day dogfood gate remain external prerequisites.

**Deliverable:** A signed, notarized direct-download build used for seven real days before browser-domain or AI work begins.

**Create:**

- `script/package_app.sh`
- `script/notarize_app.sh`
- `Config/Reality.entitlements`
- `docs/RELEASE.md`

**Distribution:** hardened runtime, Developer ID signing, notarization, staple, Gatekeeper validation. Signing credentials remain in Keychain/environment and never enter Git.

**Automated gate:** release build passes; nested signatures validate; `spctl -a -vv` accepts the artifact; repository secret scan remains clean.

**Manual gate:** fresh install, permission onboarding, login start, seven-day continuous collection, pause/exclusion/delete/export, and crash recovery all succeed.

## Explicitly deferred

- Browser-domain extensions
- Focused window titles by default
- Mobile tracking
- Cloud sync/accounts
- AI coaching
- Team or employee monitoring
- Public productivity scores, streaks, or leaderboards

These features are deferred until seven-day dogfooding proves that the deterministic loop changes behaviour.

## Definition of done

V1 is done when a fresh macOS installation can record one week locally, distinguish activity/away/unknown honestly, survive sleep/restarts/permission loss, produce evidence-based daily and weekly reviews, and permanently delete all data without network access or AI tokens.
