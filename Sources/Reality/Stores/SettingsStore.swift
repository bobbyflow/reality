import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
  private let todayStore: TodayStore
  private let reviewStore: ReviewStore
  private let loginItemService: LoginItemService
  private let defaults: UserDefaults
  private let updateExclusions: (Set<String>) -> Void
  private(set) var confirmationMessage: String?
  private(set) var isLoginEnabled: Bool
  private(set) var excludedBundleIDs: [String]

  init(
    todayStore: TodayStore,
    reviewStore: ReviewStore,
    loginItemService: LoginItemService = LoginItemService(),
    defaults: UserDefaults = .standard,
    updateExclusions: @escaping (Set<String>) -> Void = { _ in }
  ) {
    self.todayStore = todayStore
    self.reviewStore = reviewStore
    self.loginItemService = loginItemService
    self.defaults = defaults
    self.updateExclusions = updateExclusions
    isLoginEnabled = loginItemService.isEnabled
    excludedBundleIDs = (defaults.stringArray(forKey: "privacy.excludedBundleIDs") ?? []).sorted()
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
      excludedBundleIDs = []
      defaults.removeObject(forKey: "privacy.excludedBundleIDs")
      updateExclusions([])
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

  func setLoginEnabled(_ enabled: Bool) {
    do {
      try loginItemService.setEnabled(enabled)
      isLoginEnabled = loginItemService.isEnabled
      confirmationMessage = enabled ? "Reality will start at login." : "Start at login disabled."
    } catch {
      isLoginEnabled = loginItemService.isEnabled
      confirmationMessage = "macOS could not update the login-item setting."
    }
  }

  func addExcludedBundleID(_ value: String) {
    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    let allowed = cleaned.allSatisfy { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" }
    guard allowed, cleaned.contains("."), cleaned.count <= 255 else {
      confirmationMessage = "Enter a valid bundle identifier, such as com.example.app."
      return
    }
    excludedBundleIDs = Array(Set(excludedBundleIDs + [cleaned])).sorted()
    defaults.set(excludedBundleIDs, forKey: "privacy.excludedBundleIDs")
    updateExclusions(Set(excludedBundleIDs))
    confirmationMessage = "Excluded applications retain duration only."
  }

  func removeExcludedBundleID(_ value: String) {
    excludedBundleIDs.removeAll { $0 == value }
    defaults.set(excludedBundleIDs, forKey: "privacy.excludedBundleIDs")
    updateExclusions(Set(excludedBundleIDs))
  }
}
