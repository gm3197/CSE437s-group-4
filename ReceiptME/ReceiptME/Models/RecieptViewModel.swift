//
//  ReceiptViewModel.swift
//  ReceiptME
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

class ReceiptViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var selectedReceipt: Receipt? = nil
    
    // MARK: - Fetch All Receipts (Preview)
    func fetchReceipts() {
        APIService.shared.fetchReceipts { result in
            let workItem = DispatchWorkItem {
                switch result {
                case .success(let list):
                    // Convert from [ReceiptPreview] to [Receipt] if needed
                    self.receipts = list.receipts.map { preview in
                        Receipt(
                            id: preview.id,
                            merchant: preview.merchant,
                            date: preview.date,
                            total: preview.total
                        )
                    }
                case .failure(let error):
                    print("Error fetching receipts: \(error)")
                }
            }
            DispatchQueue.main.async(execute: workItem)
        }
    }
    
    // MARK: - Add a New Receipt Locally (if needed)
    func addReceipt(_ receipt: Receipt) {
        DispatchQueue.main.async {
            self.receipts.append(receipt)
            self.selectedReceipt = receipt
        }
    }
    
    // MARK: - Request Camera Permission
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                print("Camera access granted")
            } else {
                print("Camera access denied")
            }
        }
    }
    
    // MARK: - Update a Basic Receipt (Preview)
    // This updates the simpler "Receipt" object (merchant, total, etc.)
    // If your backend expects different fields, adapt as necessary.
    func updateReceipt(_ updatedReceipt: Receipt) {
        APIService.shared.updateReceipt(updatedReceipt) { result in
            switch result {
            case .success(let receipt):
                DispatchQueue.main.async {
                    if let index = self.receipts.firstIndex(where: { $0.id == receipt.id }) {
                        self.receipts[index] = receipt
                    }
                }
            case .failure(let error):
                print("Error updating receipt: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Delete Receipt
    func deleteReceipt(_ receipt: Receipt) {
        APIService.shared.deleteReceipt(receiptId: receipt.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self?.receipts.removeAll { $0.id == receipt.id }
                case .failure(let error):
                    print("Error deleting receipt: \(error)")
                }
            }
        }
    }
    
    // MARK: - Fetch Detailed Receipt Data
    /// Retrieves the full `ReceiptDetails` (owner_id, clean, merchant obj, items, etc.) from the server.
    func fetchReceiptDetails(receiptId: Int, completion: @escaping (Result<ReceiptDetails, Error>) -> Void) {
        APIService.shared.fetchReceiptDetails(receiptId: receiptId) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    // MARK: - Update Detailed Receipt Data
    /// Sends updated ReceiptDetails to the server, and returns the updated details on success.
    func updateReceiptDetails(_ details: ReceiptDetails, completion: @escaping (ReceiptDetails) -> Void) {
        APIService.shared.updateReceiptDetails(details) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updated):
                    completion(updated)
                case .failure(let error):
                    print("Error updating receipt details: \(error)")
                }
            }
        }
    }
}
