import Foundation
import GRDB

enum Migrations {
  static func makeV1Migrator() -> DatabaseMigrator {
    var migrator = DatabaseMigrator()
    registerV1(on: &migrator)
    return migrator
  }

  static func makeMigrator() -> DatabaseMigrator {
    var migrator = makeV1Migrator()
    registerV2(on: &migrator)
    registerV3(on: &migrator)
    return migrator
  }

  private static func registerV1(on migrator: inout DatabaseMigrator) {
    migrator.registerMigration("v1_activity_source_of_truth") { db in
      try db.execute(
        sql: """
          CREATE TABLE categories (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            color_hex TEXT NOT NULL,
            kind TEXT NOT NULL UNIQUE
          );

          CREATE TABLE manual_entries (
            id TEXT PRIMARY KEY NOT NULL,
            start_ms INTEGER NOT NULL,
            end_ms INTEGER NOT NULL,
            title TEXT NOT NULL,
            category_id TEXT REFERENCES categories(id) ON DELETE SET NULL,
            note TEXT,
            timezone_id TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL,
            updated_at_ms INTEGER NOT NULL,
            CHECK (end_ms > start_ms)
          );

          CREATE TABLE activity_segments (
            id TEXT PRIMARY KEY NOT NULL,
            start_ms INTEGER NOT NULL,
            end_ms INTEGER NOT NULL,
            app_bundle_id TEXT,
            app_name TEXT,
            state TEXT NOT NULL,
            source TEXT NOT NULL,
            quality TEXT NOT NULL,
            category_id TEXT REFERENCES categories(id) ON DELETE SET NULL,
            timezone_id TEXT NOT NULL,
            derivation_version INTEGER NOT NULL,
            created_at_ms INTEGER NOT NULL,
            CHECK (end_ms > start_ms),
            CHECK (derivation_version > 0)
          );
          """
      )

      let defaults = [
        CategoryRecord(id: "focus", name: "Focus", colorHex: "#16856B", kind: "focus"),
        CategoryRecord(
          id: "collaboration", name: "Collaboration", colorHex: "#5B6BC7",
          kind: "collaboration"),
        CategoryRecord(id: "admin", name: "Admin", colorHex: "#D88A31", kind: "admin"),
        CategoryRecord(
          id: "learning", name: "Learning", colorHex: "#7A65A8", kind: "learning"),
        CategoryRecord(id: "drift", name: "Drift", colorHex: "#D95D52", kind: "drift"),
        CategoryRecord(
          id: "recovery", name: "Recovery", colorHex: "#4B9CB5", kind: "recovery"),
        CategoryRecord(
          id: "unknown", name: "Unknown", colorHex: "#8B9390", kind: "unknown"),
      ]
      for category in defaults {
        try category.insert(db)
      }
    }
  }

  private static func registerV2(on migrator: inout DatabaseMigrator) {
    migrator.registerMigration("v2_settings_and_range_indexes") { db in
      try db.execute(
        sql: """
          CREATE TABLE settings (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL,
            updated_at_ms INTEGER NOT NULL
          );

          CREATE INDEX idx_manual_entries_range
            ON manual_entries(start_ms, end_ms);
          CREATE INDEX idx_activity_segments_range
            ON activity_segments(start_ms, end_ms);
          CREATE INDEX idx_manual_entries_category
            ON manual_entries(category_id);
          CREATE INDEX idx_activity_segments_category
            ON activity_segments(category_id);
          """
      )

      let now = Date.now.epochMilliseconds
      for (key, value) in [
        ("idle_threshold_seconds", "300"),
        ("raw_retention_days", "14"),
        ("store_window_titles", "false"),
        ("tracking_paused", "false"),
      ] {
        try db.execute(
          sql: "INSERT INTO settings (key, value, updated_at_ms) VALUES (?, ?, ?)",
          arguments: [key, value, now]
        )
      }
    }
  }

  private static func registerV3(on migrator: inout DatabaseMigrator) {
    migrator.registerMigration("v3_collector_evidence") { db in
      try db.execute(
        sql: """
          CREATE TABLE collector_runs (
            id TEXT PRIMARY KEY NOT NULL,
            started_at_ms INTEGER NOT NULL,
            ended_at_ms INTEGER,
            stop_reason TEXT,
            final_health TEXT
          );

          CREATE TABLE raw_samples (
            id TEXT PRIMARY KEY NOT NULL,
            run_id TEXT REFERENCES collector_runs(id) ON DELETE SET NULL,
            start_ms INTEGER NOT NULL,
            end_ms INTEGER NOT NULL,
            monotonic_duration_ms INTEGER NOT NULL,
            app_bundle_id TEXT,
            app_name TEXT,
            state TEXT NOT NULL,
            quality TEXT NOT NULL,
            reason TEXT NOT NULL,
            timezone_id TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL,
            CHECK (end_ms > start_ms),
            CHECK (monotonic_duration_ms > 0),
            CHECK (state != 'excluded' OR (app_bundle_id IS NULL AND app_name IS NULL))
          );

          CREATE TABLE system_events (
            id TEXT PRIMARY KEY NOT NULL,
            run_id TEXT REFERENCES collector_runs(id) ON DELETE SET NULL,
            occurred_at_ms INTEGER NOT NULL,
            uptime_ms INTEGER NOT NULL,
            kind TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL
          );

          CREATE INDEX idx_raw_samples_range ON raw_samples(start_ms, end_ms);
          CREATE INDEX idx_raw_samples_run ON raw_samples(run_id);
          CREATE INDEX idx_system_events_time ON system_events(occurred_at_ms);
          """
      )
    }
  }
}
