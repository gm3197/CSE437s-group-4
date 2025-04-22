import SwiftUI
import Foundation

struct ReceiptItemView: View {
    @Binding var receiptItem: ReceiptItem
    @State var receiptId: Int
    var saveAction: () -> Void // Closure to trigger save

    @State private var isEditing = true
    @State private var editedItemName: String
    @State private var editedItemPrice: String
    @State private var editedItemCategoryID: Int? // PARAMETER OF RECEIPT ITEM
    @State private var hasBeenEdited = false
    
    @State private var categories: [Category] = []
    @State private var selectedCategoryID: Int?
    @State private var selectedCategoryName: String = "Unknown Category"
    
    @Environment(\.dismiss) private var dismiss
    @State private var are_changes_saved = false

    init(receiptId: Int, receiptItem: Binding<ReceiptItem>, saveAction: @escaping () -> Void) {
        self.receiptId = receiptId
        self._receiptItem = receiptItem
        self.saveAction = saveAction
        self._editedItemName = State(initialValue: receiptItem.wrappedValue.description)
        self._editedItemPrice = State(initialValue: String(format: "%.2f", receiptItem.wrappedValue.price))
        self._editedItemCategoryID = State(initialValue: receiptItem.wrappedValue.category)
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
            
            editingView
                .background(cardBackground)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 2, y: 2)
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Background Style for the card
    private var cardBackground: some View {
        Color.white.opacity(0.15)
    }
    
    // MARK: - Editing View
    private var editingView: some View {
        VStack(spacing: 16) {
            AuthenticatedImage(url: "\(APIService.shared.baseURL)/receipts/\(receiptId)/items/\(_receiptItem.id)/scan.png")
            
            TextField("Item Name", text: $editedItemName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .rounded))
                .padding(.horizontal)
            
            TextField("Price", text: $editedItemPrice)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .font(.system(.body, design: .rounded))
                .padding(.horizontal)
            
            
            Picker("Select Category", selection: $selectedCategoryID) {
                Text("No category selected").tag(nil as Int?) // default dropdown option
                ForEach(categories, id: \.id) { category in
                    Text(category.name).tag(category.id as Int?)
                }
            }
            .onChange(of: selectedCategoryID) { newID in
                if let newID = newID, let matchedCategory = categories.first(where: { $0.id == newID }) {
                    selectedCategoryName = matchedCategory.name
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
            .foregroundColor(.white)
            
            
            
            Button(receiptItem.id <= 0 ? "Add Item" : "Save Changes") {
                if commitChanges() {
                    saveAction() // update backend
                    isEditing = false
                    are_changes_saved = true
                    dismiss() // pops back to ReceiptDetailView !!
                }
            }
            .buttonStyle(SleekButtonStyle())
            .alert("Changes Saved", isPresented: $are_changes_saved) {
                
            } message: {
                Text("Press ok to continue")
            }
        }
        .onAppear {
            showCategories()
        }
    }
    
    private func commitChanges() -> Bool {
        guard let newPrice = Double(editedItemPrice) else {
            print("Failed to commit changes: price not convertible to Double.")
            return false
        }
        receiptItem.description = editedItemName
        receiptItem.price = newPrice
        receiptItem.category = selectedCategoryID
        return true
    }
    
    private func showCategories() {
        let viewModel = ReceiptViewModel()
        
        viewModel.getCategories(nil, month: nil) { result in // call function on an instance of viewModel
            DispatchQueue.main.async {
                switch result {
                    case .success(let fetchedCategories):
                        print("Got categories in receipt item view:\n\(fetchedCategories)")
                        self.categories = fetchedCategories
                    
                    // Find current category based on receiptItem.category
                    if let categoryID = receiptItem.category,
                       let matchedCategory = fetchedCategories.first(where: { $0.id == categoryID }) {
                        self.selectedCategoryID = matchedCategory.id
                        self.selectedCategoryName = matchedCategory.name
                    } else {
                        self.selectedCategoryID = nil
                        self.selectedCategoryName = "No Category Selected"
                    }
                    case .failure(let error):
                        print("Error retrieving categories: \(error)")
                }
            }
            
        }
        
    }
    
}
