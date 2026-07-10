import SwiftUI

struct GeneralSettingsView: View {
  let store: SettingsStore?

  var body: some View {
    Form {
      Toggle(
        "Start Reality at login",
        isOn: Binding(
          get: { store?.isLoginEnabled ?? false },
          set: { store?.setLoginEnabled($0) }
        )
      )
      .disabled(store == nil)
      LabeledContent("Away threshold") { Text("5 minutes") }
      LabeledContent("Reconciliation") { Text("Every 5 seconds") }
      if let message = store?.confirmationMessage {
        Text(message).font(.caption).foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }
}
