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
    @State private var isAuthenticated = false

    @AppStorage("user_permanent_token") var backend_token: String?
    @AppStorage("user_email") var email_: String?

    var body: some View {
        Group {
            if isAuthenticated {
                ContentView()
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
                        VStack {
                            // Push content away from top edge
                            Spacer().frame(height: 60)

                            // MARK: - Logo Image
                            Image("AppImage")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            Spacer().frame(height: 60)
                            // MARK: - Welcome Title
                            Text("Welcome to ReceiptME!")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.25), radius: 4, x: 2, y: 2)
                                .padding(.top, 16)
                            Spacer().frame(height: 60)
                            // MARK: - Instructions
                            Text("Manage and organize your receipts effortlessly. Sign in with your Google account to get started.")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .padding(.top, 8)
                            Spacer().frame(height: 60)

                            // MARK: - Google Sign-In Button
                            GoogleSignInButton(action: {
                                signInWithGoogle()
                            })
                            .frame(width: 250, height: 50)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)

                            .clipShape(RoundedRectangle(cornerRadius: 60, style: .continuous))

                            // Push Terms text to the bottom
                            Spacer()

                            // MARK: - Terms & Conditions Notice
                            Text("By signing in, you agree to our Terms & Conditions.")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.bottom, 30)
                        }
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

            let user = result.user
            let userId = user.userID ?? "No ID found"
            let userEmail = user.profile?.email ?? "No email found"
            let userName = user.profile?.name ?? "No username found"

            print("Google Sign-In Successful!")
            print("User ID: \(userId)")
            print("Email: \(userEmail)")
            print("Name: \(userName)")

            // Store user email
            email_ = userEmail

            // Retrieve Google ID token for backend
            result.user.refreshTokensIfNeeded { refreshedUser, error in
                guard let refreshedUser = refreshedUser, error == nil,
                      let idToken = refreshedUser.idToken else {
                    return
                }
                sendTokenToBackend(idToken: idToken.tokenString)
            }

            // Dismiss auth screen
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

// MARK: - Previews
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
