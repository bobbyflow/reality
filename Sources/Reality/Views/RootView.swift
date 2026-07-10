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
        if let store = model.reviewStore {
          ReviewView(store: store)
        } else {
          PendingEvidenceView(
            title: "Review", message: "The local evidence store is unavailable.",
            systemImage: "exclamationmark.triangle")
        }
      case .patterns:
        PatternsView(summary: model.todayStore?.summary ?? .empty)
      }
    }
    .navigationSplitViewStyle(.balanced)
    .tint(Color(red: 0.09, green: 0.52, blue: 0.42))
  }
}
