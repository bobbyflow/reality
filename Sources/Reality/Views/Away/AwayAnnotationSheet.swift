import SwiftUI

struct AwayAnnotationSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var store: TodayStore
  let block: TimelineBlock
  @State private var label = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("What happened while away?").font(.title2.bold())
      Text("Reality records the duration, not what happened away from your Mac.")
        .foregroundStyle(.secondary)
      Picker("Label", selection: $label) {
        Text("Choose…").tag("")
        Text("Lunch").tag("Lunch")
        Text("Break").tag("Break")
        Text("Meeting").tag("Meeting")
        Text("Exercise").tag("Exercise")
        Text("Personal").tag("Personal")
      }
      HStack {
        Spacer()
        Button("Cancel") { dismiss() }
        Button("Save") {
          store.annotateAway(sourceID: block.sourceID, label: label)
          dismiss()
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(24)
    .frame(width: 420)
    .onAppear { label = store.awayAnnotations[block.sourceID] ?? "" }
  }
}
