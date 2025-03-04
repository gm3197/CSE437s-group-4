import SwiftUI

struct ReceiptDetailView: View {
    @ObservedObject var viewModel: ReceiptViewModel
    let receipt: Receipt

    @State private var isEditing = false
    @State private var editableMerchant: String
    @State private var editableTotal: String
    @State private var editableDate: Date

    // A simple DateFormatter. Modify the dateStyle/timeStyle
    // (or use a custom format) as needed to match your app.
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    init(receipt: Receipt, viewModel: ReceiptViewModel) {
        self.receipt = receipt
        self.viewModel = viewModel

        // Initialize the text fields
        _editableMerchant = State(initialValue: receipt.merchant)
        _editableTotal = State(initialValue: String(receipt.total))

        // Attempt to parse the date string; if it fails, use the current date.
        if let parsedDate = dateFormatter.date(from: receipt.date) {
            _editableDate = State(initialValue: parsedDate)
        } else {
            _editableDate = State(initialValue: Date())
        }
    }

    var body: some View {
        VStack {
            if isEditing {
                Form {
                    Section(header: Text("Edit Receipt")) {
                        TextField("Merchant", text: $editableMerchant)
                        // Add the DatePicker
                        DatePicker("Date", selection: $editableDate, displayedComponents: .date)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Merchant: \(receipt.merchant)")
                    Text("Total: \(receipt.total, specifier: "%.2f")")
                    Text("Date: \(receipt.date)")
                }
                .padding()
            }
        }
        .navigationBarTitle("Receipt Detail", displayMode: .inline)
        .navigationBarItems(
            leading: isEditing ? Button(action: {
                // Reset editable values on cancel
                editableMerchant = receipt.merchant
                editableTotal = String(receipt.total)
                if let parsedDate = dateFormatter.date(from: receipt.date) {
                    editableDate = parsedDate
                }
                isEditing = false
            }) {
                Text("Cancel")
            } : nil,
            trailing: Button(action: {
                if isEditing {
                    // Create an updated receipt with the new values
                    var updatedReceipt = receipt
                    updatedReceipt.merchant = editableMerchant
                    // Convert the selected Date to a string
                    updatedReceipt.date = dateFormatter.string(from: editableDate)
                    
                    viewModel.updateReceipt(updatedReceipt)
                }
                isEditing.toggle()
            }) {
                Text(isEditing ? "Save" : "Edit")
            }
        )
    }
}
