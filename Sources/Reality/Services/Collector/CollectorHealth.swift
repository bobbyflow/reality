import Foundation

enum CollectorDegradation: String, Equatable, Sendable {
  case accessibilityDenied
  case foregroundApplicationUnavailable
  case persistenceUnavailable
}

enum CollectorHealth: Equatable, Sendable {
  case stopped
  case healthy
  case paused
  case degraded(CollectorDegradation)
}

enum AccessibilityPermission: String, Equatable, Sendable {
  case granted
  case denied
}

enum CollectorSessionState: String, Equatable, Sendable {
  case active
  case locked
  case asleep
}

enum CollectorEvidenceState: String, Equatable, Sendable {
  case active
  case away
  case unknown
  case excluded
  case paused
}

enum CollectorEvidenceReason: String, Equatable, Sendable {
  case observed
  case idle
  case locked
  case asleep
  case reconciliationGap
  case clockChanged
  case paused
  case excluded
  case accessibilityDenied
  case applicationUnavailable
}

struct ForegroundApplication: Equatable, Sendable {
  let bundleIdentifier: String
  let displayName: String
}

struct CollectorEvidence: Equatable, Sendable {
  let start: Date
  let end: Date
  let monotonicDuration: TimeInterval
  let application: ForegroundApplication?
  let state: CollectorEvidenceState
  let quality: EvidenceQuality
  let reason: CollectorEvidenceReason
  let timezoneID: String
}

struct CollectorObservation: Equatable, Sendable {
  var wallTime: Date
  let uptime: TimeInterval
  let foregroundApplication: ForegroundApplication?
  let idleDuration: TimeInterval
  let sessionState: CollectorSessionState
  let isPaused: Bool
  let isExcluded: Bool
  let accessibilityPermission: AccessibilityPermission
  let timezoneID: String
}
