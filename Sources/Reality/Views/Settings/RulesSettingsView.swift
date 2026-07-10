import SwiftUI

struct RulesSettingsView: View {
  var body: some View {
    Form {
      Text("Classification priority")
        .font(.headline)
      LabeledContent("1") { Text("Your correction") }
      LabeledContent("2") { Text("Your future-match rule") }
      LabeledContent("3") { Text("Default rule") }
      LabeledContent("4") { Text("Unknown") }
      Text("Away and excluded time are states, never productivity categories.")
        .font(.caption).foregroundStyle(.secondary)
    }
    .formStyle(.grouped)
  }
}
