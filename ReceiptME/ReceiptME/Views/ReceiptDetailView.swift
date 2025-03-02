import SwiftUI

struct ReceiptDetailView: View {
    @ObservedObject var viewModel: ReceiptViewModel
    let receipt: Receipt

    @State private var isEditing = false
    @State private var editableMerchant: String
    @State private var editableTotal: String

    init(receipt: Receipt, viewModel: ReceiptViewModel) {
        self.receipt = receipt
        self.viewModel = viewModel
        _editableMerchant = State(initialValue: receipt.merchant)
        _editableTotal = State(initialValue: String(receipt.total))
    }

    var body: some View {
        VStack {
            if isEditing {
                Form {
                    Section(header: Text("Edit Receipt")) {
                        TextField("Merchant", text: $editableMerchant)
                        TextField("Total", text: $editableTotal)
                            .keyboardType(.decimalPad)
                        // Add additional fields (like date) if needed.
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Merchant: \(receipt.merchant)")
                    Text("Total: \(receipt.total, specifier: "%.2f")")
                    Text("Date: \(receipt.date)")
                    // Display additional fields as desired.
                }
                .padding()
            }
        }
        .navigationBarTitle("Receipt Detail", displayMode: .inline)
        .navigationBarItems(
            leading: isEditing ? Button(action: {
                // Reset editable values on cancel.
                editableMerchant = receipt.merchant
                editableTotal = String(receipt.total)
                isEditing = false
            }) {
                Text("Cancel")
            } : nil,
            trailing: Button(action: {
                if isEditing {
                    // Create an updated receipt with the new values.
                    var updatedReceipt = receipt
                    updatedReceipt.merchant = editableMerchant
                    // Convert the string to Double; if conversion fails, fall back to original total.
                    updatedReceipt.total = Double(editableTotal) ?? receipt.total
                    viewModel.updateReceipt(updatedReceipt)
                }
                isEditing.toggle()
            }) {
                Text(isEditing ? "Save" : "Edit")
            }
        )
    }
}

struct ReceiptDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy receipt matching your Receipt model.
        let dummyReceipt = Receipt(id: 1, merchant: "Test Merchant", date: "2025-02-18", total: 100.0)
        let viewModel = ReceiptViewModel()
        NavigationView {
            ReceiptDetailView(receipt: dummyReceipt, viewModel: viewModel)
        }
    }
}
