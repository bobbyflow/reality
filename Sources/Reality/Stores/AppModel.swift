import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
  var selection: NavigationSection = .today
  private(set) var activities: [ActivitySummary] = []
  private(set) var collectorStatus: CollectorStatus
  private var collector: (any CollectorControlling)?
  private var databaseManager: DatabaseManager?

  init(collectorStatus: CollectorStatus = .unavailable) {
    self.collectorStatus = collectorStatus
  }

  init(collector: any CollectorControlling) {
    self.collector = collector
    collectorStatus = Self.status(for: collector.health)
    collector.healthDidChange = { [weak self] health in
      self?.collectorStatus = Self.status(for: health)
    }
  }

  static func live() -> AppModel {
    do {
      let manager = try DatabaseManager.live()
      let repository = GRDBCollectorEvidenceRepository(pool: manager.pool)
      let model = AppModel(collector: ActivityCollector(repository: repository))
      model.databaseManager = manager
      return model
    } catch {
      return AppModel()
    }
  }

  var isTracking: Bool { collectorStatus.isTracking }
  var canTogglePause: Bool { collectorStatus.canTogglePause }
  var emptyStateMessage: String { "No activity recorded yet." }

  func togglePause() {
    if let collector {
      collector.setPaused(collectorStatus != .paused)
      return
    }
    switch collectorStatus {
    case .tracking, .degraded:
      collectorStatus = .paused
    case .paused:
      collectorStatus = .tracking
    case .unavailable:
      break
    }
  }

  func startCollector() {
    collector?.start()
  }

  private static func status(for health: CollectorHealth) -> CollectorStatus {
    switch health {
    case .stopped: .unavailable
    case .healthy: .tracking
    case .paused: .paused
    case .degraded: .degraded
    }
  }
}
