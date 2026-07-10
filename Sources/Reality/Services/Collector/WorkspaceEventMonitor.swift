import AppKit

@MainActor
final class WorkspaceEventMonitor {
  private(set) var sessionState: CollectorSessionState = .active
  private var observations: [NSObjectProtocol] = []

  func start(onEvent: @escaping @MainActor () -> Void) {
    guard observations.isEmpty else { return }
    let center = NSWorkspace.shared.notificationCenter
    observe(NSWorkspace.didActivateApplicationNotification, center: center, onEvent: onEvent)
    observe(
      NSWorkspace.willSleepNotification, center: center, state: .asleep, onEvent: onEvent)
    observe(NSWorkspace.didWakeNotification, center: center, state: .active, onEvent: onEvent)
    observe(
      NSWorkspace.sessionDidResignActiveNotification, center: center, state: .locked,
      onEvent: onEvent)
    observe(
      NSWorkspace.sessionDidBecomeActiveNotification, center: center, state: .active,
      onEvent: onEvent)
  }

  func stop() {
    let center = NSWorkspace.shared.notificationCenter
    observations.forEach(center.removeObserver)
    observations.removeAll()
  }

  private func observe(
    _ name: Notification.Name,
    center: NotificationCenter,
    state: CollectorSessionState? = nil,
    onEvent: @escaping @MainActor () -> Void
  ) {
    observations.append(
      center.addObserver(forName: name, object: nil, queue: .main) {
        [weak self] _ in
        Task { @MainActor in
          if let state { self?.sessionState = state }
          onEvent()
        }
      })
  }
}
