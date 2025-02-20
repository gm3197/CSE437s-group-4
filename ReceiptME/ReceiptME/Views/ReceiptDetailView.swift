//
//  ReceiptDetailView.swift
//  ReceiptME
//
//  Created by Jimmy Lancaster on 2/18/25.
//

import SwiftUI

struct ReceiptDetailView: View {
    let receiptId: Int
    @State private var receiptDetails: ReceiptDetails?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading details...")
            } else if let details = receiptDetails {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Merchant: \(details.merchant.name)")
                            .font(.headline)
                        Text("Date: \(details.date)")
                        Text("Payment Method: \(details.payment_method)")
                        Text("Tax: \(String(format: "$%.2f", details.tax))")
                        Divider()
                        Text("Items:")
                            .font(.headline)
                        ForEach(details.items, id: \.id) { item in
                            HStack {
                                Text(item.description)
                                Spacer()
                                Text(String(format: "$%.2f", item.price))
                            }
                        }
                    }
                    .padding()
                }
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else {
                Text("No details available.")
            }
        }
        .navigationTitle("Receipt Details")
        .onAppear(perform: fetchReceiptDetails)
    }
    
    func fetchReceiptDetails() {
        isLoading = true
        APIService.shared.fetchReceiptDetails(receiptId: receiptId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let details):
                    receiptDetails = details
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
