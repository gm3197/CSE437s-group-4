//
//  AuthView.swift
//  ReceiptME
//
//  Created by Jimmy Lancaster on 2/4/25.
//
import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignIn: Bool = true

    var body: some View {
        NavigationView {
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
                            .background(Color.blue)
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

                        Button(action: {
                            // Handle Google Sign-In
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Google")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
