import Foundation
import GRDB
import Testing

@testable import Reality

@Suite("Database migrations")
struct DatabaseMigrationTests {
  @Test("creates a private WAL database with defaults and indexed range queries")
  func createsSecureIndexedDatabase() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)

    try manager.pool.read { db in
      let tables = try String.fetchAll(
        db,
        sql: "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
      )
      #expect(tables.contains("activity_segments"))
      #expect(tables.contains("categories"))
      #expect(tables.contains("manual_entries"))
      #expect(tables.contains("collector_runs"))
      #expect(tables.contains("raw_samples"))
      #expect(tables.contains("settings"))
      #expect(tables.contains("system_events"))

      let categoryCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM categories")
      let retention = try String.fetchOne(
        db,
        sql: "SELECT value FROM settings WHERE key = 'raw_retention_days'"
      )
      let journalMode = try String.fetchOne(db, sql: "PRAGMA journal_mode")
      let foreignKeys = try Int.fetchOne(db, sql: "PRAGMA foreign_keys")
      let secureDelete = try Int.fetchOne(db, sql: "PRAGMA secure_delete")
      let busyTimeout = try Int.fetchOne(db, sql: "PRAGMA busy_timeout")

      #expect(categoryCount == 7)
      #expect(retention == "14")
      #expect(journalMode?.lowercased() == "wal")
      #expect(foreignKeys == 1)
      #expect(secureDelete == 1)
      #expect(busyTimeout == 5_000)

      let plan = try Row.fetchAll(
        db,
        sql: """
          EXPLAIN QUERY PLAN
          SELECT * FROM manual_entries
          WHERE start_ms < ? AND end_ms > ?
          ORDER BY start_ms
          """,
        arguments: [2_000, 1_000]
      )
      let details = plan.map { row -> String in row["detail"] }
      #expect(details.contains { $0.contains("USING INDEX idx_manual_entries_range") })

      let rawPlan = try Row.fetchAll(
        db,
        sql: """
          EXPLAIN QUERY PLAN
          SELECT * FROM raw_samples
          WHERE start_ms < ? AND end_ms > ?
          ORDER BY start_ms
          """,
        arguments: [2_000, 1_000]
      )
      let rawDetails = rawPlan.map { row -> String in row["detail"] }
      #expect(rawDetails.contains { $0.contains("USING INDEX idx_raw_samples_range") })
    }

    let attributes = try FileManager.default.attributesOfItem(
      atPath: fixture.databaseURL.path
    )
    let permissions = try #require(attributes[.posixPermissions] as? NSNumber)
    #expect((permissions.intValue & 0o777) == 0o600)
  }

  @Test("upgrades a version-one database without losing existing activity")
  func upgradesPriorVersion() throws {
    let fixture = try DatabaseFixture()
    let pool = try DatabaseManager.makePool(at: fixture.databaseURL)
    try Migrations.makeV1Migrator().migrate(pool)

    try pool.write { db in
      try db.execute(
        sql: """
          INSERT INTO manual_entries
            (id, start_ms, end_ms, title, category_id, note, timezone_id,
             created_at_ms, updated_at_ms)
          VALUES (?, ?, ?, ?, ?, NULL, ?, ?, ?)
          """,
        arguments: ["prior", 1_000, 2_000, "Existing work", "focus", "UTC", 1_000, 1_000]
      )
    }

    try Migrations.makeMigrator().migrate(pool)

    try pool.read { db in
      let activityCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM manual_entries")
      let settingsExists = try db.tableExists("settings")
      let indexes = try db.indexes(on: "manual_entries")
      #expect(activityCount == 1)
      #expect(settingsExists)
      #expect(indexes.contains { $0.name == "idx_manual_entries_range" })
    }
  }
}

struct DatabaseFixture {
  let directoryURL: URL
  let databaseURL: URL

  init() throws {
    directoryURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("RealityTests-\(UUID().uuidString)", isDirectory: true)
    databaseURL = directoryURL.appendingPathComponent("reality.sqlite")
    try FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o700]
    )
  }
}
