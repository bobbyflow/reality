import Foundation

enum ActivityCategory: String, CaseIterable, Codable, Sendable {
  case focus
  case collaboration
  case admin
  case learning
  case drift
  case recovery
  case unknown
}

enum ActivityState: String, Codable, Sendable {
  case active
  case away
  case unknown
  case excluded
}

enum ActivitySource: String, Codable, Sendable {
  case automatic
  case manual
}

enum EvidenceQuality: String, Codable, Sendable {
  case exact
  case degraded
}

struct ManualEntry: Identifiable, Equatable, Sendable {
  let id: UUID
  let start: Date
  let end: Date
  let title: String
  let category: ActivityCategory?
  let note: String?
  let timezoneID: String
  let createdAt: Date
  let updatedAt: Date
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

enum TimelineItem: Equatable, Sendable {
  case automatic(ActivitySegment)
  case manual(ManualEntry)

  var start: Date {
    switch self {
    case .automatic(let segment): segment.start
    case .manual(let entry): entry.start
    }
  }
}

extension Date {
  var epochMilliseconds: Int64 {
    Int64((timeIntervalSince1970 * 1_000).rounded())
  }
}

extension Int64 {
  var dateFromEpochMilliseconds: Date {
    Date(timeIntervalSince1970: Double(self) / 1_000)
  }
}
