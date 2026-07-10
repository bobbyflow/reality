import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
  private let todayStore: TodayStore
  private let reviewStore: ReviewStore
  private(set) var confirmationMessage: String?

  init(todayStore: TodayStore, reviewStore: ReviewStore) {
    self.todayStore = todayStore
    self.reviewStore = reviewStore
  }

  func deleteToday() {
    do {
      try todayStore.deleteToday()
      reviewStore.prepare(summary: .empty, intention: todayStore.intention)
      confirmationMessage = "Today’s activity was deleted."
    } catch {
      confirmationMessage = "Deletion failed. Your data was not reported as deleted."
    }
  }

  func deleteEverything() {
    do {
      try todayStore.deleteAll()
      reviewStore.clear()
      confirmationMessage = "All recorded activity was deleted."
    } catch {
      confirmationMessage = "Deletion failed. Your data was not reported as deleted."
    }
  }

  func exportToday(to url: URL) {
    do {
      try todayStore.exportCSV(to: url)
      confirmationMessage = "Today’s timeline was exported."
    } catch {
      confirmationMessage = "Export failed."
    }
  }
}
