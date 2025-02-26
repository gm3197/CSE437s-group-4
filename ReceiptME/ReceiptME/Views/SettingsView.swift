//
//  SettingsView.swift
//  ReceiptME
//
//  Created by Jake Teitelbaum on 2/25/25.
//
import SwiftUI
import Foundation

struct SettingsView: View {
    
    @AppStorage("user_permanent_token") var backend_token: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20){
                Button(action: {
                    backend_token = nil
                    AuthView()
                }) {
                    Text("Log Out")
                }
            }
        }
        
    }
}
