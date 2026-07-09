import Foundation
import GRDB

struct ManualEntryRecord: Codable, FetchableRecord, PersistableRecord {
  static let databaseTableName = "manual_entries"

  let id: String
  let startMilliseconds: Int64
  let endMilliseconds: Int64
  let title: String
  let categoryID: String?
  let note: String?
  let timezoneID: String
  let createdAtMilliseconds: Int64
  let updatedAtMilliseconds: Int64

  enum CodingKeys: String, CodingKey {
    case id
    case startMilliseconds = "start_ms"
    case endMilliseconds = "end_ms"
    case title
    case categoryID = "category_id"
    case note
    case timezoneID = "timezone_id"
    case createdAtMilliseconds = "created_at_ms"
    case updatedAtMilliseconds = "updated_at_ms"
  }

  init(_ entry: ManualEntry) {
    id = entry.id.uuidString
    startMilliseconds = entry.start.epochMilliseconds
    endMilliseconds = entry.end.epochMilliseconds
    title = entry.title
    categoryID = entry.category?.rawValue
    note = entry.note
    timezoneID = entry.timezoneID
    createdAtMilliseconds = entry.createdAt.epochMilliseconds
    updatedAtMilliseconds = entry.updatedAt.epochMilliseconds
  }

  func domainValue() throws -> ManualEntry {
    guard let uuid = UUID(uuidString: id) else {
      throw ActivityRepositoryError.corruptIdentifier(id)
    }
    let category = try categoryID.map { value in
      guard let category = ActivityCategory(rawValue: value) else {
        throw ActivityRepositoryError.corruptCategory(value)
      }
      return category
    }
    return ManualEntry(
      id: uuid,
      start: startMilliseconds.dateFromEpochMilliseconds,
      end: endMilliseconds.dateFromEpochMilliseconds,
      title: title,
      category: category,
      note: note,
      timezoneID: timezoneID,
      createdAt: createdAtMilliseconds.dateFromEpochMilliseconds,
      updatedAt: updatedAtMilliseconds.dateFromEpochMilliseconds
    )
  }
}
