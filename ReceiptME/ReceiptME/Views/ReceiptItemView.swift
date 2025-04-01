//
//  ReceiptItemView.swift
//  ReceiptME
//
//  Created by Jake Teitelbaum on 3/27/25.
//

import SwiftUI
import Foundation

struct ReceiptItemView: View {
    
//    let item_id: UUID // id will never be mutable
//    @Binding var item_name: String // Need @Binding so values are mutable
//    @Binding var item_price: Double
    @Binding var receiptItem: ReceiptItem
    var saveAction: () -> Void // Closure (passing of function as a parameter) to trigger save
    
    @State private var isEditing = false
    @State private var editedItemName: String
    @State private var editedItemPrice: String
    @State private var hasBeenEdited = false
    
    init(receiptItem: Binding<ReceiptItem>, saveAction: @escaping () -> Void) { // using wrappers instead if @ declaration -- allows for incremental updates to State vars (vs immediate updates)
        // initializes with values from @Binding (indicated by underscore var prefix)
        self._receiptItem = receiptItem
        self.saveAction = saveAction
        self._editedItemName = State(initialValue: receiptItem.wrappedValue.description)
        self._editedItemPrice = State(initialValue: String(format: "%.2f", receiptItem.wrappedValue.price))
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
    }
    
    
    private var displayView: some View {
        VStack(spacing: 12) {
            Text(receiptItem.description.isEmpty ? "No name available" : receiptItem.description)
                .font(.title)
                .foregroundColor(.white)
            
            Text(receiptItem.price == 0.0 ? "Price Not Set" : String(format: "$%.2f", receiptItem.price))
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
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
        return true
    }
    
}
