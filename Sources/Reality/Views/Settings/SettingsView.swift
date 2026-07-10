import SwiftUI

struct SettingsView: View {
  let store: SettingsStore?

  var body: some View {
    TabView {
      GeneralSettingsView(store: store)
        .tabItem { Label("General", systemImage: "gearshape") }
      PrivacySettingsView(store: store)
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
