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
    @State private var isSignIn: Bool = true        // sign in vs sign up
    @State private var isAuthenticated = false      // to redirect to home page

    @AppStorage("user_permanent_token") var backend_token: String?

    var body: some View {
        Group {
            if isAuthenticated {
                ContentView()
                // If a token exists, you can also check that here and skip login:
                // } else if backend_token != nil { ContentView() }
            } else {
                NavigationStack {
                    ZStack {
                        // MARK: - Background Gradient
                        LinearGradient(
                            gradient: Gradient(colors: [.pink, .purple, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()

                        // MARK: - Main VStack
                        VStack(spacing: 30) {
                            // MARK: - Title
                            Text("ReceiptME")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.25), radius: 4, x: 2, y: 2)
                                .padding(.top, 50)

                            // MARK: - Subtitle / Instructions
                            Text("Keep track of your receipts effortlessly.\nSign in to get started!")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .padding(.top, 20)


                            // MARK: - Google Sign-In Button
                            GoogleSignInButton(action: {
                                signInWithGoogle()
                            })
                            .padding(.top, 20)
                            .frame(width: 200, height: 100, alignment: .center)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)

                            Spacer()
                        }
                        .padding(.bottom, 50)
                    }
                    .navigationBarHidden(true)
                }
            }
        }
    }
}

// MARK: - Google Sign In Logic
extension AuthView {
    func signInWithGoogle() {
        guard let rootViewController = getRootViewController() else {
            print("Error: Unable to get root view controller")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            guard let result = signInResult, error == nil else {
                print("Google Sign-In Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Log user info for debug
            let user = result.user
            let userId = user.userID ?? "No ID found"
            let userEmail = user.profile?.email ?? "No email found"
            let userName = user.profile?.name ?? "No username found"

            print("Google Sign-In Successful!")
            print("User ID: \(userId)")
            print("Email: \(userEmail)")
            print("Name: \(userName)")

            // Access ID token for backend
            result.user.refreshTokensIfNeeded { refreshedUser, error in
                guard let refreshedUser = refreshedUser, error == nil,
                      let idToken = refreshedUser.idToken else {
                    return
                }
                sendTokenToBackend(idToken: idToken.tokenString)
            }

            // Toggle to move to main content
            isAuthenticated = true
        }
    }

    func sendTokenToBackend(idToken: String) {
        guard let authData = try? JSONEncoder().encode(["idToken": idToken]) else {
            return
        }

        let url = URL(string: "https://cse437.graysonmartin.net/auth/google/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.uploadTask(with: request, from: authData) { data, response, error in
            guard let unwrappedData = data else {
                return
            }

            struct LoginResponse: Codable {
                var session: String
            }
            let decoder = JSONDecoder()

            do {
                let sessionToken = try decoder.decode(LoginResponse.self, from: unwrappedData)
                print("Backend data: \(sessionToken.session)")
                print("Backend Response: \(String(describing: response))")

                // Save the backend token
                backend_token = sessionToken.session
                print("Got backend token: \(backend_token ?? "None")")
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        task.resume()
    }
}

// MARK: - Helpers
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

func signOutFromGoogle(sender: Any) {
    GIDSignIn.sharedInstance.signOut()
    print("User signed out of Google account")
}
