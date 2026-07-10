import Foundation

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
