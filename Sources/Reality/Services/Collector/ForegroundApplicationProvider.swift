import AppKit

@MainActor
protocol ForegroundApplicationProviding: AnyObject {
  func currentApplication() -> ForegroundApplication?
}

@MainActor
final class ForegroundApplicationProvider: ForegroundApplicationProviding {
  func currentApplication() -> ForegroundApplication? {
    guard
      let application = NSWorkspace.shared.frontmostApplication,
      let bundleIdentifier = application.bundleIdentifier
    else {
      return nil
    }
    return ForegroundApplication(
      bundleIdentifier: bundleIdentifier,
      displayName: application.localizedName ?? bundleIdentifier
    )
  }
}
