import Foundation

enum RetentionServiceError: Error, Equatable {
  case invalidRetentionDays
}

struct RetentionService {
  private let repository: any CollectorEvidenceRepository

  init(repository: any CollectorEvidenceRepository) {
    self.repository = repository
  }

  func prune(retentionDays: Int, now: Date = .now) throws -> Int {
    guard (1...365).contains(retentionDays) else {
      throw RetentionServiceError.invalidRetentionDays
    }
    let cutoff = now.addingTimeInterval(-TimeInterval(retentionDays) * 86_400)
    return try repository.deleteEvidence(endingBefore: cutoff)
  }
}
