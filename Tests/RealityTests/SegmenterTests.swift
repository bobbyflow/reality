import Foundation
import Testing

@testable import Reality

@Suite("Deterministic segmenter")
struct SegmenterTests {
  private let base = Date(timeIntervalSince1970: 2_000_000)

  @Test("merges adjacent samples and splits at application boundaries")
  func applicationBoundaries() {
    let segmenter = Segmenter(derivationVersion: 4)
    let terminal = app("com.apple.Terminal", "Terminal")
    let safari = app("com.apple.Safari", "Safari")

    let result = segmenter.process(evidence: [
      evidence(0, 5, application: terminal),
      evidence(5, 10, application: terminal),
      evidence(10, 15, application: safari),
    ])

    #expect(result.count == 2)
    #expect(result[0].start == base)
    #expect(result[0].end == base.addingTimeInterval(10))
    #expect(result[0].appBundleID == terminal.bundleIdentifier)
    #expect(result[0].derivationVersion == 4)
    #expect(result[1].start == base.addingTimeInterval(10))
    #expect(result[1].appBundleID == safari.bundleIdentifier)
  }

  @Test("clips overlapping evidence so automatic segments never overlap")
  func overlap() {
    let segmenter = Segmenter()
    let terminal = app("com.apple.Terminal", "Terminal")
    let safari = app("com.apple.Safari", "Safari")

    let result = segmenter.process(evidence: [
      evidence(0, 10, application: terminal),
      evidence(5, 15, application: safari),
    ])

    #expect(result.map(\.start) == [base, base.addingTimeInterval(10)])
    #expect(result.map(\.end) == [base.addingTimeInterval(10), base.addingTimeInterval(15)])
  }

  @Test("idle stays an unclassified state and exclusion remains redacted")
  func idleAndExclusion() {
    let segmenter = Segmenter()
    let privateApp = app("private.bundle", "Private")
    let result = segmenter.process(evidence: [
      evidence(0, 5, state: .away, reason: .idle),
      evidence(5, 10, application: privateApp, state: .excluded, reason: .excluded),
    ])

    #expect(result[0].state == .away)
    #expect(result[0].category == nil)
    #expect(result[1].state == .excluded)
    #expect(result[1].appBundleID == nil)
    #expect(result[1].appName == nil)
  }

  @Test("same evidence and version produce byte-stable identifiers")
  func deterministicReprocessing() {
    let input = [evidence(0, 5, application: app("com.apple.Terminal", "Terminal"))]

    let first = Segmenter(derivationVersion: 2).process(evidence: input)
    let second = Segmenter(derivationVersion: 2).process(evidence: input.reversed())

    #expect(first == second)
    #expect(first.first?.id.uuidString == second.first?.id.uuidString)
  }

  @Test("splits at local midnight and timezone changes without DST duration loss")
  func calendarBoundaries() throws {
    let segmenter = Segmenter()
    let terminal = app("com.apple.Terminal", "Terminal")
    let midnightStart = try #require(ISO8601DateFormatter().date(from: "2026-07-10T22:59:00Z"))
    let midnightEnd = try #require(ISO8601DateFormatter().date(from: "2026-07-10T23:01:00Z"))
    let fallbackStart = try #require(ISO8601DateFormatter().date(from: "2026-10-25T00:30:00Z"))
    let fallbackEnd = try #require(ISO8601DateFormatter().date(from: "2026-10-25T01:30:00Z"))

    let midnight = segmenter.process(evidence: [
      CollectorEvidence(
        start: midnightStart,
        end: midnightEnd,
        monotonicDuration: 120,
        application: terminal,
        state: .active,
        quality: .exact,
        reason: .observed,
        timezoneID: "Europe/London"
      )
    ])
    let midnightBoundary = try #require(
      ISO8601DateFormatter().date(from: "2026-07-10T23:00:00Z"))
    #expect(midnight.count == 2)
    #expect(midnight[0].end == midnightBoundary)

    let fallback = segmenter.process(evidence: [
      CollectorEvidence(
        start: fallbackStart,
        end: fallbackEnd,
        monotonicDuration: 3_600,
        application: terminal,
        state: .active,
        quality: .exact,
        reason: .observed,
        timezoneID: "Europe/London"
      )
    ])
    #expect(fallback.count == 1)
    #expect(fallback[0].end.timeIntervalSince(fallback[0].start) == 3_600)

    let timezoneChange = segmenter.process(evidence: [
      evidence(0, 5, application: terminal, timezoneID: "Europe/London"),
      evidence(5, 10, application: terminal, timezoneID: "Asia/Singapore"),
    ])
    #expect(timezoneChange.count == 2)
    #expect(timezoneChange.map(\.timezoneID) == ["Europe/London", "Asia/Singapore"])
  }

  private func app(_ id: String, _ name: String) -> ForegroundApplication {
    ForegroundApplication(bundleIdentifier: id, displayName: name)
  }

  private func evidence(
    _ start: TimeInterval,
    _ end: TimeInterval,
    application: ForegroundApplication? = nil,
    state: CollectorEvidenceState = .active,
    reason: CollectorEvidenceReason = .observed,
    timezoneID: String = "Europe/London"
  ) -> CollectorEvidence {
    CollectorEvidence(
      start: base.addingTimeInterval(start),
      end: base.addingTimeInterval(end),
      monotonicDuration: end - start,
      application: application,
      state: state,
      quality: .exact,
      reason: reason,
      timezoneID: timezoneID
    )
  }
}
