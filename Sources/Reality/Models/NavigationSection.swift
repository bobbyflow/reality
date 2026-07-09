import Foundation

enum NavigationSection: String, CaseIterable, Identifiable, Sendable {
  case today
  case review
  case patterns

  var id: Self { self }

  var title: String {
    switch self {
    case .today: "Today"
    case .review: "Review"
    case .patterns: "Patterns"
    }
  }

  var systemImage: String {
    switch self {
    case .today: "clock"
    case .review: "list.bullet.rectangle"
    case .patterns: "chart.line.uptrend.xyaxis"
    }
  }
}
