import Foundation

struct Segmenter: Sendable {
  let derivationVersion: Int

  init(derivationVersion: Int = 1) {
    precondition(derivationVersion > 0)
    self.derivationVersion = derivationVersion
  }

  func process<S: Sequence>(evidence: S) -> [ActivitySegment]
  where S.Element == CollectorEvidence {
    let ordered =
      evidence
      .filter { $0.end > $0.start && $0.monotonicDuration > 0 }
      .sorted(by: evidenceOrder)
    var coveredUntil: Date?
    var normalized: [SegmentCandidate] = []

    for item in ordered {
      let start = max(item.start, coveredUntil ?? item.start)
      guard start < item.end else { continue }
      let candidate = candidate(from: item, start: start)
      if let last = normalized.last, last.canMerge(with: candidate) {
        normalized[normalized.count - 1] = last.extending(to: candidate.end)
      } else {
        normalized.append(candidate)
      }
      coveredUntil = max(coveredUntil ?? item.end, item.end)
    }

    return normalized.flatMap(splitAtLocalMidnight).map(makeSegment)
  }

  private func evidenceOrder(_ lhs: CollectorEvidence, _ rhs: CollectorEvidence) -> Bool {
    if lhs.start != rhs.start { return lhs.start < rhs.start }
    if lhs.end != rhs.end { return lhs.end < rhs.end }
    return evidenceKey(lhs) < evidenceKey(rhs)
  }

  private func evidenceKey(_ item: CollectorEvidence) -> String {
    [
      item.application?.bundleIdentifier ?? "", item.application?.displayName ?? "",
      item.state.rawValue, item.quality.rawValue, item.reason.rawValue, item.timezoneID,
    ].joined(separator: "|")
  }

  private func candidate(from evidence: CollectorEvidence, start: Date) -> SegmentCandidate {
    let mappedState = state(for: evidence)
    let storesIdentity = mappedState != .excluded && mappedState == .active
    return SegmentCandidate(
      start: start,
      end: evidence.end,
      appBundleID: storesIdentity ? evidence.application?.bundleIdentifier : nil,
      appName: storesIdentity ? evidence.application?.displayName : nil,
      state: mappedState,
      quality: evidence.quality,
      timezoneID: evidence.timezoneID
    )
  }

  private func state(for evidence: CollectorEvidence) -> ActivityState {
    switch evidence.state {
    case .active: evidence.application == nil ? .unknown : .active
    case .away: .away
    case .unknown: .unknown
    case .excluded: .excluded
    case .paused: .paused
    }
  }

  private func splitAtLocalMidnight(_ candidate: SegmentCandidate) -> [SegmentCandidate] {
    guard let timezone = TimeZone(identifier: candidate.timezoneID) else { return [candidate] }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timezone
    var cursor = candidate.start
    var pieces: [SegmentCandidate] = []

    while cursor < candidate.end {
      let dayEnd = calendar.dateInterval(of: .day, for: cursor)?.end ?? candidate.end
      let end = min(dayEnd, candidate.end)
      guard end > cursor else { break }
      pieces.append(candidate.clipped(from: cursor, to: end))
      cursor = end
    }
    return pieces
  }

  private func makeSegment(_ candidate: SegmentCandidate) -> ActivitySegment {
    let id = StableIdentifier.make([
      String(candidate.start.epochMilliseconds), String(candidate.end.epochMilliseconds),
      candidate.appBundleID ?? "", candidate.appName ?? "", candidate.state.rawValue,
      candidate.quality.rawValue, candidate.timezoneID, String(derivationVersion),
    ])
    return ActivitySegment(
      id: id,
      start: candidate.start,
      end: candidate.end,
      appBundleID: candidate.appBundleID,
      appName: candidate.appName,
      state: candidate.state,
      source: .automatic,
      quality: candidate.quality,
      category: nil,
      timezoneID: candidate.timezoneID,
      derivationVersion: derivationVersion
    )
  }
}

private struct SegmentCandidate {
  let start: Date
  let end: Date
  let appBundleID: String?
  let appName: String?
  let state: ActivityState
  let quality: EvidenceQuality
  let timezoneID: String

  func canMerge(with other: SegmentCandidate) -> Bool {
    end == other.start
      && appBundleID == other.appBundleID
      && appName == other.appName
      && state == other.state
      && quality == other.quality
      && timezoneID == other.timezoneID
  }

  func extending(to end: Date) -> SegmentCandidate {
    clipped(from: start, to: end)
  }

  func clipped(from start: Date, to end: Date) -> SegmentCandidate {
    SegmentCandidate(
      start: start, end: end, appBundleID: appBundleID, appName: appName, state: state,
      quality: quality, timezoneID: timezoneID)
  }
}
