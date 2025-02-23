import Foundation
import SwiftUI

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
}
