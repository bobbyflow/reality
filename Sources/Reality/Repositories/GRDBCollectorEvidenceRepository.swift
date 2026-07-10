import Foundation
import GRDB

final class GRDBCollectorEvidenceRepository: CollectorEvidenceRepository, @unchecked Sendable {
  private let pool: DatabasePool

  init(pool: DatabasePool) {
    self.pool = pool
  }

  func append(_ evidence: CollectorEvidence) throws {
    guard evidence.end > evidence.start else {
      throw CollectorEvidenceRepositoryError.invalidInterval
    }
    guard evidence.monotonicDuration > 0 else {
      throw CollectorEvidenceRepositoryError.invalidDuration
    }
    try pool.write { db in
      try RawSampleRecord(evidence).insert(db)
    }
  }

  func fetch(in interval: DateInterval) throws -> [CollectorEvidence] {
    try pool.read { db in
      try RawSampleRecord.fetchAll(
        db,
        sql: """
          SELECT * FROM raw_samples
          WHERE start_ms < ? AND end_ms > ?
          ORDER BY start_ms
          """,
        arguments: [interval.end.epochMilliseconds, interval.start.epochMilliseconds]
      ).map { try $0.domainValue() }
    }
  }
}
