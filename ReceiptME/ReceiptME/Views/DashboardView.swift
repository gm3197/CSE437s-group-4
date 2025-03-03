import SwiftUI
import Foundation

struct DashboardView: View {
    @State private var receiptList: ReceiptList?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasFetched = false // Prevent repeated API calls

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading receipts...")
                } else if let receiptList = receiptList {
                    List(receiptList.receipts) { receipt in
                        NavigationLink(destination: ReceiptDetailView(receiptId: receipt.id)) {
                            VStack(alignment: .leading) {
                                Text(receipt.merchant)
                                    .font(.headline)
                                Text(receipt.date)
                                    .font(.subheadline)
                                Text(String(format: "$%.2f", receipt.total))
                                    .font(.subheadline)
                            }
                        }
                    }
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    Text("No receipts available.")
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                if !hasFetched { // ✅ Ensures the API is only called once
                    fetchReceipts()
                    hasFetched = true
                }
            }
        } // end of navigation view
        .refreshable {
            print("Page refreshed !!")
            fetchReceipts()
        }
    }

    func fetchReceipts() {
        isLoading = true
        APIService.shared.fetchReceipts { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let list):
                    receiptList = list
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
