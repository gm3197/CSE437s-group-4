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
                // 1) Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.pink, .purple, .blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 2) Main content
                Group {
                    if isLoading {
                        ProgressView("Loading receipts...")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
                    } else if !viewModel.receipts.isEmpty {
                        // Use a List with hidden scroll background
                        List {
                            ForEach(viewModel.receipts) { receipt in
                                NavigationLink(
                                    destination: ReceiptDetailView(
                                        receipt: receipt,
                                        viewModel: viewModel
                                    )
                                ) {
                                    // 3) Row style
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
                        // iOS 16+ only: hide default List background so gradient shows through
                        .scrollContentBackground(.hidden)
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
                    } else {
                        Text("No receipts available.")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                if hasFetched != true { // false or null
                    fetchReceipts()
                    hasFetched = true
                }
            }
        } // end of NavigationView
        
    }
    
    // MARK: - Delete Items (swipe-to-delete)
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let receiptToDelete = viewModel.receipts[index]
            viewModel.deleteReceipt(receiptToDelete)
        }
        // If you want rows to vanish immediately, uncomment:
        // viewModel.receipts.remove(atOffsets: offsets)
        // Then remove the local deletion in deleteReceipt(_:) in the ViewModel.
    }
    
    // MARK: - Fetch Receipts
    func fetchReceipts() {
        isLoading = true
        APIService.shared.fetchReceipts { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let list):
                    // Convert [ReceiptPreview] -> [Receipt]
                    viewModel.receipts = list.receipts.map { preview in
                        Receipt(id: preview.id,
                                merchant: preview.merchant,
                                date: preview.date,
                                total: preview.total)
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
