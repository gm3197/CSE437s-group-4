//
//  AuthView.swift
//  ReceiptME
//
//  Created by Jimmy Lancaster on 2/4/25.
//
import SwiftUI
import AuthenticationServices

import GoogleSignIn
import GoogleSignInSwift



struct AuthView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignIn: Bool = true // sign in vs sign up
    @State private var isAuthenticated = false // to redirect to home page
    
    // initialize var name, set to optional string type
    @AppStorage("user_permanent_token") var backend_token: String?

    var body: some View {
        if isAuthenticated {
            ContentView()
//        } else if @AppStrorage("user_permanent_token") != 0 { // token value already exists
//           ContentView()
        } else {
            NavigationStack {
                ZStack {
                    // 1) Light gray background to fill the entire screen
                    Color(UIColor.systemGray6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // MARK: - Colorful App Title
                        Text("ReceiptME")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.pink, .purple, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .gray.opacity(0.4), radius: 4, x: 2, y: 2)
                            .padding(.top, 40)
                        
                        // MARK: - Sign In / Sign Up Heading
                        Text(isSignIn ? "Sign In" : "Sign Up")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.bottom, 10)
                        
                        // 2) Card-style container for text fields
                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            
                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        
                        // MARK: - Primary Action Button
                        Button(action: {
                            // Handle sign-in or sign-up logic
                        }) {
                            Text(isSignIn ? "Sign In" : "Sign Up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Toggle Sign In / Sign Up
                        Button(action: {
                            isSignIn.toggle()
                            email = ""
                            password = ""
                        }) {
                            Text(isSignIn
                                 ? "Don’t have an account? Sign Up"
                                 : "Already have an account? Sign In")
                            .font(.footnote)
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        // MARK: - Third-party sign in buttons
                        HStack(spacing: 12) {
                            SignInWithAppleButton(.signIn,
                                                  onRequest: { request in
                                // Configure request if needed
                            },
                                                  onCompletion: { result in
                                // Handle Apple sign-in result
                            }
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 45)
                            .cornerRadius(8)
                            
                            GoogleSignInButton(
                                //scheme: GoogleSignInButtonColorScheme,
                                //style: .standard,
                                //state: GoogleSignInButtonState,
                                action: { signInWithGoogle() } )
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(Color.red)
                            .cornerRadius(8)
                            
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                }
                .navigationBarHidden(true)
            }
        }
    }
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
                    guard error == nil else { return }
                    guard let signInResult = signInResult else { return }

                    signInResult.user.refreshTokensIfNeeded { user, error in
                        guard error == nil else { return }
                        guard let user = user else { return }

                        guard let idToken = user.idToken else { return }
                        // Send ID token to backend (example below).
                        
                        sendTokenToBackend(idToken: idToken.tokenString)
                    }
                     // redirect
                    isAuthenticated = true
                }
            }
        else {
            print("Error: Unable to get root view controller")
        }
        
    }
    
    
    func sendTokenToBackend(idToken: String) {
        guard let authData = try? JSONEncoder().encode(["idToken": idToken]) else {
            return
        }
        let url = URL(string: "http://172.27.65.36:8080/auth/google/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.uploadTask(with: request, from: authData) { data, response, error in
            // Handle response from your backend.
            
            struct loginResponse: Codable {
                var session: String
            }
            
            let decoder = JSONDecoder()
            
            guard let unwrapped_data = data else {
                return
            }
            
            do{
                let session_token = try  decoder.decode(loginResponse.self, from: unwrapped_data)
                
                print("Backend data: \(session_token.session)")
                print("Backend Response: \(String(describing: response))")
                                
                // set @AppStorage variable
                backend_token = session_token.session
                print("Got backend token: \(backend_token ?? "None")")
            
                
            } catch {
                print("Error descoding JSON \(error)")
            }
            
            
        }
        task.resume()
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
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
