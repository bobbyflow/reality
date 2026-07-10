import Foundation
import Testing

@testable import Reality

@Suite("Safe export")
struct ExportTests {
  @Test("exports bounded CSV with formula neutralization and quote escaping")
  func safeCSV() throws {
    let fixture = try ExportFixture()
    let destination = fixture.directory.appendingPathComponent("today.csv")
    let start = Date(timeIntervalSince1970: 100)
    let block = TimelineBlock(
      id: UUID(), sourceID: UUID(), start: start, end: start.addingTimeInterval(60),
      origin: .manual, title: "\t=HYPERLINK(\"bad\")", appBundleID: nil, appName: nil,
      state: .active, category: .focus, timezoneID: "UTC")

    try ExportService().export(blocks: [block], awayAnnotations: [:], to: destination)

    let csv = try String(contentsOf: destination, encoding: .utf8)
    #expect(csv.contains("'\t=HYPERLINK(\"\"bad\"\")"))
    #expect(csv.contains("duration_seconds"))
    #expect((try destination.resourceValues(forKeys: [.isRegularFileKey])).isRegularFile == true)
  }

  @Test("excluded blocks never export identifying metadata")
  func redactsExcluded() throws {
    let fixture = try ExportFixture()
    let destination = fixture.directory.appendingPathComponent("excluded.csv")
    let start = Date(timeIntervalSince1970: 200)
    let block = TimelineBlock(
      id: UUID(), sourceID: UUID(), start: start, end: start.addingTimeInterval(60),
      origin: .automatic, title: nil, appBundleID: "secret.bundle", appName: "Secret App",
      state: .excluded, category: nil, timezoneID: "UTC")

    try ExportService().export(blocks: [block], awayAnnotations: [:], to: destination)

    let csv = try String(contentsOf: destination, encoding: .utf8)
    #expect(!csv.contains("secret.bundle"))
    #expect(!csv.contains("Secret App"))
  }

  @Test("refuses symlink destinations")
  func symlinkDefense() throws {
    let fixture = try ExportFixture()
    let target = fixture.directory.appendingPathComponent("target.csv")
    let link = fixture.directory.appendingPathComponent("link.csv")
    try "untouched".write(to: target, atomically: true, encoding: .utf8)
    try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

    #expect(throws: ExportServiceError.unsafeDestination) {
      try ExportService().export(blocks: [], awayAnnotations: [:], to: link)
    }
    #expect(try String(contentsOf: target, encoding: .utf8) == "untouched")
  }
}

private struct ExportFixture {
  let directory: URL

  init() throws {
    directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("RealityExportTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }
}
