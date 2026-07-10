import Foundation

enum CollectorStatus: Equatable, Sendable {
  case unavailable
  case paused
  case tracking
  case degraded

  var isTracking: Bool { self == .tracking || self == .degraded }
  var canTogglePause: Bool { self != .unavailable }

  var title: String {
    switch self {
    case .unavailable: "Not connected"
    case .paused: "Paused"
    case .tracking: "Tracking"
    case .degraded: "Tracking app activity"
    }
  }

  var detail: String {
    switch self {
    case .unavailable: "Automatic tracking is not connected."
    case .paused: "Automatic tracking is paused."
    case .tracking: "Automatic tracking is active."
    case .degraded: "App tracking is active; optional Accessibility access is unavailable."
    }
  }

  var systemImage: String {
    switch self {
    case .unavailable: "circle.dashed"
    case .paused: "pause.circle"
    case .tracking: "record.circle"
    case .degraded: "exclamationmark.circle"
    }
  }
}
