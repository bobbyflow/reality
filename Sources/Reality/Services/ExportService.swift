import Darwin
import Foundation

enum ExportServiceError: Error, Equatable {
  case unsafeDestination
  case invalidFileType
  case writeFailed
}

struct ExportService {
  private let fileManager: FileManager

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func export(
    blocks: [TimelineBlock], awayAnnotations: [UUID: String], to destination: URL
  ) throws {
    guard destination.isFileURL, destination.pathExtension.lowercased() == "csv" else {
      throw ExportServiceError.invalidFileType
    }
    let parent = destination.deletingLastPathComponent()
    let parentValues = try parent.resourceValues(forKeys: [
      .isDirectoryKey, .isSymbolicLinkKey,
    ])
    guard parentValues.isDirectory == true, parentValues.isSymbolicLink != true else {
      throw ExportServiceError.unsafeDestination
    }
    if fileManager.fileExists(atPath: destination.path) {
      let values = try destination.resourceValues(forKeys: [
        .isRegularFileKey, .isSymbolicLinkKey,
      ])
      guard values.isRegularFile == true, values.isSymbolicLink != true else {
        throw ExportServiceError.unsafeDestination
      }
    }

    let temporary = parent.appendingPathComponent(".reality-export-\(UUID().uuidString).tmp")
    defer { try? fileManager.removeItem(at: temporary) }
    let data = Data(csv(blocks: blocks, awayAnnotations: awayAnnotations).utf8)
    guard
      fileManager.createFile(
        atPath: temporary.path, contents: data, attributes: [.posixPermissions: 0o600])
    else { throw ExportServiceError.writeFailed }
    guard rename(temporary.path, destination.path) == 0 else {
      throw ExportServiceError.writeFailed
    }
  }

  private func csv(
    blocks: [TimelineBlock], awayAnnotations: [UUID: String]
  ) -> String {
    var lines = ["start,end,origin,title,state,category,duration_seconds"]
    lines += blocks.map { block in
      let storesIdentity = block.state != .excluded
      let title =
        storesIdentity
        ? (awayAnnotations[block.sourceID] ?? block.title ?? block.appName ?? "") : ""
      return [
        block.start.ISO8601Format(), block.end.ISO8601Format(), block.origin.rawValue,
        title, block.state.rawValue, block.category?.rawValue ?? "",
        String(Int(block.end.timeIntervalSince(block.start))),
      ].map(csvField).joined(separator: ",")
    }
    return lines.joined(separator: "\n") + "\n"
  }

  private func csvField(_ value: String) -> String {
    let neutralized: String
    let firstMeaningful = value.first { !$0.isWhitespace && !$0.isNewline }
    if let firstMeaningful, "=+-@".contains(firstMeaningful) {
      neutralized = "'" + value
    } else {
      neutralized = value
    }
    return "\"\(neutralized.replacingOccurrences(of: "\"", with: "\"\""))\""
  }
}
