//
//  ReceiptMEApp.swift
//  ReceiptME
//
//  Created by Jimmy Lancaster on 1/30/25.
//
// ENTRY POINT FOR THE APP


import SwiftUI
import GoogleSignIn
import GoogleSignInSwift


@main
struct ReceiptMEApp: App {
    @AppStorage("user_permanent_token") var backend_token: String?
    @StateObject var viewModel = ReceiptViewModel()
    
    var body: some Scene {
        WindowGroup {
            if backend_token != nil {
                ContentView()
                    .environmentObject(viewModel)
            } else {
                AuthView()
            }
        }
        
    }
}

