import Foundation
import Observation

@MainActor
@Observable
final class TodayStore {
  private let activityRepository: any ActivityRepository
  private let evidenceRepository: any CollectorEvidenceRepository
  private let defaults: UserDefaults
  private let projector = TimelineProjector()
  private let aggregator = DailyAggregator()

  private(set) var blocks: [TimelineBlock] = []
  private(set) var summary: DailySummary = .empty
  private(set) var intention = DailyIntention()
  private(set) var errorMessage: String?
  private(set) var awayAnnotations: [UUID: String] = [:]

  init(
    activityRepository: any ActivityRepository,
    evidenceRepository: any CollectorEvidenceRepository,
    defaults: UserDefaults = .standard
  ) {
    self.activityRepository = activityRepository
    self.evidenceRepository = evidenceRepository
    self.defaults = defaults
    loadIntention()
  }

  func reload(now: Date = .now, timezone: TimeZone = .current) throws {
    let interval = try dayInterval(now: now, timezone: timezone)
    let items = try activityRepository.fetchTimeline(in: interval)
    let automatic = items.compactMap { item -> ActivitySegment? in
      if case .automatic(let segment) = item { return segment }
      return nil
    }
    let manual = items.compactMap { item -> ManualEntry? in
      if case .manual(let entry) = item { return entry }
      return nil
    }
    blocks = projector.project(automatic: automatic, manual: manual)
    summary = aggregator.summarize(blocks, in: interval)
    awayAnnotations = blocks.reduce(into: [:]) { annotations, block in
      if let label = defaults.string(forKey: annotationKey(block.sourceID)) {
        annotations[block.sourceID] = label
      }
    }
    errorMessage = nil
  }

  func saveIntention(essential: String, optionalOutcomes: [String]) {
    intention = DailyIntention(
      essential: essential.trimmingCharacters(in: .whitespacesAndNewlines),
      optionalOutcomes: optionalOutcomes.map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
      }.filter { !$0.isEmpty }
    )
    defaults.set(intention.essential, forKey: "today.essential")
    defaults.set(intention.optionalOutcomes, forKey: "today.optional")
  }

  func addManualActivity(
    title: String, start: Date, end: Date, category: ActivityCategory?
  ) throws {
    let now = Date.now
    try activityRepository.save(
      manualEntry: ManualEntry(
        id: UUID(), start: start, end: end, title: title, category: category, note: nil,
        timezoneID: TimeZone.current.identifier, createdAt: now, updatedAt: now))
    try reload()
  }

  func annotateAway(sourceID: UUID, label: String) {
    let cleaned = label.trimmingCharacters(in: .whitespacesAndNewlines)
    if cleaned.isEmpty {
      defaults.removeObject(forKey: annotationKey(sourceID))
      awayAnnotations.removeValue(forKey: sourceID)
    } else {
      defaults.set(cleaned, forKey: annotationKey(sourceID))
      awayAnnotations[sourceID] = cleaned
    }
  }

  func deleteToday(now: Date = .now, timezone: TimeZone = .current) throws {
    let interval = try dayInterval(now: now, timezone: timezone)
    try evidenceRepository.deleteEvidence(in: interval)
    try activityRepository.deleteActivities(in: interval)
    blocks = []
    summary = .empty
  }

  func deleteAll() throws {
    try evidenceRepository.deleteAllEvidence()
    try activityRepository.deleteAllActivities()
    blocks = []
    summary = .empty
    intention = DailyIntention()
    defaults.removeObject(forKey: "today.essential")
    defaults.removeObject(forKey: "today.optional")
    defaults.removeObject(forKey: "review.correction")
    for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("away.annotation.") {
      defaults.removeObject(forKey: key)
    }
    awayAnnotations = [:]
  }

  func exportCSV(to url: URL) throws {
    var lines = ["start,end,origin,title,state,category,duration_seconds"]
    lines += blocks.map { block in
      [
        block.start.ISO8601Format(), block.end.ISO8601Format(), block.origin.rawValue,
        awayAnnotations[block.sourceID] ?? block.title ?? block.appName ?? "", block.state.rawValue,
        block.category?.rawValue ?? "",
        String(Int(block.end.timeIntervalSince(block.start))),
      ].map(csvField).joined(separator: ",")
    }
    try (lines.joined(separator: "\n") + "\n").write(
      to: url, atomically: true, encoding: .utf8)
  }

  func record(error: Error) {
    errorMessage = "Reality could not refresh local activity."
  }

  private func loadIntention() {
    intention = DailyIntention(
      essential: defaults.string(forKey: "today.essential") ?? "",
      optionalOutcomes: defaults.stringArray(forKey: "today.optional") ?? [])
  }

  private func annotationKey(_ id: UUID) -> String {
    "away.annotation.\(id.uuidString)"
  }

  private func csvField(_ value: String) -> String {
    "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
  }

  private func dayInterval(now: Date, timezone: TimeZone) throws -> DateInterval {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timezone
    guard let interval = calendar.dateInterval(of: .day, for: now) else {
      throw TodayStoreError.invalidDay
    }
    return interval
  }
}

enum TodayStoreError: Error {
  case invalidDay
}
