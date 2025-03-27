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
    var saveAction: (() -> Void)? // Closure (passing of function as a parameter) to trigger save
    
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedPrice: String = ""
    @State private var hasBeenEdited = false
    
    init(receiptItem: Binding<ReceiptItem>, saveAction: (() -> Void)? = nil) { // using wrappers instead if @ declaration -- allows for incremental updates to State vars (vs immediate updates)
        // initializes with values from @Binding (indicated by underscore var prefix)
        self._receiptItem = receiptItem
        self.saveAction = saveAction
        self._editedName = State(initialValue: receiptItem.wrappedValue.description)
        self._editedPrice = State(initialValue: String(format: "%.2f", receiptItem.wrappedValue.price))
    }
    
    var body: some View {
        VStack {
            
            // Edit button
            Button(action: {
                isEditing.toggle()
                editedName = receiptItem.description
                editedPrice = String(format: "%.2f", receiptItem.price)
            }) {
                Text(isEditing ? "Cancel" : "Edit")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if isEditing {
                // Editable Fields
                TextField("Item Name", text: $editedName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Price", text: $editedPrice)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .padding()

                Button("Save") {
                    print("Commiting changes (a)")
                    commitChanges()
                    hasBeenEdited = true
                    isEditing = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(8)
            } else {
                // Display Item Details
                Text(receiptItem.description.isEmpty ? "No name available": receiptItem.description)
                    .font(.title)
                    .foregroundColor(.white)
                
                Text(receiptItem.price == 0.0 ? "Price Not Set" : String(format: "$%.2f", receiptItem.price))
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 5)
        .navigationTitle("Item Details")
        .onDisappear {
            // save edits when going back to ReceiptDetailView
            if hasBeenEdited {
                // saveEdits() // update backend values and display in ReceiptDetailView
                saveAction?() // call closure
                hasBeenEdited = false // reset flag
             }
        }
    }
    
    private func commitChanges() {
        if let newPrice = Double(editedPrice) {
            receiptItem.description = editedName
            receiptItem.price = newPrice
        }
        else {
            print("Failed to commit changes")
        }
    }
    
    
    
    
    
    
}
