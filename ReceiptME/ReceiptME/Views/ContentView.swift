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
                    Text("Dashboard")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        // Make the tab bar icons stand out
        .tint(.white)
        // Give the tab bar a translucent background or color
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
