import SwiftUI

struct SidebarView: View {
  @Binding var selection: NavigationSection

  var body: some View {
    List(NavigationSection.allCases, selection: $selection) { section in
      Label(section.title, systemImage: section.systemImage)
        .tag(section)
        .padding(.vertical, 4)
    }
    .listStyle(.sidebar)
    .navigationTitle("Reality")
    .safeAreaInset(edge: .bottom) {
      VStack(alignment: .leading, spacing: 5) {
        Label("Private on this Mac", systemImage: "lock.fill")
          .font(.caption.weight(.semibold))
        Text("No account · No cloud")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
    }
  }
}
