import SwiftUI

struct SettingsView: View {
  @AppStorage("idleThresholdMinutes") private var idleThresholdMinutes = 5
  @AppStorage("storeWindowTitles") private var storeWindowTitles = false

  var body: some View {
    TabView {
      Form {
        Picker("Away after", selection: $idleThresholdMinutes) {
          Text("3 minutes").tag(3)
          Text("5 minutes").tag(5)
          Text("10 minutes").tag(10)
          Text("15 minutes").tag(15)
        }

        LabeledContent("Start at login") {
          Text("Available with collector")
            .foregroundStyle(.secondary)
        }

        Text("These preferences are local to this Mac.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .formStyle(.grouped)
      .tabItem { Label("General", systemImage: "gearshape") }

      Form {
        Toggle("Store focused window titles", isOn: $storeWindowTitles)
          .disabled(true)
        Text(
          "Not available yet. Window titles can contain document names and message subjects, so app-only tracking remains the default."
        )
        .font(.caption)
        .foregroundStyle(.secondary)

        LabeledContent("Screenshots") {
          Text("Never collected")
            .foregroundStyle(.secondary)
        }
        LabeledContent("Keystrokes") {
          Text("Never collected")
            .foregroundStyle(.secondary)
        }
        LabeledContent("Cloud upload") {
          Text("Disabled")
            .foregroundStyle(.secondary)
        }
      }
      .formStyle(.grouped)
      .tabItem { Label("Privacy", systemImage: "hand.raised") }
    }
    .frame(width: 520, height: 330)
    .scenePadding()
  }
}
