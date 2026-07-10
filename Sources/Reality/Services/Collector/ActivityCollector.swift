import Foundation

@MainActor
protocol CollectorControlling: AnyObject {
  var health: CollectorHealth { get }
  var healthDidChange: ((CollectorHealth) -> Void)? { get set }
  func start()
  func stop()
  func setPaused(_ paused: Bool)
}

struct CollectorConfiguration: Equatable, Sendable {
  var idleThreshold: TimeInterval = 300
  var maximumTrustedGap: TimeInterval = 20
  var clockTolerance: TimeInterval = 2
}

struct CollectorStateMachine: Sendable {
  private let configuration: CollectorConfiguration
  private var previous: CollectorObservation?
  private(set) var health: CollectorHealth = .stopped

  init(configuration: CollectorConfiguration = .init()) {
    self.configuration = configuration
  }

  mutating func ingest(_ current: CollectorObservation) -> [CollectorEvidence] {
    defer {
      previous = current
      health = health(for: current)
    }
    guard let previous else {
      return []
    }

    let monotonicDuration = current.uptime - previous.uptime
    guard monotonicDuration > 0 else {
      return []
    }

    let wallDuration = current.wallTime.timeIntervalSince(previous.wallTime)
    if abs(wallDuration - monotonicDuration) > configuration.clockTolerance {
      return [
        evidence(
          from: previous.wallTime,
          duration: monotonicDuration,
          observation: previous,
          application: nil,
          state: .unknown,
          quality: .degraded,
          reason: .clockChanged
        )
      ]
    }

    if previous.sessionState != .active {
      return [
        evidence(
          from: previous.wallTime,
          duration: monotonicDuration,
          observation: previous,
          application: nil,
          state: .away,
          reason: previous.sessionState == .locked ? .locked : .asleep
        )
      ]
    }

    if previous.isPaused {
      return [
        evidence(
          from: previous.wallTime,
          duration: monotonicDuration,
          observation: previous,
          application: nil,
          state: .paused,
          reason: .paused
        )
      ]
    }

    if previous.isExcluded {
      return [
        evidence(
          from: previous.wallTime,
          duration: monotonicDuration,
          observation: previous,
          application: nil,
          state: .excluded,
          reason: .excluded
        )
      ]
    }

    if current.idleDuration >= configuration.idleThreshold {
      let idleStart = current.wallTime.addingTimeInterval(-current.idleDuration)
      let boundary = min(max(idleStart, previous.wallTime), current.wallTime)
      var result: [CollectorEvidence] = []
      let activeDuration = boundary.timeIntervalSince(previous.wallTime)
      if activeDuration > 0 {
        result.append(
          evidence(
            from: previous.wallTime,
            duration: activeDuration,
            observation: previous,
            application: previous.foregroundApplication,
            state: previous.foregroundApplication == nil ? .unknown : .active,
            quality: previous.foregroundApplication == nil ? .degraded : quality(for: previous),
            reason: previous.foregroundApplication == nil
              ? .applicationUnavailable : reason(for: previous)
          ))
      }
      let awayDuration = current.wallTime.timeIntervalSince(boundary)
      if awayDuration > 0 {
        result.append(
          evidence(
            from: boundary,
            duration: awayDuration,
            observation: previous,
            application: nil,
            state: .away,
            reason: .idle
          ))
      }
      return result
    }

    if monotonicDuration > configuration.maximumTrustedGap {
      return [
        evidence(
          from: previous.wallTime,
          duration: monotonicDuration,
          observation: previous,
          application: nil,
          state: .unknown,
          quality: .degraded,
          reason: .reconciliationGap
        )
      ]
    }

    let app = previous.foregroundApplication
    return [
      evidence(
        from: previous.wallTime,
        duration: monotonicDuration,
        observation: previous,
        application: app,
        state: app == nil ? .unknown : .active,
        quality: app == nil ? .degraded : quality(for: previous),
        reason: app == nil ? .applicationUnavailable : reason(for: previous)
      )
    ]
  }

