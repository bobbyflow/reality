import Foundation

enum TimelineBlockOrigin: String, Equatable, Sendable {
  case automatic
  case manual
}

struct TimelineBlock: Identifiable, Equatable, Sendable {
  let id: UUID
  let sourceID: UUID
  let start: Date
  let end: Date
  let origin: TimelineBlockOrigin
  let title: String?
  let appBundleID: String?
  let appName: String?
  let state: ActivityState
  let category: ActivityCategory?
  let timezoneID: String
}

struct TimelineProjector: Sendable {
  func project(
    automatic: [ActivitySegment], manual: [ManualEntry]
  ) -> [TimelineBlock] {
    let validAutomatic = automatic.filter { $0.end > $0.start }
    let validManual = manual.filter { $0.end > $0.start }
    let boundaries = Set(
      validAutomatic.flatMap { [$0.start, $0.end] }
        + validManual.flatMap { [$0.start, $0.end] }
    ).sorted()
    guard boundaries.count > 1 else { return [] }

    var blocks: [TimelineBlock] = []
    for index in 0..<(boundaries.count - 1) {
      let start = boundaries[index]
      let end = boundaries[index + 1]
      guard start < end else { continue }

      let block: TimelineBlock?
      if let entry = manualWinner(validManual, start: start, end: end) {
        block = makeManualBlock(entry, start: start, end: end)
      } else if let segment = automaticWinner(validAutomatic, start: start, end: end) {
        block = makeAutomaticBlock(segment, start: start, end: end)
      } else {
        block = nil
      }
      guard let block else { continue }
      if let last = blocks.last, canMerge(last, block) {
        blocks[blocks.count - 1] = extending(last, to: block.end)
      } else {
        blocks.append(block)
      }
    }
    return blocks
  }

  private func manualWinner(
    _ entries: [ManualEntry], start: Date, end: Date
  ) -> ManualEntry? {
    entries
      .filter { $0.start < end && $0.end > start }
      .sorted {
        if $0.updatedAt != $1.updatedAt { return $0.updatedAt > $1.updatedAt }
        return $0.id.uuidString < $1.id.uuidString
      }
      .first
  }

  private func automaticWinner(
    _ segments: [ActivitySegment], start: Date, end: Date
  ) -> ActivitySegment? {
    segments
      .filter { $0.start < end && $0.end > start }
      .sorted {
        if $0.start != $1.start { return $0.start < $1.start }
        return $0.id.uuidString < $1.id.uuidString
      }
      .first
  }

  private func makeManualBlock(
    _ entry: ManualEntry, start: Date, end: Date
  ) -> TimelineBlock {
    TimelineBlock(
      id: blockID(sourceID: entry.id, origin: .manual, start: start, end: end),
      sourceID: entry.id,
      start: start,
      end: end,
      origin: .manual,
      title: entry.title,
      appBundleID: nil,
      appName: nil,
      state: .active,
      category: entry.category,
      timezoneID: entry.timezoneID
    )
  }

  private func makeAutomaticBlock(
    _ segment: ActivitySegment, start: Date, end: Date
  ) -> TimelineBlock {
    let storesIdentity = segment.state == .active
    return TimelineBlock(
      id: blockID(sourceID: segment.id, origin: .automatic, start: start, end: end),
      sourceID: segment.id,
      start: start,
      end: end,
      origin: .automatic,
      title: nil,
      appBundleID: storesIdentity ? segment.appBundleID : nil,
      appName: storesIdentity ? segment.appName : nil,
      state: segment.state,
      category: segment.category,
      timezoneID: segment.timezoneID
    )
  }

  private func canMerge(_ lhs: TimelineBlock, _ rhs: TimelineBlock) -> Bool {
    lhs.end == rhs.start
      && lhs.sourceID == rhs.sourceID
      && lhs.origin == rhs.origin
      && lhs.title == rhs.title
      && lhs.appBundleID == rhs.appBundleID
      && lhs.appName == rhs.appName
      && lhs.state == rhs.state
      && lhs.category == rhs.category
      && lhs.timezoneID == rhs.timezoneID
  }

  private func extending(_ block: TimelineBlock, to end: Date) -> TimelineBlock {
    TimelineBlock(
      id: blockID(sourceID: block.sourceID, origin: block.origin, start: block.start, end: end),
      sourceID: block.sourceID,
      start: block.start,
      end: end,
      origin: block.origin,
      title: block.title,
      appBundleID: block.appBundleID,
      appName: block.appName,
      state: block.state,
      category: block.category,
      timezoneID: block.timezoneID
    )
  }

  private func blockID(
    sourceID: UUID, origin: TimelineBlockOrigin, start: Date, end: Date
  ) -> UUID {
    StableIdentifier.make([
      sourceID.uuidString, origin.rawValue, String(start.epochMilliseconds),
      String(end.epochMilliseconds),
    ])
  }
}
