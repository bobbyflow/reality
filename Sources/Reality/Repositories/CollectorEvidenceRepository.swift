import Foundation

protocol CollectorEvidenceRepository: Sendable {
  func append(_ evidence: CollectorEvidence) throws
  func fetch(in interval: DateInterval) throws -> [CollectorEvidence]
  func deleteEvidence(in interval: DateInterval) throws
  func deleteEvidence(endingBefore cutoff: Date) throws -> Int
  func deleteAllEvidence() throws
}

enum CollectorEvidenceRepositoryError: Error, Equatable {
  case invalidInterval
  case invalidDuration
  case corruptValue(String)
}
