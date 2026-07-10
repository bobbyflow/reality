import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
  var selection: NavigationSection = .today
  private(set) var captureRequestID = 0
  private(set) var activities: [ActivitySummary] = []
  private(set) var collectorStatus: CollectorStatus
  private var collector: (any CollectorControlling)?
  private var databaseManager: DatabaseManager?
  private var processingService: ActivityProcessingService?
  private(set) var todayStore: TodayStore?
  private(set) var reviewStore: ReviewStore?
  private(set) var settingsStore: SettingsStore?

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
      let evidenceRepository = GRDBCollectorEvidenceRepository(pool: manager.pool)
      let activityRepository = GRDBActivityRepository(pool: manager.pool)
      let processor = ActivityProcessingService(
        evidenceRepository: evidenceRepository,
        activityRepository: activityRepository
      )
      try processor.reprocessToday()
      let todayStore = TodayStore(
        activityRepository: activityRepository, evidenceRepository: evidenceRepository)
      try todayStore.reload()
      let reviewStore = ReviewStore()
      reviewStore.prepare(summary: todayStore.summary, intention: todayStore.intention)
      let collector = ActivityCollector(repository: evidenceRepository)
      let model = AppModel(collector: collector)
      model.databaseManager = manager
      model.processingService = processor
      model.todayStore = todayStore
      model.reviewStore = reviewStore
      model.settingsStore = SettingsStore(todayStore: todayStore, reviewStore: reviewStore)
      collector.evidenceDidChange = { [weak processor, weak model] in
        try processor?.reprocessToday()
        try model?.todayStore?.reload()
        if let today = model?.todayStore {
          model?.reviewStore?.prepare(summary: today.summary, intention: today.intention)
        }
      }
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

  func requestCapture() {
    selection = .today
    captureRequestID += 1
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
