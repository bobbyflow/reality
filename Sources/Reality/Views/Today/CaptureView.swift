import SwiftUI

struct CaptureView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var store: TodayStore
  @State private var title = ""
  @State private var start = Date.now.addingTimeInterval(-1_800)
  @State private var end = Date.now
  @State private var category: ActivityCategory = .focus
  @State private var errorMessage: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Add activity").font(.title2.bold())
      TextField("What did you do?", text: $title)
      DatePicker("Started", selection: $start)
      DatePicker("Ended", selection: $end)
      Picker("Category", selection: $category) {
        ForEach(ActivityCategory.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
      }
      if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.caption) }
      HStack {
        Spacer()
        Button("Cancel") { dismiss() }
        Button("Save") {
          do {
            try store.addManualActivity(title: title, start: start, end: end, category: category)
            dismiss()
          } catch {
            errorMessage = "Enter a title and a valid time range."
          }
        }
        .keyboardShortcut(.defaultAction)
        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || end <= start)
      }
    }
    .padding(24)
    .frame(width: 430)
  }
}
