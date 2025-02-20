//
//  ContentView.swift
//  ReceiptME
//
//  Created by Jimmy Lancaster on 1/30/25.
//

import SwiftUI

import GoogleSignIn
import GoogleSignInSwift

struct ContentView: View {
    
    @AppStorage("user_permanent_token") var backend_token: String?
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text(backend_token ?? "No backend token found")
        }
        .padding()
        .navigationTitle("Main Page")
    }
}

#Preview {
    ContentView()
}
