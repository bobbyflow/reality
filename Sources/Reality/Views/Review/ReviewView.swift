import SwiftUI

struct ReviewView: View {
  @Bindable var store: ReviewStore
  @State private var correction = ""
  @State private var message: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        Text("Review").font(.system(size: 38, weight: .bold, design: .serif))
        if store.isReady {
          RealityCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("PLANNED VS ACTUAL").realityEyebrow()
              Text(store.plannedVersusActual ?? "No essential outcome was set.")
                .font(.headline)
              if let leak = store.recoverableLeak {
                Text("Largest recoverable leak: \(Int(leak.duration / 60)) minutes")
                  .foregroundStyle(.secondary)
              } else {
                Text("No recoverable drift block was identified.").foregroundStyle(.secondary)
              }
            }
          }
          RealityCard(tint: Color.green.opacity(0.08)) {
            VStack(alignment: .leading, spacing: 12) {
              Text("ONE CORRECTION FOR TOMORROW").realityEyebrow()
              TextField("A concrete behaviour, not a wish", text: $correction)
              Button("Save correction") {
                do {
                  try store.setCorrection(correction)
                  message = "Saved. Reality will show only this correction."
                } catch { message = "Write one concrete correction." }
              }
              .disabled(correction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
              if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
            }
          }
        } else {
          ContentUnavailableView(
            "Not enough evidence", systemImage: "hourglass",
            description: Text(
              "Reality waits for 30 minutes of active evidence before reviewing your day."))
        }
      }
      .frame(maxWidth: 900, alignment: .leading)
      .padding(32)
    }
    .navigationTitle("Review")
    .onAppear { correction = store.correction ?? "" }
  }
}
