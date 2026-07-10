import Foundation

final class ActivityProcessingService {
  private let evidenceRepository: any CollectorEvidenceRepository
  private let activityRepository: any ActivityRepository
  private let segmenter: Segmenter
  private let ruleEngine: RuleEngine
  private let userRules: [ClassificationRule]
  private let defaultRules: [ClassificationRule]
  private let corrections: [UUID: BlockCorrection]

  init(
    evidenceRepository: any CollectorEvidenceRepository,
    activityRepository: any ActivityRepository,
    segmenter: Segmenter = Segmenter(),
    ruleEngine: RuleEngine = RuleEngine(),
    userRules: [ClassificationRule] = [],
    defaultRules: [ClassificationRule] = [],
    corrections: [BlockCorrection] = []
  ) {
    self.evidenceRepository = evidenceRepository
    self.activityRepository = activityRepository
    self.segmenter = segmenter
    self.ruleEngine = ruleEngine
    self.userRules = userRules
    self.defaultRules = defaultRules
    self.corrections = Dictionary(uniqueKeysWithValues: corrections.map { ($0.segmentID, $0) })
  }

  func reprocess(in interval: DateInterval) throws {
    let evidence = try evidenceRepository.fetch(in: interval).compactMap {
      clipped($0, to: interval)
    }
    let classified = segmenter.process(evidence: evidence).map { segment in
      ruleEngine.applying(
        to: segment,
        correction: corrections[segment.id],
        userRules: userRules,
        defaultRules: defaultRules
      )
    }
    try activityRepository.replaceAutomaticSegments(in: interval, with: classified)
  }

  func reprocessToday(now: Date = .now, timezone: TimeZone = .current) throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timezone
    guard let day = calendar.dateInterval(of: .day, for: now) else { return }
    try reprocess(in: day)
  }

  private func clipped(
    _ evidence: CollectorEvidence, to interval: DateInterval
  ) -> CollectorEvidence? {
    let start = max(evidence.start, interval.start)
    let end = min(evidence.end, interval.end)
    guard end > start else { return nil }
    return CollectorEvidence(
      start: start,
      end: end,
      monotonicDuration: end.timeIntervalSince(start),
      application: evidence.application,
      state: evidence.state,
      quality: evidence.quality,
      reason: evidence.reason,
      timezoneID: evidence.timezoneID
    )
  }
}
