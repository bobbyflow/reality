import AppKit
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let logger = Logger(subsystem: "com.bobbyflow.reality", category: "Lifecycle")
  private var databaseManager: DatabaseManager?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
    do {
      databaseManager = try DatabaseManager.live()
      logger.info("Local database ready")
    } catch {
      logger.error("Local database unavailable")
    }
    logger.info("Reality launched")
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }
}
