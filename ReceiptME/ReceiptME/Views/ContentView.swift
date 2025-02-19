//
//  ContentView.swift
//  ReceiptME
//
//  Created by Jimmy Lancaster on 1/30/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ScanView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Scan")
                }
            
            DashboardView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Dashboard")
                }
        }
    }
}
