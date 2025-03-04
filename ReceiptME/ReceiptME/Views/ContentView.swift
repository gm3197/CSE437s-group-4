import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ScanView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Scan")
                }

            DashboardView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Receipts")
                }
            SettingsView()
                .tabItem{
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .accentColor(.blue) // Optional: Changes the selected tab color
    }
}

#Preview {
    ContentView()
}
