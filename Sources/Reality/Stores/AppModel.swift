import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
  var selection: NavigationSection = .today
  private(set) var activities: [ActivitySummary] = []
  private(set) var collectorStatus: CollectorStatus

  init(collectorStatus: CollectorStatus = .unavailable) {
    self.collectorStatus = collectorStatus
  }

  var isTracking: Bool { collectorStatus.isTracking }
  var canTogglePause: Bool { collectorStatus.canTogglePause }
  var emptyStateMessage: String { "No activity recorded yet." }

  func togglePause() {
    switch collectorStatus {
    case .tracking:
      collectorStatus = .paused
    case .paused:
      collectorStatus = .tracking
    case .unavailable:
      break
    }
  }
}
