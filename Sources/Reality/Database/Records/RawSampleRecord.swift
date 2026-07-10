import Foundation
import GRDB

struct RawSampleRecord: Codable, FetchableRecord, PersistableRecord {
  static let databaseTableName = "raw_samples"

  let id: String
  let runID: String?
  let startMilliseconds: Int64
  let endMilliseconds: Int64
  let monotonicDurationMilliseconds: Int64
  let appBundleID: String?
  let appName: String?
  let state: String
  let quality: String
  let reason: String
  let timezoneID: String
  let createdAtMilliseconds: Int64

  enum CodingKeys: String, CodingKey {
    case id
    case runID = "run_id"
    case startMilliseconds = "start_ms"
    case endMilliseconds = "end_ms"
    case monotonicDurationMilliseconds = "monotonic_duration_ms"
    case appBundleID = "app_bundle_id"
    case appName = "app_name"
    case state
    case quality
    case reason
    case timezoneID = "timezone_id"
    case createdAtMilliseconds = "created_at_ms"
  }

  init(_ evidence: CollectorEvidence, runID: UUID? = nil) {
    let storesIdentity = evidence.state != .excluded
    id = UUID().uuidString
    self.runID = runID?.uuidString
    startMilliseconds = evidence.start.epochMilliseconds
    endMilliseconds = evidence.end.epochMilliseconds
    monotonicDurationMilliseconds = Int64((evidence.monotonicDuration * 1_000).rounded())
    appBundleID = storesIdentity ? evidence.application?.bundleIdentifier : nil
    appName = storesIdentity ? evidence.application?.displayName : nil
    state = evidence.state.rawValue
    quality = evidence.quality.rawValue
    reason = evidence.reason.rawValue
    timezoneID = evidence.timezoneID
    createdAtMilliseconds = Date.now.epochMilliseconds
  }

  func domainValue() throws -> CollectorEvidence {
    guard let evidenceState = CollectorEvidenceState(rawValue: state) else {
      throw CollectorEvidenceRepositoryError.corruptValue(state)
    }
    guard let evidenceQuality = EvidenceQuality(rawValue: quality) else {
      throw CollectorEvidenceRepositoryError.corruptValue(quality)
    }
    guard let evidenceReason = CollectorEvidenceReason(rawValue: reason) else {
      throw CollectorEvidenceRepositoryError.corruptValue(reason)
    }
    let application = appBundleID.map {
      ForegroundApplication(bundleIdentifier: $0, displayName: appName ?? $0)
    }
    return CollectorEvidence(
      start: startMilliseconds.dateFromEpochMilliseconds,
      end: endMilliseconds.dateFromEpochMilliseconds,
      monotonicDuration: Double(monotonicDurationMilliseconds) / 1_000,
      application: application,
      state: evidenceState,
      quality: evidenceQuality,
      reason: evidenceReason,
      timezoneID: timezoneID
    )
  }
}
