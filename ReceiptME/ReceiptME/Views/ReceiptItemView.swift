import SwiftUI
import Foundation

struct ReceiptItemView: View {
    @Binding var receiptItem: ReceiptItem
    var saveAction: () -> Void // Closure to trigger save

    @State private var isEditing = true
    @State private var editedItemName: String
    @State private var editedItemPrice: String

    init(receiptItem: Binding<ReceiptItem>, saveAction: @escaping () -> Void) {
        self._receiptItem = receiptItem
        self.saveAction = saveAction
        self._editedItemName = State(initialValue: receiptItem.wrappedValue.description)
        self._editedItemPrice = State(initialValue: String(format: "%.2f", receiptItem.wrappedValue.price))
    }

    var body: some View {
        ZStack {
            // 1) Background gradient (cover the whole screen)
            LinearGradient(
                gradient: Gradient(colors: [.pink, .purple, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 2) Main card container
            VStack(spacing: 20) {
                if isEditing {
                    editingView
                } else {
                    displayView
                }
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 2, y: 2)
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Cancel" : "Edit") {
                    if isEditing {
                        // Reset to original values if canceling
                        editedItemName = receiptItem.description
                        editedItemPrice = String(format: "%.2f", receiptItem.price)
                    }
                    isEditing.toggle()
                }
                .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Background Style for the card
    private var cardBackground: some View {
        Color.white.opacity(0.15)
    }
    
    // MARK: - Editing View
    private var editingView: some View {
        VStack(spacing: 16) {
            TextField("Item Name", text: $editedItemName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .rounded))
                .padding(.horizontal)
            
            TextField("Price", text: $editedItemPrice)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .font(.system(.body, design: .rounded))
                .padding(.horizontal)
            
            Button("Save Changes") {
                if commitChanges() {
                    saveAction() // update backend
                    isEditing = false
                }
            }
            .buttonStyle(SleekButtonStyle())
        }
    }
    
    // MARK: - Display View
    private var displayView: some View {
        VStack(spacing: 12) {
            Text(receiptItem.description.isEmpty ? "No name available" : receiptItem.description)
                .font(.system(.title, design: .rounded))
                .foregroundColor(.white)
            
            Text(receiptItem.price == 0.0 ? "Price Not Set" : String(format: "$%.2f", receiptItem.price))
                .font(.system(.title2, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
    }
    
    // MARK: - Commit Changes
    private func commitChanges() -> Bool {
        guard let newPrice = Double(editedItemPrice) else {
            print("Failed to commit changes: price not convertible to Double.")
            return false
        }
        receiptItem.description = editedItemName
        receiptItem.price = newPrice
        return true
    }
}

