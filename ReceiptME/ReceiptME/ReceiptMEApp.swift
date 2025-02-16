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
    
    var body: some Scene {
        WindowGroup {
            AuthView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                } // listens for incoming URLs, used to redirect users back to app after authentication
                .onAppear{
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let error = error {
                            print("Google Sign-in error: \(error.localizedDescription)")
                        } else if let user = user {
                            print("User already signed in: \(user.profile?.email ?? "No Email")")
                            // redirect to home page !!, bypass login
                        }
                        
                    }
                   
                }
        }
        
    }
}



//func application( // not finished
//  _ application: UIApplication,
//  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//) -> Bool {
//  GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
//    if error != nil || user == nil {
//      // Show the app's signed-out state.
//    } else {
//      // Show the app's signed-in state.
//    }
//  }
//  return true
//}
