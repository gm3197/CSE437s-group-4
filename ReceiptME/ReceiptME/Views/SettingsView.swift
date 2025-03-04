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
    @AppStorage("user_email") var email_: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20){
                Text("User email: \(email_ ?? "No stored email")")
                
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
