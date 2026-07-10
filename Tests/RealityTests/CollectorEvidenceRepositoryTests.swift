import Foundation
import Testing

@testable import Reality

@Suite("Collector evidence repository")
struct CollectorEvidenceRepositoryTests {
  @Test("appends and fetches immutable evidence chronologically")
  func appendAndFetch() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let repository = GRDBCollectorEvidenceRepository(pool: manager.pool)
    let base = Date(timeIntervalSince1970: 50_000)
    let terminal = ForegroundApplication(
      bundleIdentifier: "com.apple.Terminal", displayName: "Terminal")
    let evidence = CollectorEvidence(
      start: base,
      end: base.addingTimeInterval(5),
      monotonicDuration: 5,
      application: terminal,
      state: .active,
      quality: .exact,
      reason: .observed,
      timezoneID: "UTC"
    )

    try repository.append(evidence)

    #expect(try repository.fetch(in: DateInterval(start: base, duration: 10)) == [evidence])
  }

  @Test("excluded evidence cannot persist application identity")
  func excludedRedaction() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let repository = GRDBCollectorEvidenceRepository(pool: manager.pool)
    let base = Date(timeIntervalSince1970: 60_000)

    try repository.append(
      CollectorEvidence(
        start: base,
        end: base.addingTimeInterval(5),
        monotonicDuration: 5,
        application: ForegroundApplication(
          bundleIdentifier: "private.bundle", displayName: "Private App"),
        state: .excluded,
        quality: .exact,
        reason: .excluded,
        timezoneID: "UTC"
      ))

    let saved = try #require(
      repository.fetch(in: DateInterval(start: base, duration: 10)).first)
    #expect(saved.application == nil)
    #expect(saved.state == .excluded)
  }

  @Test("rejects invalid monotonic duration")
  func rejectsInvalidDuration() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let repository = GRDBCollectorEvidenceRepository(pool: manager.pool)
    let base = Date(timeIntervalSince1970: 70_000)

    do {
      try repository.append(
        CollectorEvidence(
          start: base,
          end: base.addingTimeInterval(5),
          monotonicDuration: 0,
          application: nil,
          state: .unknown,
          quality: .degraded,
          reason: .reconciliationGap,
          timezoneID: "UTC"
        ))
      Issue.record("Expected invalid evidence rejection")
    } catch let error as CollectorEvidenceRepositoryError {
      #expect(error == .invalidDuration)
    }
  }
}
