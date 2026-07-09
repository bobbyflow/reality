import Foundation
import GRDB

final class GRDBActivityRepository: ActivityRepository {
  private let pool: DatabasePool

  init(pool: DatabasePool) {
    self.pool = pool
  }

  func save(manualEntry: ManualEntry) throws {
    guard manualEntry.end > manualEntry.start else {
      throw ActivityRepositoryError.invalidInterval
    }
    guard !manualEntry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ActivityRepositoryError.invalidTitle
    }
    let record = ManualEntryRecord(manualEntry)
    try pool.write { db in
      try record.save(db)
    }
  }

  func save(segment: ActivitySegment) throws {
    guard segment.end > segment.start else {
      throw ActivityRepositoryError.invalidInterval
    }
    guard segment.derivationVersion > 0 else {
      throw ActivityRepositoryError.invalidDerivationVersion
    }
    let record = ActivitySegmentRecord(segment)
    try pool.write { db in
      try record.save(db)
    }
  }

  func fetchTimeline(in interval: DateInterval) throws -> [TimelineItem] {
    let start = interval.start.epochMilliseconds
    let end = interval.end.epochMilliseconds
    return try pool.read { db in
      let manualRecords = try ManualEntryRecord.fetchAll(
        db,
        sql: """
          SELECT * FROM manual_entries
          WHERE start_ms < ? AND end_ms > ?
          ORDER BY start_ms
          """,
        arguments: [end, start]
      )
      let automaticRecords = try ActivitySegmentRecord.fetchAll(
        db,
        sql: """
          SELECT * FROM activity_segments
          WHERE start_ms < ? AND end_ms > ?
          ORDER BY start_ms
          """,
        arguments: [end, start]
      )

      let manualItems = try manualRecords.map { TimelineItem.manual(try $0.domainValue()) }
      let automaticItems = try automaticRecords.map {
        TimelineItem.automatic(try $0.domainValue())
      }
      return (manualItems + automaticItems).sorted {
        if $0.start == $1.start {
          return timelineSortRank($0) < timelineSortRank($1)
        }
        return $0.start < $1.start
      }
    }
  }

  func deleteActivities(in interval: DateInterval) throws {
    let start = interval.start.epochMilliseconds
    let end = interval.end.epochMilliseconds
    try pool.write { db in
      try db.execute(
        sql: "DELETE FROM manual_entries WHERE start_ms < ? AND end_ms > ?",
        arguments: [end, start]
      )
      try db.execute(
        sql: "DELETE FROM activity_segments WHERE start_ms < ? AND end_ms > ?",
        arguments: [end, start]
      )
    }
  }

  func deleteAllActivities() throws {
    try pool.write { db in
      try db.execute(sql: "DELETE FROM manual_entries")
      try db.execute(sql: "DELETE FROM activity_segments")
    }
  }
}

private func timelineSortRank(_ item: TimelineItem) -> Int {
  switch item {
  case .automatic: 0
  case .manual: 1
  }
}
