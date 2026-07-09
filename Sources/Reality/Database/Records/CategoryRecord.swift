import GRDB

struct CategoryRecord: Codable, FetchableRecord, PersistableRecord {
  static let databaseTableName = "categories"

  let id: String
  let name: String
  let colorHex: String
  let kind: String

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case colorHex = "color_hex"
    case kind
  }
}
