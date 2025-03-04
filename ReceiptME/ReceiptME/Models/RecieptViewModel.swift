import Foundation
import SwiftUI
import AVFoundation
import Combine

class ReceiptViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var selectedReceipt: Receipt? = nil

    func fetchReceipts() {
        APIService.shared.fetchReceipts { result in
            let workItem = DispatchWorkItem {
                switch result {
                case .success(let list):
                    self.receipts = list.receipts.map { preview in
                        Receipt(id: preview.id, merchant: preview.merchant, date: preview.date, total: preview.total)
                    }
                case .failure(let error):
                    print("Error fetching receipts: \(error)")
                }
            }
            DispatchQueue.main.async(execute: workItem)
        }
    }

    func addReceipt(_ receipt: Receipt) {
        DispatchQueue.main.async {
            self.receipts.append(receipt)
            self.selectedReceipt = receipt  // ✅ Set for immediate navigation
        }
    }
    

    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                print("Camera access granted")
            } else {
                print("Camera access denied")
            }
        }
    }
    // This method calls the API service to update a receipt.
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
                    // Handle error appropriately (e.g. alert the user)
                    print("Error updating receipt: \(error.localizedDescription)")
                }
            }
        }
}
