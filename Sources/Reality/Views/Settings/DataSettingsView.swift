import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DataSettingsView: View {
  let store: SettingsStore?
  @State private var confirmation: DeletionKind?

  var body: some View {
    Form {
      LabeledContent("Storage") { Text("Private on this Mac") }
      LabeledContent("Raw evidence retention") { Text("14 days") }
      Button("Export today as CSV") { exportToday() }
        .disabled(store == nil)
      Button("Delete today’s activity", role: .destructive) { confirmation = .today }
        .disabled(store == nil)
      Button("Delete all activity", role: .destructive) { confirmation = .everything }
        .disabled(store == nil)
      if let message = store?.confirmationMessage {
        Text(message).font(.caption).foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
    .alert(
      confirmation == .everything ? "Delete all activity?" : "Delete today’s activity?",
      isPresented: Binding(
        get: { confirmation != nil },
        set: { if !$0 { confirmation = nil } }
      )
    ) {
      Button("Cancel", role: .cancel) { confirmation = nil }
      Button("Delete", role: .destructive) {
        if confirmation == .everything { store?.deleteEverything() } else { store?.deleteToday() }
        confirmation = nil
      }
    } message: {
      Text("This permanently removes the selected local evidence and derived activity.")
    }
  }

  private func exportToday() {
    let panel = NSSavePanel()
    panel.nameFieldStringValue = "Reality-Today.csv"
    panel.allowedContentTypes = [.commaSeparatedText]
    guard panel.runModal() == .OK, let url = panel.url else { return }
    store?.exportToday(to: url)
  }
}

private enum DeletionKind {
  case today
  case everything
}
