import Foundation

struct ActivitySummary: Identifiable, Equatable, Sendable {
  let id: UUID
  let title: String
  let start: Date
  let end: Date
}
