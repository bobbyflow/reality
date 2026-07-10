import SwiftUI

struct PrivacySettingsView: View {
  var body: some View {
    Form {
      LabeledContent("Application identity") { Text("Stored locally") }
      LabeledContent("Window titles") { Text("Not collected") }
      LabeledContent("Screenshots") { Text("Never collected") }
      LabeledContent("Keystrokes") { Text("Never collected") }
      LabeledContent("Cloud upload") { Text("Disabled") }
      Text("Away labels describe your own time and stay on this Mac.")
        .font(.caption).foregroundStyle(.secondary)
    }
    .formStyle(.grouped)
  }
}
