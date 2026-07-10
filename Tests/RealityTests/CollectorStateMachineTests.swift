import Foundation
import Testing

@testable import Reality

@Suite("Collector state machine")
struct CollectorStateMachineTests {
  private let base = Date(timeIntervalSince1970: 1_000_000)

  @Test("activation closes the previous application at the observed boundary")
  func activation() {
    var machine = CollectorStateMachine()
    #expect(machine.ingest(observation(at: 0, app: terminal)).isEmpty)

    let evidence = machine.ingest(observation(at: 5, app: safari))

    #expect(evidence == [interval(0, 5, app: terminal, state: .active)])
  }

  @Test("idle is backdated to the last input rather than the polling instant")
  func idleBackdating() {
    var machine = CollectorStateMachine(configuration: .init(idleThreshold: 300))
    _ = machine.ingest(observation(at: 0, app: terminal))

    let evidence = machine.ingest(observation(at: 400, app: terminal, idle: 360))

    #expect(
      evidence == [
        interval(0, 40, app: terminal, state: .active),
        interval(40, 400, app: nil, state: .away, reason: .idle),
      ])
  }

  @Test("locking and sleeping close work immediately and never create false work")
  func lockSleepWake() {
    var machine = CollectorStateMachine()
    _ = machine.ingest(observation(at: 0, app: terminal))

    #expect(
      machine.ingest(observation(at: 5, app: terminal, session: .locked)) == [
        interval(0, 5, app: terminal, state: .active)
      ])
    #expect(
      machine.ingest(observation(at: 10, app: nil, session: .asleep)) == [
        interval(5, 10, app: nil, state: .away, reason: .locked)
      ])
    #expect(
      machine.ingest(observation(at: 15, app: safari)) == [
        interval(10, 15, app: nil, state: .away, reason: .asleep)
      ])
  }

  @Test("a missed notification reconciles from the provider without extending the old app")
  func missedNotification() {
    var machine = CollectorStateMachine()
    _ = machine.ingest(observation(at: 0, app: terminal))
    _ = machine.ingest(observation(at: 5, app: terminal))

    #expect(
      machine.ingest(observation(at: 10, app: safari)) == [
        interval(5, 10, app: terminal, state: .active)
      ])
  }

  @Test("wall clock changes use monotonic duration and degrade the interval")
  func clockChange() {
    var machine = CollectorStateMachine()
    _ = machine.ingest(observation(at: 0, app: terminal))
    var changed = observation(at: 10, app: terminal)
    changed.wallTime = base.addingTimeInterval(3_610)

    #expect(
      machine.ingest(changed) == [
        interval(0, 10, app: nil, state: .unknown, quality: .degraded, reason: .clockChanged)
      ])
  }

  @Test("a reconciliation gap over twenty seconds is unknown")
  func crashGap() {
    var machine = CollectorStateMachine(configuration: .init(maximumTrustedGap: 20))
    _ = machine.ingest(observation(at: 0, app: terminal))

    #expect(
      machine.ingest(observation(at: 21, app: terminal)) == [
        interval(0, 21, app: nil, state: .unknown, quality: .degraded, reason: .reconciliationGap)
      ])
  }

  @Test("pause is immediate and resumed time starts from fresh evidence")
  func pause() {
    var machine = CollectorStateMachine()
    _ = machine.ingest(observation(at: 0, app: terminal))

    #expect(
      machine.ingest(observation(at: 5, app: terminal, paused: true)) == [
        interval(0, 5, app: terminal, state: .active)
      ])
    #expect(
      machine.ingest(observation(at: 10, app: terminal, paused: true)) == [
        interval(5, 10, app: nil, state: .paused, reason: .paused)
      ])
    #expect(
      machine.ingest(observation(at: 15, app: terminal)) == [
        interval(10, 15, app: nil, state: .paused, reason: .paused)
      ])
  }

  @Test("excluded applications persist duration without identity")
  func exclusion() {
    var machine = CollectorStateMachine()
    _ = machine.ingest(observation(at: 0, app: terminal, excluded: true))

    #expect(
      machine.ingest(observation(at: 5, app: terminal, excluded: true)) == [
        interval(0, 5, app: nil, state: .excluded, reason: .excluded)
      ])
  }

  @Test("Accessibility loss degrades health but app-only evidence continues")
  func permissionLoss() {
    var machine = CollectorStateMachine()
    _ = machine.ingest(observation(at: 0, app: terminal))
    _ = machine.ingest(observation(at: 5, app: terminal, permission: .denied))

    #expect(machine.health == .degraded(.accessibilityDenied))
    #expect(
      machine.ingest(observation(at: 10, app: terminal, permission: .denied)) == [
        interval(
          5, 10, app: terminal, state: .active, quality: .degraded,
          reason: .accessibilityDenied)
      ])
  }

  private var terminal: ForegroundApplication {
    ForegroundApplication(bundleIdentifier: "com.apple.Terminal", displayName: "Terminal")
  }

  private var safari: ForegroundApplication {
    ForegroundApplication(bundleIdentifier: "com.apple.Safari", displayName: "Safari")
  }

  private func observation(
    at offset: TimeInterval,
    app: ForegroundApplication?,
    idle: TimeInterval = 0,
    session: CollectorSessionState = .active,
    paused: Bool = false,
    excluded: Bool = false,
    permission: AccessibilityPermission = .granted
  ) -> CollectorObservation {
    CollectorObservation(
      wallTime: base.addingTimeInterval(offset),
      uptime: offset,
      foregroundApplication: app,
      idleDuration: idle,
      sessionState: session,
      isPaused: paused,
      isExcluded: excluded,
      accessibilityPermission: permission,
      timezoneID: "Europe/London"
    )
  }

  private func interval(
    _ start: TimeInterval,
    _ end: TimeInterval,
    app: ForegroundApplication?,
    state: CollectorEvidenceState,
    quality: EvidenceQuality = .exact,
    reason: CollectorEvidenceReason = .observed
  ) -> CollectorEvidence {
    CollectorEvidence(
      start: base.addingTimeInterval(start),
      end: base.addingTimeInterval(end),
      monotonicDuration: end - start,
      application: app,
      state: state,
      quality: quality,
      reason: reason,
      timezoneID: "Europe/London"
    )
  }
}
