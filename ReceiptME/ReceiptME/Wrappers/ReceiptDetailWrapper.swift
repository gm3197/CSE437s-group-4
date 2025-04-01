//
//  ReceiptDetailWrapper.swift
//  ReceiptME
//
//  Created by Jake Teitelbaum on 3/4/25.
//

import SwiftUI

struct ReceiptDetailWrapper: View {
    // The ID we receive from navigation
    let receiptId: Int
    
    // View model to manage data and API calls
    @StateObject private var viewModel = ReceiptViewModel()
    @State private var receipt: Receipt?
    
    // Loading state
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView("Loading receipt details...")
                }
            } else if let errorMessage = errorMessage {
                // Error state
                VStack {
                    Text("Error loading receipt")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .foregroundColor(.gray)
                        .padding()
                    
                    Button("Try Again") {
                        loadReceipt()
                    }
                    .padding()
                }
            } else if let receipt = receipt {
                // Success state - pass data to the detail view
                ReceiptDetailView(viewModel: viewModel, receipt: receipt)
            } else {
                // Not found state
                VStack {
                    Text("Receipt not found")
                        .font(.headline)
                    
                    Text("The receipt with ID \(receiptId) could not be found.")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
        }
        .onAppear {
            loadReceipt()
        }
    }
    
    private func loadReceipt() {
        isLoading = true
        errorMessage = nil
        
        APIService.shared.fetchReceiptDetails(receiptId: receiptId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let details):
                    // Calculate total by summing item prices and adding tax
                    let itemsTotal = details.items.reduce(0) { $0 + $1.price }
                    let calculatedTotal = itemsTotal + details.tax
                    
                    // Create Receipt with the calculated total
                    self.receipt = Receipt(
                        id: details.id,
                        merchant: details.merchant,
                        date: details.date,
                        total: calculatedTotal
                    )
                    
                    if let receipt = self.receipt {
                        if !viewModel.receipts.contains(where: { $0.id == receipt.id }) {
                            viewModel.addReceipt(receipt)
                        }
                    }
                    
                    isLoading = false
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
