//
//  ReceiptItemView.swift
//  ReceiptME
//
//  Created by Jake Teitelbaum on 3/27/25.
//

import SwiftUI
import Foundation

struct ReceiptItemView: View {
    
    @Binding var receiptItem: ReceiptItem
    var saveAction: () -> Void // Closure (passing of function as a parameter) to trigger save
    
    @State private var isEditing = false
    @State private var editedItemName: String
    @State private var editedItemPrice: String
    @State private var editedItemCategoryID: Int? // PARAMETER OF RECEIPT ITEM
    @State private var hasBeenEdited = false
    
    @State private var categories: [Category] = []
    @State private var selectedCategoryID: Int?
    @State private var selectedCategoryName: String = "Unknown Category"
    
    init(receiptItem: Binding<ReceiptItem>, saveAction: @escaping () -> Void) { // using wrappers instead if @ declaration -- allows for incremental updates to State vars (vs immediate updates)
        // initializes with values from @Binding (indicated by underscore var prefix)
        self._receiptItem = receiptItem
        self.saveAction = saveAction
        self._editedItemName = State(initialValue: receiptItem.wrappedValue.description)
        self._editedItemPrice = State(initialValue: String(format: "%.2f", receiptItem.wrappedValue.price))
        self._editedItemCategoryID = State(initialValue: receiptItem.wrappedValue.category)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if isEditing {
                editingView
            } else {
                displayView
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 5)
        .navigationTitle("Item Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Cancel" : "Edit") {
                    if isEditing {
                        // Reset to original values
                        editedItemName = receiptItem.description
                        editedItemPrice = String(format: "%.2f", receiptItem.price)
                        
                    }
                    isEditing.toggle()
                }
                .foregroundColor(.black)
            }
        }
    }
    
    private var editingView: some View {
        VStack(spacing: 16){
            TextField("Item Name", text: $editedItemName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("Price", text: $editedItemPrice)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
            
            
            Picker("Select Category", selection: $selectedCategoryID) {
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
            
            
            
            Button("Save Changes") {
                print("Commiting changes (a)")
                if commitChanges() {
                    saveAction() // update backend
                    isEditing = false // reset flag
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.green)
            .cornerRadius(8)
        }
        .onAppear {
            showCategories()
        }
    }
    
    
    private var displayView: some View {
        VStack(spacing: 12) {
            Text(receiptItem.description.isEmpty ? "No name available" : receiptItem.description)
                .font(.title)
                .foregroundColor(.white)
            
            Text(receiptItem.price == 0.0 ? "Price Not Set" : String(format: "$%.2f", receiptItem.price))
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            Text(selectedCategoryName)
            .font(.title3)
            .foregroundColor(.white.opacity(0.7))
            .italic()
        }
        .padding()
    }
    
    
    private func commitChanges() -> Bool {
        guard let newPrice = Double(editedItemPrice) else {
            print("Failed to commit changes")
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
                        self.selectedCategoryID = fetchedCategories.first?.id // Default to first category
                        self.selectedCategoryName = fetchedCategories.first?.name ?? "No Category Selected"
                    }
                    case .failure(let error):
                        print("Error retrieving categories: \(error)")
                }
            }
            
        }
        
    }
    
}


