import Foundation

enum ActivityState: String, Codable, Sendable {
  case active
  case away
  case unknown
  case excluded
  case paused
}

enum ActivitySource: String, Codable, Sendable {
  case automatic
  case manual
}

enum EvidenceQuality: String, Codable, Sendable {
  case exact
  case degraded
}

struct ActivitySegment: Identifiable, Equatable, Sendable {
  let id: UUID
  let start: Date
  let end: Date
  let appBundleID: String?
  let appName: String?
  let state: ActivityState
  let source: ActivitySource
  let quality: EvidenceQuality
  let category: ActivityCategory?
  let timezoneID: String
  let derivationVersion: Int
}
