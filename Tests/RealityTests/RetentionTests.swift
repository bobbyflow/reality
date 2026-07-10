import Foundation
import Testing

@testable import Reality

@Suite("Raw evidence retention")
struct RetentionTests {
  @Test("deletes expired raw evidence while retaining derived history")
  func prunesOnlyRawEvidence() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let evidenceRepository = GRDBCollectorEvidenceRepository(pool: manager.pool)
    let activityRepository = GRDBActivityRepository(pool: manager.pool)
    let now = Date(timeIntervalSince1970: 2_000_000)
    let old = now.addingTimeInterval(-15 * 86_400)
    let recent = now.addingTimeInterval(-13 * 86_400)
    for start in [old, recent] {
      try evidenceRepository.append(sample(start: start))
    }
    let derived = ActivitySegment(
      id: UUID(), start: old, end: old.addingTimeInterval(5), appBundleID: nil,
      appName: nil, state: .away, source: .automatic, quality: .exact, category: nil,
      timezoneID: "UTC", derivationVersion: 1)
    try activityRepository.save(segment: derived)

    let deleted = try RetentionService(repository: evidenceRepository).prune(
      retentionDays: 14, now: now)

    #expect(deleted == 1)
    #expect(
      try evidenceRepository.fetch(
        in: DateInterval(start: old.addingTimeInterval(-1), end: now)
      ).count == 1)
    #expect(
      try activityRepository.fetchTimeline(
        in: DateInterval(start: old.addingTimeInterval(-1), duration: 10)
      ) == [.automatic(derived)])
  }

  @Test("rejects unsafe retention values")
  func validatesRetention() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let service = RetentionService(
      repository: GRDBCollectorEvidenceRepository(pool: manager.pool))

    #expect(throws: RetentionServiceError.invalidRetentionDays) {
      try service.prune(retentionDays: 0, now: .now)
    }
  }

  private func sample(start: Date) -> CollectorEvidence {
    CollectorEvidence(
      start: start, end: start.addingTimeInterval(5), monotonicDuration: 5,
      application: nil, state: .away, quality: .exact, reason: .idle, timezoneID: "UTC")
  }
}
