//
//  GoogleSignIn.swift
//  ReceiptME
//
//  Created by Jake Teitelbaum on 2/9/25.
//

import GoogleSignIn
import GoogleSignInSwift


func signInWithGoogle() {
    if let rootViewController = getRootViewController() {
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController) { signInResult, error in
                guard let result = signInResult else {
                    // Inspect error
                    print("Error with root view controller: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // If sign in succeeded, display the app's main content View.
                
                // Access user information
                let user = result.user
                let userId = user.userID ?? "No ID found" // given ?
                let userEmail = user.profile?.email ?? "No email found"
                let userName = user.profile?.name ?? "No username found"
                
                print("Google Sign-In Successful!")
                print("User ID: \(userId)")
                print("Email: \(userEmail)")
                print("Name: \(userName)")
                
                // also pass id tokens to backend...
                
                // redirect
                ContentView()
            }
        }
    else {
        print("Error: Unable to get root view controller")
    }
}

func getRootViewController() -> UIViewController? {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = scene.windows.first,
          let rootVC = window.rootViewController else {
        return nil
    }
    return rootVC
}



func signOutFromGoogle(sender: Any){
    GIDSignIn.sharedInstance.signOut()
    print("User signed out of Google account")
}
