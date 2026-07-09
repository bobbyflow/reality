import Foundation

enum ActivityRepositoryError: Error, Equatable {
  case invalidInterval
  case invalidTitle
  case invalidDerivationVersion
  case corruptIdentifier(String)
  case corruptCategory(String)
  case corruptState(String)
  case corruptSource(String)
  case corruptQuality(String)
}

protocol ActivityRepository {
  func save(manualEntry: ManualEntry) throws
  func save(segment: ActivitySegment) throws
  func fetchTimeline(in interval: DateInterval) throws -> [TimelineItem]
  func deleteActivities(in interval: DateInterval) throws
  func deleteAllActivities() throws
}
