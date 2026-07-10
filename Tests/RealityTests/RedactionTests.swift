import Foundation
import Testing

@testable import Reality

@Suite("Storage and redaction hardening")
struct RedactionTests {
  @Test("rejects a database path through a symbolic-link directory")
  func rejectsSymlinkStorage() throws {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("RealityPathTests-\(UUID().uuidString)", isDirectory: true)
    let actual = root.appendingPathComponent("actual", isDirectory: true)
    let alias = root.appendingPathComponent("alias", isDirectory: true)
    try FileManager.default.createDirectory(at: actual, withIntermediateDirectories: true)
    try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: actual)

    #expect(throws: DatabaseManagerError.unsafeStoragePath) {
      _ = try DatabaseManager(databaseURL: alias.appendingPathComponent("reality.sqlite"))
    }
  }

  @Test("corrupt SQLite never initializes as a healthy database")
  func rejectsCorruption() throws {
    let fixture = try DatabaseFixture()
    try Data("not sqlite".utf8).write(to: fixture.databaseURL)

    #expect(throws: (any Error).self) {
      _ = try DatabaseManager(databaseURL: fixture.databaseURL)
    }
  }
}
