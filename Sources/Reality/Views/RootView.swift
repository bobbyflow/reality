import SwiftUI

struct RootView: View {
  @Bindable var model: AppModel

  var body: some View {
    NavigationSplitView {
      SidebarView(selection: $model.selection)
    } detail: {
      switch model.selection {
      case .today:
        TodayView(model: model)
      case .review:
        PendingEvidenceView(
          title: "Review",
          message: "Your review will appear after Reality records real activity.",
          systemImage: "list.bullet.rectangle"
        )
      case .patterns:
        PendingEvidenceView(
          title: "Patterns",
          message: "Patterns require several real days. Reality will not invent them.",
          systemImage: "chart.line.uptrend.xyaxis"
        )
      }
    }
    .navigationSplitViewStyle(.balanced)
    .tint(Color(red: 0.09, green: 0.52, blue: 0.42))
  }
}
