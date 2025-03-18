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
            ZStack {
                // 1) Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.pink, .purple, .blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // 2) Scrollable container for settings items
                ScrollView {
                    VStack(spacing: 24) {
                        // 3) User Info Card
                        userInfoCard
                        
                        // 4) Log Out Button
                        Button(action: {
                            // Clear the backend token, effectively logging out
                            backend_token = nil
                            // Usually you'd present or navigate back to AuthView,
                            // e.g. by setting a state var or environment var that triggers a nav change.
                            // For now, we simply set the token to nil.
                        }) {
                            Text("Log Out")
                                .font(.system(.headline, design: .rounded))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SleekButtonStyle2())
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - User Info Card
    private var userInfoCard: some View {
        VStack(spacing: 8) {
            Text("User Email")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Text(email_ ?? "No stored email")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 3, y: 3)
        .padding(.horizontal, 20)
    }
}

// MARK: - Sleek Reusable ButtonStyle (matches other screens)
struct SleekButtonStyle2: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.pink, .purple, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.25), radius: configuration.isPressed ? 2 : 4, x: 2, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
    
    // MARK: - Preview
    struct SettingsView_Previews: PreviewProvider {
        static var previews: some View {
            SettingsView()
        }
    }
}