  private func health(for observation: CollectorObservation) -> CollectorHealth {
    if observation.isPaused { return .paused }
    if observation.accessibilityPermission == .denied {
      return .degraded(.accessibilityDenied)
    }
    if observation.foregroundApplication == nil && observation.sessionState == .active {
      return .degraded(.foregroundApplicationUnavailable)
    }
    return .healthy
  }

  private func quality(for observation: CollectorObservation) -> EvidenceQuality {
    observation.accessibilityPermission == .granted ? .exact : .degraded
  }

  private func reason(for observation: CollectorObservation) -> CollectorEvidenceReason {
    observation.accessibilityPermission == .granted ? .observed : .accessibilityDenied
  }

  private func evidence(
    from start: Date,
    duration: TimeInterval,
    observation: CollectorObservation,
    application: ForegroundApplication?,
    state: CollectorEvidenceState,
    quality: EvidenceQuality = .exact,
    reason: CollectorEvidenceReason = .observed
  ) -> CollectorEvidence {
    CollectorEvidence(
      start: start,
      end: start.addingTimeInterval(duration),
      monotonicDuration: duration,
      application: application,
      state: state,
      quality: quality,
      reason: reason,
      timezoneID: observation.timezoneID
    )
  }
}

@MainActor
final class ActivityCollector: CollectorControlling {
  private let repository: any CollectorEvidenceRepository
  private let foregroundProvider: any ForegroundApplicationProviding
  private let idleProvider: any IdleStateProviding
  private let workspaceMonitor: WorkspaceEventMonitor
  private let permissionService: AccessibilityPermissionService
  private let clock: any CollectorClock
  private var stateMachine: CollectorStateMachine
  private var timer: Timer?
  private var isPaused = false
  private var excludedBundleIDs: Set<String> = []
  private(set) var health: CollectorHealth = .stopped {
    didSet {
      guard oldValue != health else { return }
      healthDidChange?(health)
    }
  }
  var healthDidChange: ((CollectorHealth) -> Void)?

  init(
    repository: any CollectorEvidenceRepository,
    foregroundProvider: any ForegroundApplicationProviding = ForegroundApplicationProvider(),
    idleProvider: any IdleStateProviding = IdleStateProvider(),
    workspaceMonitor: WorkspaceEventMonitor = WorkspaceEventMonitor(),
    permissionService: AccessibilityPermissionService = AccessibilityPermissionService(),
    clock: any CollectorClock = SystemCollectorClock(),
    configuration: CollectorConfiguration = .init()
  ) {
    self.repository = repository
    self.foregroundProvider = foregroundProvider
    self.idleProvider = idleProvider
    self.workspaceMonitor = workspaceMonitor
    self.permissionService = permissionService
    self.clock = clock
    stateMachine = CollectorStateMachine(configuration: configuration)
  }

  func start() {
    guard timer == nil else { return }
    workspaceMonitor.start { [weak self] in
      self?.reconcile()
    }
    reconcile()
    let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.reconcile()
      }
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  func stop() {
    guard timer != nil else { return }
    reconcile()
    timer?.invalidate()
    timer = nil
    workspaceMonitor.stop()
    health = .stopped
  }

  func setPaused(_ paused: Bool) {
    guard paused != isPaused else { return }
    reconcile()
    isPaused = paused
    reconcile()
  }

  func setExcludedBundleIDs(_ bundleIDs: Set<String>) {
    reconcile()
    excludedBundleIDs = bundleIDs
    reconcile()
  }

  private func reconcile() {
    let application = foregroundProvider.currentApplication()
    let observation = CollectorObservation(
      wallTime: clock.now,
      uptime: clock.uptime,
      foregroundApplication: application,
      idleDuration: idleProvider.idleDuration,
      sessionState: workspaceMonitor.sessionState,
      isPaused: isPaused,
      isExcluded: application.map { excludedBundleIDs.contains($0.bundleIdentifier) } ?? false,
      accessibilityPermission: permissionService.currentPermission,
      timezoneID: TimeZone.current.identifier
    )
    let evidence = stateMachine.ingest(observation)
    do {
      for item in evidence {
        try repository.append(item)
      }
      health = stateMachine.health
    } catch {
      health = .degraded(.persistenceUnavailable)
    }
  }
}
