import SwiftUI

struct PendingEvidenceView: View {
  let title: String
  let message: String
  let systemImage: String

  var body: some View {
    ContentUnavailableView {
      Label(title, systemImage: systemImage)
    } description: {
      Text(message)
    }
    .navigationTitle(title)
  }
}
