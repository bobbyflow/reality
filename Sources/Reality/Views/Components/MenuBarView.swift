import AppKit
import SwiftUI

struct MenuBarView: View {
  @Bindable var model: AppModel
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Label(model.collectorStatus.title, systemImage: model.collectorStatus.systemImage)
      .foregroundStyle(.secondary)

    Divider()

    Button("Open Reality") {
      openWindow(id: "main")
      NSApp.activate(ignoringOtherApps: true)
    }
    .keyboardShortcut("r", modifiers: [.command, .shift])

    Button(model.collectorStatus == .paused ? "Resume tracking" : "Pause tracking") {
      model.togglePause()
    }
    .disabled(!model.canTogglePause)

    Button("Add activity") {}
      .disabled(true)

    Divider()

    SettingsLink {
      Text("Settings…")
    }

    Button("Quit Reality") {
      NSApplication.shared.terminate(nil)
    }
    .keyboardShortcut("q")
  }
}
