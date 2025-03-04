import SwiftUI
import Foundation

struct ReceiptDetailView: View {
    @ObservedObject var viewModel: ReceiptViewModel
    let receipt: Receipt

    @State private var isEditing = false
    @State private var editableMerchant: String
    @State private var editableDate: Date

    // A simple DateFormatter. Adjust to match your desired format.
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    // MARK: - Init
    init(receipt: Receipt, viewModel: ReceiptViewModel) {
        self.receipt = receipt
        self.viewModel = viewModel

        _editableMerchant = State(initialValue: receipt.merchant)

        // Attempt to parse the date string; if it fails, use the current date
        if let parsedDate = dateFormatter.date(from: receipt.date) {
            _editableDate = State(initialValue: parsedDate)
        } else {
            _editableDate = State(initialValue: Date())
        }
    }

    var body: some View {
        ZStack {
            // 1) Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.pink, .purple, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 2) Show either the Form (for editing) or the detail card (non-editing)
            if isEditing {
                editForm
            } else {
                ScrollView {
                    detailCard
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Receipt Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: isEditing ? Button("Cancel") {
                // Reset editable values on cancel
                editableMerchant = receipt.merchant
                if let parsedDate = dateFormatter.date(from: receipt.date) {
                    editableDate = parsedDate
                }
                isEditing = false
            } : nil,
            trailing: Button(isEditing ? "Save" : "Edit") {
                if isEditing {
                    // Create an updated receipt with the new values
                    var updatedReceipt = receipt
                    updatedReceipt.merchant = editableMerchant
                    updatedReceipt.date = dateFormatter.string(from: editableDate)

                    
                    viewModel.updateReceipt(updatedReceipt)
                }
                isEditing.toggle()
            }
        )
    }
}

// MARK: - Subviews
extension ReceiptDetailView {

    /// The editing form with fields for merchant, total, and date picker
    private var editForm: some View {
        Form {
            Section(header: Text("Edit Receipt").font(.system(.headline, design: .rounded))) {
                TextField("Merchant", text: $editableMerchant)
                    .font(.system(.body, design: .rounded))
                
                DatePicker("Date", selection: $editableDate, displayedComponents: .date)
                    .font(.system(.body, design: .rounded))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Optionally style the background if you want it translucent:
         .scrollContentBackground(.hidden)
         .background(Color.white.opacity(0.15))
         .cornerRadius(16)
         .shadow(color: .black.opacity(0.15), radius: 5, x: 2, y: 4)
    }
    
    /// The detail card shown when NOT editing
    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Merchant")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            Text(receipt.merchant)
                .font(.system(.title, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Divider().background(Color.white.opacity(0.3))
            
            Text("Total")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            Text(String(format: "$%.2f", receipt.total))
                .font(.system(.title, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Divider().background(Color.white.opacity(0.3))
            
            Text("Date")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            Text(receipt.date)
                .font(.system(.title, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 6, x: 3, y: 4)
        
    }
    
}

// MARK: - Preview
struct ReceiptDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyReceipt = Receipt(id: 1,
                                   merchant: "Test Merchant",
                                   date: "Feb 20, 2025",
                                   total: 100.00)
        let viewModel = ReceiptViewModel()
        NavigationView {
            ReceiptDetailView(receipt: dummyReceipt, viewModel: viewModel)
        }
    }
}
