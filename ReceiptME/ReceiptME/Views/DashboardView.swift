import SwiftUI
import Foundation

struct DashboardView: View {
    @ObservedObject var viewModel = ReceiptViewModel()
    
    @AppStorage("fetch_receipts") var hasFetched: Bool?
    
    @State private var isLoading = false
    @State private var errorMessage: String?
//    @State private var hasFetched = false // Prevent repeated API calls
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                contentView
            }
            .navigationTitle("Dashboard")
            .onAppear {
                if hasFetched != true { // false or null
                    fetchReceipts()
                    hasFetched = true
                }
            }
        }
        .refreshable {
            fetchReceipts()
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
    private var contentView: some View {
        if isLoading {
            loadingView
        } else if let errorMessage = errorMessage {
            errorView(message: errorMessage)
        } else if !viewModel.receipts.isEmpty {
            listView
        } else {
            emptyView
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ProgressView("Loading receipts...")
            .font(.system(.title3, design: .rounded))
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        Text(message)
            .font(.system(.title3, design: .rounded))
            .foregroundColor(.red)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        Text("No receipts available.")
            .font(.system(.title3, design: .rounded))
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
    }
    
    // MARK: - List View
    private var listView: some View {
        List {
            ForEach(viewModel.receipts) { receipt in
                NavigationLink(
                    destination: ReceiptDetailView(viewModel: viewModel, receipt: receipt)
                ) {
                    ReceiptRow(receipt: receipt)
                }
                .listRowBackground(Color.white.opacity(0.15))
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 2)
            }
            .onDelete(perform: deleteItems)
        }
        .refreshable {
            print("Page refreshed !!")
            fetchReceipts()
        }
        .scrollContentBackground(.hidden) // iOS 16+ to let the gradient show through
    }
    
    // MARK: - Receipt Row Subview
    private struct ReceiptRow: View {
        let receipt: Receipt
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(receipt.merchant)
                    .font(.system(.headline, design: .rounded))
                Text(receipt.date)
                    .font(.system(.subheadline, design: .rounded))
                Text(String(format: "$%.2f", receipt.total))
                    .font(.system(.subheadline, design: .rounded))
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Delete Items
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let receiptToDelete = viewModel.receipts[index]
            viewModel.deleteReceipt(receiptToDelete)
        }
        // If you want rows to vanish immediately, uncomment:
        // viewModel.receipts.remove(atOffsets: offsets)
    }
    
    // MARK: - Fetch Receipts
    private func fetchReceipts() {
        isLoading = true
        APIService.shared.fetchReceipts { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let list):
                    // Convert [ReceiptPreview] -> [Receipt]
                    viewModel.receipts = list.receipts.map { preview in
                        Receipt(
                            id: preview.id,
                            merchant: preview.merchant,
                            date: preview.date,
                            total: preview.total
                        )
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
