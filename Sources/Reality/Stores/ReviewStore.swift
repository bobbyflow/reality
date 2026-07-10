import Foundation
import Observation

struct DailyIntention: Equatable, Sendable {
  var essential: String
  var optionalOutcomes: [String]

  init(essential: String = "", optionalOutcomes: [String] = []) {
    self.essential = essential
    self.optionalOutcomes = Array(optionalOutcomes.prefix(2))
  }
}

enum ReviewStoreError: Error, Equatable {
  case blankCorrection
}

@MainActor
@Observable
final class ReviewStore {
  private let defaults: UserDefaults
  private(set) var summary: DailySummary = .empty
  private(set) var intention = DailyIntention()
  private(set) var correction: String?

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    correction = defaults.string(forKey: "review.correction")
  }

  var isReady: Bool { summary.hasEnoughEvidence }
  var recoverableLeak: RecoverableLeak? { isReady ? summary.largestRecoverableLeak : nil }
  var corrections: [String] { correction.map { [$0] } ?? [] }

  var plannedVersusActual: String? {
    guard isReady, !intention.essential.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { return nil }
    let focus = summary.categoryDurations[.focus, default: 0]
    return "Planned: \(intention.essential) · Focus evidence: \(formatDuration(focus))"
  }

  func prepare(summary: DailySummary, intention: DailyIntention) {
    self.summary = summary
    self.intention = intention
  }

  func setCorrection(_ value: String) throws {
    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { throw ReviewStoreError.blankCorrection }
    correction = cleaned
    defaults.set(cleaned, forKey: "review.correction")
  }

  func clear() {
    summary = .empty
    intention = DailyIntention()
    correction = nil
    defaults.removeObject(forKey: "review.correction")
  }

  private func formatDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration / 60)
    if minutes < 60 { return "\(minutes)m" }
    return "\(minutes / 60)h \(minutes % 60)m"
  }
}
