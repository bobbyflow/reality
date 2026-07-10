import SwiftUI

struct PrivacySettingsView: View {
  let store: SettingsStore?
  @State private var bundleID = ""

  var body: some View {
    Form {
      LabeledContent("Application identity") { Text("Stored locally") }
      LabeledContent("Window titles") { Text("Not collected") }
      LabeledContent("Screenshots") { Text("Never collected") }
      LabeledContent("Keystrokes") { Text("Never collected") }
      LabeledContent("Cloud upload") { Text("Disabled") }
      Section("Excluded applications") {
        HStack {
          TextField("com.example.private-app", text: $bundleID)
          Button("Exclude") {
            store?.addExcludedBundleID(bundleID)
            bundleID = ""
          }
          .disabled(bundleID.isEmpty || store == nil)
        }
        ForEach(store?.excludedBundleIDs ?? [], id: \.self) { id in
          HStack {
            Text(id).font(.system(.caption, design: .monospaced))
            Spacer()
            Button("Remove") { store?.removeExcludedBundleID(id) }
              .buttonStyle(.borderless)
          }
        }
        Text("Excluded applications retain duration only; identity is discarded before storage.")
          .font(.caption).foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }
}
