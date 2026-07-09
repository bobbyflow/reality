import Foundation

enum CollectorStatus: Equatable, Sendable {
  case unavailable
  case paused
  case tracking

  var isTracking: Bool { self == .tracking }
  var canTogglePause: Bool { self != .unavailable }

  var title: String {
    switch self {
    case .unavailable: "Not connected"
    case .paused: "Paused"
    case .tracking: "Tracking"
    }
  }

  var detail: String {
    switch self {
    case .unavailable: "Automatic tracking is not connected."
    case .paused: "Automatic tracking is paused."
    case .tracking: "Automatic tracking is active."
    }
  }

  var systemImage: String {
    switch self {
    case .unavailable: "circle.dashed"
    case .paused: "pause.circle"
    case .tracking: "record.circle"
    }
  }
}
