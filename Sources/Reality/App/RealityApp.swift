import AppKit
import SwiftUI

@main
@MainActor
struct RealityApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @State private var model: AppModel

  init() {
    let model = AppModel.live()
    model.startCollector()
    _model = State(initialValue: model)
  }

  var body: some Scene {
    WindowGroup("Reality", id: "main") {
      RootView(model: model)
        .frame(minWidth: 900, minHeight: 620)
    }
    .defaultSize(width: 1_180, height: 760)
    .commands {
      CommandGroup(after: .appSettings) {
        Button("Show Reality") {
          NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("r", modifiers: [.command, .shift])
      }
    }

    MenuBarExtra("Reality", systemImage: model.collectorStatus.systemImage) {
      MenuBarView(model: model)
    }

    Settings {
      SettingsView(store: model.settingsStore)
    }
  }
}
