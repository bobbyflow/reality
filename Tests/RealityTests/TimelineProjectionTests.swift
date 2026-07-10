import Foundation
import Testing

@testable import Reality

@Suite("Timeline projection")
struct TimelineProjectionTests {
  private let base = Date(timeIntervalSince1970: 4_000_000)

  @Test("manual entries override automatic display without double-counting")
  func manualOverride() {
    let automatic = segment(0, 60, category: .focus)
    let manual = entry(20, 40, title: "Client call", category: .collaboration, updated: 1)

    let blocks = TimelineProjector().project(automatic: [automatic], manual: [manual])

    #expect(
      blocks.map(\.start) == [
        base, base.addingTimeInterval(20), base.addingTimeInterval(40),
      ])
    #expect(
      blocks.map(\.end) == [
        base.addingTimeInterval(20), base.addingTimeInterval(40),
        base.addingTimeInterval(60),
      ])
    #expect(blocks.map(\.origin) == [.automatic, .manual, .automatic])
    #expect(blocks.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) } == 60)
  }

  @Test("newest manual correction wins overlapping manual time deterministically")
  func manualConflict() {
    let older = entry(0, 30, title: "Old", category: .admin, updated: 1)
    let newer = entry(10, 20, title: "Corrected", category: .focus, updated: 2)

    let first = TimelineProjector().project(automatic: [], manual: [newer, older])
    let second = TimelineProjector().project(automatic: [], manual: [older, newer])

    #expect(first == second)
    #expect(first.map(\.title) == ["Old", "Corrected", "Old"])
    #expect(first.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) } == 30)
  }

  @Test("excluded blocks expose no identifying metadata")
  func exclusionRedaction() {
    let excluded = segment(
      0, 10, bundleID: "should.not.escape", appName: "Private", state: .excluded,
      category: nil)

    let block = TimelineProjector().project(automatic: [excluded], manual: []).first

    #expect(block?.state == .excluded)
    #expect(block?.appBundleID == nil)
    #expect(block?.appName == nil)
  }

  private func segment(
    _ start: TimeInterval,
    _ end: TimeInterval,
    bundleID: String? = "com.apple.Terminal",
    appName: String? = "Terminal",
    state: ActivityState = .active,
    category: ActivityCategory?
  ) -> ActivitySegment {
    ActivitySegment(
      id: uuid(Int(start + 100)), start: base.addingTimeInterval(start),
      end: base.addingTimeInterval(end), appBundleID: bundleID, appName: appName, state: state,
      source: .automatic, quality: .exact, category: category, timezoneID: "UTC",
      derivationVersion: 1)
  }

  private func entry(
    _ start: TimeInterval,
    _ end: TimeInterval,
    title: String,
    category: ActivityCategory,
    updated: TimeInterval
  ) -> ManualEntry {
    ManualEntry(
      id: uuid(Int(start + updated + 500)), start: base.addingTimeInterval(start),
      end: base.addingTimeInterval(end), title: title, category: category, note: nil,
      timezoneID: "UTC", createdAt: base, updatedAt: base.addingTimeInterval(updated))
  }

  private func uuid(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
  }
}
