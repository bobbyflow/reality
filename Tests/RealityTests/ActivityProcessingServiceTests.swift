import Foundation
import Testing

@testable import Reality

@Suite("Activity processing service")
struct ActivityProcessingServiceTests {
  @Test("derives and classifies raw evidence into the activity source of truth")
  func reprocessesEvidence() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let evidenceRepository = GRDBCollectorEvidenceRepository(pool: manager.pool)
    let activityRepository = GRDBActivityRepository(pool: manager.pool)
    let service = ActivityProcessingService(
      evidenceRepository: evidenceRepository,
      activityRepository: activityRepository,
      segmenter: Segmenter(derivationVersion: 4)
    )
    let base = Date(timeIntervalSince1970: 80_000)
    let terminal = ForegroundApplication(
      bundleIdentifier: "com.apple.Terminal", displayName: "Terminal")
    for offset in [0.0, 5.0] {
      try evidenceRepository.append(
        CollectorEvidence(
          start: base.addingTimeInterval(offset),
          end: base.addingTimeInterval(offset + 5),
          monotonicDuration: 5,
          application: terminal,
          state: .active,
          quality: .exact,
          reason: .observed,
          timezoneID: "UTC"
        ))
    }

    try service.reprocess(in: DateInterval(start: base, duration: 10))

    let timeline = try activityRepository.fetchTimeline(
      in: DateInterval(start: base, duration: 10))
    guard case .automatic(let derived) = try #require(timeline.first) else {
      Issue.record("Expected derived automatic segment")
      return
    }
    #expect(timeline.count == 1)
    #expect(derived.start == base)
    #expect(derived.end == base.addingTimeInterval(10))
    #expect(derived.category == .unknown)
    #expect(derived.derivationVersion == 4)
  }
}
