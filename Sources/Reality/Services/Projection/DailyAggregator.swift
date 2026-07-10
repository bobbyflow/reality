import Foundation

struct RecoverableLeak: Equatable, Sendable {
  let start: Date
  let end: Date
  let duration: TimeInterval
  let appName: String?
}

struct DailySummary: Equatable, Sendable {
  let evidenceDuration: TimeInterval
  let activeDuration: TimeInterval
  let awayDuration: TimeInterval
  let unknownDuration: TimeInterval
  let categoryDurations: [ActivityCategory: TimeInterval]
  let largestRecoverableLeak: RecoverableLeak?
  let hasEnoughEvidence: Bool

  static let empty = DailySummary(
    evidenceDuration: 0,
    activeDuration: 0,
    awayDuration: 0,
    unknownDuration: 0,
    categoryDurations: [:],
    largestRecoverableLeak: nil,
    hasEnoughEvidence: false
  )
}

struct DailyAggregator: Sendable {
  let minimumActiveEvidence: TimeInterval

  init(minimumActiveEvidence: TimeInterval = 1_800) {
    self.minimumActiveEvidence = max(0, minimumActiveEvidence)
  }

  func summarize(
    _ blocks: [TimelineBlock], in interval: DateInterval? = nil
  ) -> DailySummary {
    var evidence: TimeInterval = 0
    var active: TimeInterval = 0
    var away: TimeInterval = 0
    var unknown: TimeInterval = 0
    var categories: [ActivityCategory: TimeInterval] = [:]
    var driftBlocks: [RecoverableLeak] = []

    for block in blocks {
      let start = max(block.start, interval?.start ?? block.start)
      let end = min(block.end, interval?.end ?? block.end)
      let duration = end.timeIntervalSince(start)
      guard duration > 0 else { continue }
      evidence += duration
      switch block.state {
      case .active:
        active += duration
        if let category = block.category {
          categories[category, default: 0] += duration
        }
        if block.category == .drift {
          driftBlocks.append(
            RecoverableLeak(
              start: start, end: end, duration: duration, appName: block.appName ?? block.title))
        }
      case .away:
        away += duration
      case .unknown, .paused:
        unknown += duration
      case .excluded:
        break
      }
    }

    let enough = active > 0 && active >= minimumActiveEvidence
    let leak = enough ? driftBlocks.max(by: leakOrder) : nil
    return DailySummary(
      evidenceDuration: evidence,
      activeDuration: active,
      awayDuration: away,
      unknownDuration: unknown,
      categoryDurations: categories,
      largestRecoverableLeak: leak,
      hasEnoughEvidence: enough
    )
  }

  private func leakOrder(_ lhs: RecoverableLeak, _ rhs: RecoverableLeak) -> Bool {
    if lhs.duration != rhs.duration { return lhs.duration < rhs.duration }
    return lhs.start > rhs.start
  }
}
