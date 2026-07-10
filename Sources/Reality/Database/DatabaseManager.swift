import Foundation
import GRDB

enum DatabaseManagerError: Error, Equatable {
  case unsafeStoragePath
}

final class DatabaseManager {
  let pool: DatabasePool
  let databaseURL: URL

  init(databaseURL: URL) throws {
    self.databaseURL = databaseURL
    pool = try Self.makePool(at: databaseURL)
    try Migrations.makeMigrator().migrate(pool)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o600],
      ofItemAtPath: databaseURL.path
    )
  }

  static func live() throws -> DatabaseManager {
    try DatabaseManager(databaseURL: applicationSupportDatabaseURL())
  }

  static func applicationSupportDatabaseURL(
    fileManager: FileManager = .default
  ) throws -> URL {
    let applicationSupport = try fileManager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    return
      applicationSupport
      .appendingPathComponent("Reality", isDirectory: true)
      .appendingPathComponent("reality.sqlite")
  }

  static func makePool(at databaseURL: URL) throws -> DatabasePool {
    let directoryURL = databaseURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o700]
    )
    let directoryValues = try directoryURL.resourceValues(forKeys: [
      .isDirectoryKey, .isSymbolicLinkKey,
    ])
    guard directoryValues.isDirectory == true, directoryValues.isSymbolicLink != true else {
      throw DatabaseManagerError.unsafeStoragePath
    }
    if FileManager.default.fileExists(atPath: databaseURL.path) {
      let databaseValues = try databaseURL.resourceValues(forKeys: [
        .isRegularFileKey, .isSymbolicLinkKey,
      ])
      guard databaseValues.isRegularFile == true, databaseValues.isSymbolicLink != true else {
        throw DatabaseManagerError.unsafeStoragePath
      }
    }
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o700],
      ofItemAtPath: directoryURL.path
    )

    var configuration = Configuration()
    configuration.label = "Reality"
    configuration.prepareDatabase { db in
      try db.execute(sql: "PRAGMA foreign_keys = ON")
      try db.execute(sql: "PRAGMA busy_timeout = 5000")
      try db.execute(sql: "PRAGMA secure_delete = ON")
    }
    return try DatabasePool(path: databaseURL.path, configuration: configuration)
  }
}
