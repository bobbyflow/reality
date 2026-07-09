import Foundation
import GRDB

struct ActivitySegmentRecord: Codable, FetchableRecord, PersistableRecord {
  static let databaseTableName = "activity_segments"

  let id: String
  let startMilliseconds: Int64
  let endMilliseconds: Int64
  let appBundleID: String?
  let appName: String?
  let state: String
  let source: String
  let quality: String
  let categoryID: String?
  let timezoneID: String
  let derivationVersion: Int
  let createdAtMilliseconds: Int64

  enum CodingKeys: String, CodingKey {
    case id
    case startMilliseconds = "start_ms"
    case endMilliseconds = "end_ms"
    case appBundleID = "app_bundle_id"
    case appName = "app_name"
    case state
    case source
    case quality
    case categoryID = "category_id"
    case timezoneID = "timezone_id"
    case derivationVersion = "derivation_version"
    case createdAtMilliseconds = "created_at_ms"
  }

  init(_ segment: ActivitySegment) {
    let storesIdentity = segment.state != .excluded
    id = segment.id.uuidString
    startMilliseconds = segment.start.epochMilliseconds
    endMilliseconds = segment.end.epochMilliseconds
    appBundleID = storesIdentity ? segment.appBundleID : nil
    appName = storesIdentity ? segment.appName : nil
    state = segment.state.rawValue
    source = segment.source.rawValue
    quality = segment.quality.rawValue
    categoryID = storesIdentity ? segment.category?.rawValue : nil
    timezoneID = segment.timezoneID
    derivationVersion = segment.derivationVersion
    createdAtMilliseconds = Date.now.epochMilliseconds
  }

  func domainValue() throws -> ActivitySegment {
    guard let uuid = UUID(uuidString: id) else {
      throw ActivityRepositoryError.corruptIdentifier(id)
    }
    guard let activityState = ActivityState(rawValue: state) else {
      throw ActivityRepositoryError.corruptState(state)
    }
    guard let activitySource = ActivitySource(rawValue: source) else {
      throw ActivityRepositoryError.corruptSource(source)
    }
    guard let evidenceQuality = EvidenceQuality(rawValue: quality) else {
      throw ActivityRepositoryError.corruptQuality(quality)
    }
    let category = try categoryID.map { value in
      guard let category = ActivityCategory(rawValue: value) else {
        throw ActivityRepositoryError.corruptCategory(value)
      }
      return category
    }
    return ActivitySegment(
      id: uuid,
      start: startMilliseconds.dateFromEpochMilliseconds,
      end: endMilliseconds.dateFromEpochMilliseconds,
      appBundleID: appBundleID,
      appName: appName,
      state: activityState,
      source: activitySource,
      quality: evidenceQuality,
      category: category,
      timezoneID: timezoneID,
      derivationVersion: derivationVersion
    )
  }
}
