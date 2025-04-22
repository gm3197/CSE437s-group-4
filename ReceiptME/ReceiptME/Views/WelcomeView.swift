import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @State private var navigateToAuth = false
    
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                content
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToAuth) {
                AuthView()
            }
        }
    }

    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.pink, .purple, .blue]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Main Content
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Welcome to ReceiptME")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Effortless receipt tracking and spending insights at your fingertips.")
                .font(.system(.title3, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 16) {
                tipRow(icon: "camera.viewfinder", text: "Tap the scan button to capture receipts instantly.")
                tipRow(icon: "folder", text: "Organize receipts by category and date for easy lookup.")
                tipRow(icon: "chart.bar.doc.horizontal", text: "View spending summaries to stay on budget.")
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
            .padding(.horizontal)

            Spacer()

            Button(action: {
                if let dismiss = onDismiss {
                    dismiss()
                } else {
                    navigateToAuth = true
                }
            }) {
                Text("Okay")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .foregroundColor(.accentColor)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Tip Row Subview
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(.title2, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 30)

            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Preview
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
