import Foundation
import Testing

@testable import Reality

@Suite("Daily aggregation")
struct DailyAggregationTests {
  private let base = Date(timeIntervalSince1970: 5_000_000)

  @Test("empty and partial days never produce conclusions")
  func evidenceGate() {
    let aggregator = DailyAggregator(minimumActiveEvidence: 1_800)
    #expect(aggregator.summarize([]).hasEnoughEvidence == false)

    let partial = aggregator.summarize([block(0, 600, category: .focus)])
    #expect(partial.activeDuration == 600)
    #expect(partial.hasEnoughEvidence == false)
    #expect(partial.largestRecoverableLeak == nil)
  }

  @Test("manual projection prevents double counting")
  func manualOverlap() {
    let automatic = segment(0, 60, category: .focus)
    let manual = ManualEntry(
      id: uuid(2), start: base.addingTimeInterval(20), end: base.addingTimeInterval(40),
      title: "Call", category: .collaboration, note: nil, timezoneID: "UTC",
      createdAt: base, updatedAt: base)
    let projected = TimelineProjector().project(automatic: [automatic], manual: [manual])

    let summary = DailyAggregator(minimumActiveEvidence: 0).summarize(projected)

    #expect(summary.evidenceDuration == 60)
    #expect(summary.categoryDurations[.focus] == 40)
    #expect(summary.categoryDurations[.collaboration] == 20)
  }

  @Test("away is distinct from recovery and drift is the recoverable leak")
  func awayRecoveryAndLeak() {
    let summary = DailyAggregator(minimumActiveEvidence: 0).summarize([
      block(0, 300, state: .away, category: nil),
      block(300, 600, category: .recovery),
      block(600, 1_200, category: .drift),
    ])

    #expect(summary.awayDuration == 300)
    #expect(summary.categoryDurations[.recovery] == 300)
    #expect(summary.categoryDurations[.drift] == 600)
    #expect(summary.largestRecoverableLeak?.duration == 600)
  }

  @Test("day bounds clip midnight while DST duration stays absolute")
  func midnightAndDST() throws {
    let start = try #require(ISO8601DateFormatter().date(from: "2026-10-25T00:30:00Z"))
    let end = try #require(ISO8601DateFormatter().date(from: "2026-10-25T01:30:00Z"))
    let day = DateInterval(start: start.addingTimeInterval(900), end: end)
    let block = TimelineBlock(
      id: uuid(3), sourceID: uuid(4), start: start, end: end, origin: .automatic,
      title: nil, appBundleID: "app", appName: "App", state: .active, category: .focus,
      timezoneID: "Europe/London")

    let summary = DailyAggregator(minimumActiveEvidence: 0).summarize([block], in: day)

    #expect(summary.evidenceDuration == 2_700)
  }

  @Test("deletion recomputes to a truthful empty summary")
  func deletionRecomputation() {
    let aggregator = DailyAggregator(minimumActiveEvidence: 0)
    #expect(aggregator.summarize([block(0, 60, category: .focus)]).evidenceDuration == 60)
    #expect(aggregator.summarize([]).evidenceDuration == 0)
    #expect(aggregator.summarize([]).hasEnoughEvidence == false)
  }

  private func block(
    _ start: TimeInterval,
    _ end: TimeInterval,
    state: ActivityState = .active,
    category: ActivityCategory?
  ) -> TimelineBlock {
    TimelineBlock(
      id: uuid(Int(start + 10)), sourceID: uuid(Int(start + 20)),
      start: base.addingTimeInterval(start), end: base.addingTimeInterval(end),
      origin: .automatic, title: nil, appBundleID: state == .active ? "app" : nil,
      appName: state == .active ? "App" : nil, state: state, category: category,
      timezoneID: "UTC")
  }

  private func segment(
    _ start: TimeInterval, _ end: TimeInterval, category: ActivityCategory
  ) -> ActivitySegment {
    ActivitySegment(
      id: uuid(1), start: base.addingTimeInterval(start), end: base.addingTimeInterval(end),
      appBundleID: "app", appName: "App", state: .active, source: .automatic,
      quality: .exact, category: category, timezoneID: "UTC", derivationVersion: 1)
  }

  private func uuid(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
  }
}
