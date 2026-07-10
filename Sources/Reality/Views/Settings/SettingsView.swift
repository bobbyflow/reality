import SwiftUI

struct SettingsView: View {
  let store: SettingsStore?

  var body: some View {
    TabView {
      PrivacySettingsView()
        .tabItem { Label("Privacy", systemImage: "hand.raised") }
      RulesSettingsView()
        .tabItem { Label("Rules", systemImage: "list.bullet.rectangle") }
      DataSettingsView(store: store)
        .tabItem { Label("Data", systemImage: "internaldrive") }
    }
    .frame(width: 560, height: 390)
    .scenePadding()
  }
}
