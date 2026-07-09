import Foundation
import Testing

@testable import Reality

@Suite("Activity repository contract")
struct ActivityRepositoryContractTests {
  @Test("persists manual and automatic evidence in chronological order")
  func persistsAndFetchesTimeline() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let repository = GRDBActivityRepository(pool: manager.pool)
    let base = Date(timeIntervalSince1970: 1_000)

    let automatic = ActivitySegment(
      id: UUID(),
      start: base,
      end: base.addingTimeInterval(600),
      appBundleID: "com.apple.Terminal",
      appName: "Terminal",
      state: .active,
      source: .automatic,
      quality: .exact,
      category: .focus,
      timezoneID: "Europe/London",
      derivationVersion: 1
    )
    let manual = ManualEntry(
      id: UUID(),
      start: base.addingTimeInterval(900),
      end: base.addingTimeInterval(1_500),
      title: "Plan tomorrow",
      category: .admin,
      note: nil,
      timezoneID: "Europe/London",
      createdAt: base,
      updatedAt: base
    )

    try repository.save(segment: automatic)
    try repository.save(manualEntry: manual)

    let timeline = try repository.fetchTimeline(
      in: DateInterval(start: base.addingTimeInterval(-1), duration: 2_000)
    )

    #expect(timeline == [.automatic(automatic), .manual(manual)])
  }

  @Test("upserts corrections without creating duplicate manual entries")
  func updatesManualEntry() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let repository = GRDBActivityRepository(pool: manager.pool)
    let base = Date(timeIntervalSince1970: 2_000)
    let id = UUID()

    try repository.save(
      manualEntry: ManualEntry(
        id: id,
        start: base,
        end: base.addingTimeInterval(300),
        title: "Inbox",
        category: .admin,
        note: nil,
        timezoneID: "UTC",
        createdAt: base,
        updatedAt: base
      )
    )
    let corrected = ManualEntry(
      id: id,
      start: base,
      end: base.addingTimeInterval(300),
      title: "Client reply",
      category: .collaboration,
      note: "Corrected",
      timezoneID: "UTC",
      createdAt: base,
      updatedAt: base.addingTimeInterval(60)
    )
    try repository.save(manualEntry: corrected)

    let timeline = try repository.fetchTimeline(
      in: DateInterval(start: base.addingTimeInterval(-1), duration: 1_000)
    )
    #expect(timeline == [.manual(corrected)])
  }

  @Test("range deletion removes overlapping evidence from every activity table")
  func deletesOverlappingRange() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let repository = GRDBActivityRepository(pool: manager.pool)
    let base = Date(timeIntervalSince1970: 10_000)

    let overlapping = ManualEntry(
      id: UUID(),
      start: base,
      end: base.addingTimeInterval(600),
      title: "Overlap",
      category: .focus,
      note: nil,
      timezoneID: "UTC",
      createdAt: base,
      updatedAt: base
    )
    let retained = ManualEntry(
      id: UUID(),
      start: base.addingTimeInterval(1_200),
      end: base.addingTimeInterval(1_800),
      title: "Retained",
      category: .learning,
      note: nil,
      timezoneID: "UTC",
      createdAt: base,
      updatedAt: base
    )
    let automatic = ActivitySegment(
      id: UUID(),
      start: base.addingTimeInterval(300),
      end: base.addingTimeInterval(900),
      appBundleID: "com.apple.TextEdit",
      appName: "TextEdit",
      state: .active,
      source: .automatic,
      quality: .exact,
      category: nil,
      timezoneID: "UTC",
      derivationVersion: 1
    )

    try repository.save(manualEntry: overlapping)
    try repository.save(manualEntry: retained)
    try repository.save(segment: automatic)
    try repository.deleteActivities(
      in: DateInterval(start: base.addingTimeInterval(450), duration: 300)
    )

    let timeline = try repository.fetchTimeline(
      in: DateInterval(start: base.addingTimeInterval(-1), duration: 2_000)
    )
    #expect(timeline == [.manual(retained)])
  }

  @Test("delete all leaves no durable activity")
  func deletesAllActivity() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let repository = GRDBActivityRepository(pool: manager.pool)
    let base = Date(timeIntervalSince1970: 20_000)

    try repository.save(
      manualEntry: ManualEntry(
        id: UUID(),
        start: base,
        end: base.addingTimeInterval(60),
        title: "Temporary",
        category: nil,
        note: nil,
        timezoneID: "UTC",
        createdAt: base,
        updatedAt: base
      )
    )
    try repository.deleteAllActivities()

    #expect(
      try repository.fetchTimeline(
        in: DateInterval(start: base.addingTimeInterval(-1), duration: 500)
      ).isEmpty
    )
  }

  @Test("rejects invalid intervals before writing")
  func rejectsInvalidIntervals() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let repository = GRDBActivityRepository(pool: manager.pool)
    let now = Date(timeIntervalSince1970: 30_000)
    let invalid = ManualEntry(
      id: UUID(),
      start: now,
      end: now,
      title: "Impossible",
      category: nil,
      note: nil,
      timezoneID: "UTC",
      createdAt: now,
      updatedAt: now
    )

    do {
      try repository.save(manualEntry: invalid)
      Issue.record("Expected invalid interval rejection")
    } catch let error as ActivityRepositoryError {
      #expect(error == .invalidInterval)
    }
  }

  @Test("rejects blank manual titles and invalid derivation versions")
  func rejectsInvalidActivityValues() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let repository = GRDBActivityRepository(pool: manager.pool)
    let now = Date(timeIntervalSince1970: 35_000)

    let blankTitle = ManualEntry(
      id: UUID(),
      start: now,
      end: now.addingTimeInterval(60),
      title: "   ",
      category: nil,
      note: nil,
      timezoneID: "UTC",
      createdAt: now,
      updatedAt: now
    )
    do {
      try repository.save(manualEntry: blankTitle)
      Issue.record("Expected blank title rejection")
    } catch let error as ActivityRepositoryError {
      #expect(error == .invalidTitle)
    }

    let invalidVersion = ActivitySegment(
      id: UUID(),
      start: now,
      end: now.addingTimeInterval(60),
      appBundleID: nil,
      appName: nil,
      state: .unknown,
      source: .automatic,
      quality: .degraded,
      category: nil,
      timezoneID: "UTC",
      derivationVersion: 0
    )
    do {
      try repository.save(segment: invalidVersion)
      Issue.record("Expected derivation version rejection")
    } catch let error as ActivityRepositoryError {
      #expect(error == .invalidDerivationVersion)
    }
  }

  @Test("excluded evidence persists duration without identifying metadata")
  func excludedEvidenceIsRedacted() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let repository = GRDBActivityRepository(pool: manager.pool)
    let base = Date(timeIntervalSince1970: 40_000)
    let excluded = ActivitySegment(
      id: UUID(),
      start: base,
      end: base.addingTimeInterval(300),
      appBundleID: "com.private.app",
      appName: "Private App",
      state: .excluded,
      source: .automatic,
      quality: .exact,
      category: nil,
      timezoneID: "UTC",
      derivationVersion: 1
    )

    try repository.save(segment: excluded)

    let timeline = try repository.fetchTimeline(
      in: DateInterval(start: base.addingTimeInterval(-1), duration: 500)
    )
    guard case .automatic(let stored) = try #require(timeline.first) else {
      Issue.record("Expected automatic segment")
      return
    }
    #expect(stored.appBundleID == nil)
    #expect(stored.appName == nil)
    #expect(stored.start == excluded.start)
    #expect(stored.end == excluded.end)
  }
}
