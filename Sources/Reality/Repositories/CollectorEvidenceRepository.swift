import Foundation

protocol CollectorEvidenceRepository: Sendable {
  func append(_ evidence: CollectorEvidence) throws
  func fetch(in interval: DateInterval) throws -> [CollectorEvidence]
}

enum CollectorEvidenceRepositoryError: Error, Equatable {
  case invalidInterval
  case invalidDuration
  case corruptValue(String)
}
