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
        }
        .accentColor(.blue) // Optional: Changes the selected tab color
    }
}

#Preview {
    ContentView()
}
