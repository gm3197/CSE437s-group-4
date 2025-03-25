//
//  ReceiptDetailView.swift
//  ReceiptME
//

import SwiftUI
import Foundation

struct ReceiptDetailView: View {
    @ObservedObject var viewModel: ReceiptViewModel
    let receipt: Receipt

    // The full, detailed data for this receipt, loaded onAppear
    @State private var details: ReceiptDetails?
    
    // Editing states
    @State private var isEditing = false
    
    // Editable fields for the advanced details
    @State private var editableMerchantName: String = ""
    @State private var editableDate: Date = Date()
    @State private var editablePaymentMethod: String = ""
    @State private var editableTax: String = ""
    @State private var isClean: Bool = false
    
    // Items in the receipt
    @State private var editableItems: [ReceiptItem] = []
    
    // A simple DateFormatter. Adjust to match your desired format.
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        ZStack {
            // 1) Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.pink, .purple, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 2) Content
            if isEditing {
                editForm
            } else {
                ScrollView {
                    if let details = details {
                        detailCard(for: details)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    } else {
                        // If details haven't loaded or there's an error
                        ProgressView("Loading details...")
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("Receipt Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: isEditing ? Button("Cancel") {
                resetEditableFields()
                isEditing = false
            } : nil,
            trailing: Button(isEditing ? "Save" : "Edit") {
                if isEditing {
                    saveEdits()
                }
                isEditing.toggle()
            }
        )
        .onAppear {
            // Fetch the full details for this receipt
            viewModel.fetchReceiptDetails(receiptId: receipt.id) { result in
                switch result {
                case .success(let fetchedDetails):
                    self.details = fetchedDetails
                    setupEditableFields(with: fetchedDetails)
                case .failure(let error):
                    print("Error fetching full details: \(error)")
                }
            }
        }
    }
}

// MARK: - Subviews & Helpers
extension ReceiptDetailView {
    
    // MARK: Non-Editing State
    private func detailCard(for details: ReceiptDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            
            infoSectionHeader("Merchant")
            Text(details.merchant.name)
                .infoSectionValueStyle()
            
            Divider().background(Color.white.opacity(0.3))
            
            infoSectionHeader("Date")
            Text(details.date)
                .infoSectionValueStyle()
            
            Divider().background(Color.white.opacity(0.3))
            
            infoSectionHeader("Total")
            Text(String(format: "$%.2f", receipt.total))
                .infoSectionValueStyle()
            
            Divider().background(Color.white.opacity(0.3))
            
            infoSectionHeader("Payment Method")
            Text(details.payment_method)
                .infoSectionValueStyle()
            
            Divider().background(Color.white.opacity(0.3))
            
            infoSectionHeader("Tax")
            Text(String(format: "$%.2f", details.tax))
                .infoSectionValueStyle()
            
            Divider().background(Color.white.opacity(0.3))
            
            infoSectionHeader("Clean?")
            Text(details.clean ? "Yes" : "No")
                .infoSectionValueStyle()
            
            Divider().background(Color.white.opacity(0.3))
            
            infoSectionHeader("Items")
            ForEach(details.items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.description)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white)
                    Text(String(format: "$%.2f", item.price))
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                Divider().background(Color.white.opacity(0.2))
            }
            
            // Additional debugging or advanced info
            Divider().background(Color.white.opacity(0.3))
            
            infoSectionHeader("Owner ID")
            Text("\(details.owner_id)")
                .infoSectionValueStyle()
            
            infoSectionHeader("Receipt ID")
            Text("\(details.id)")
                .infoSectionValueStyle()
            
        }
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 6, x: 3, y: 4)
    }
    
    // MARK: Editing State
    private var editForm: some View {
        Form {
            Section(header: Text("Edit Receipt").font(.system(.headline, design: .rounded))) {
                
                TextField("Merchant Name", text: $editableMerchantName)
                    .font(.system(.body, design: .rounded))
                
                DatePicker("Date", selection: $editableDate, displayedComponents: .date)
                    .font(.system(.body, design: .rounded))
                
                TextField("Payment Method", text: $editablePaymentMethod)
                    .font(.system(.body, design: .rounded))
                
                TextField("Tax", text: $editableTax)
                    .keyboardType(.decimalPad)
                    .font(.system(.body, design: .rounded))
                
                Toggle(isOn: $isClean) {
                    Text("Clean?")
                        .font(.system(.body, design: .rounded))
                }
            }
            
            Section(header: Text("Items").font(.system(.headline, design: .rounded))) {
                ForEach($editableItems) { $item in
                    VStack(alignment: .leading) {
                        TextField("Item Name", text: $item.description)
                            .font(.system(.body, design: .rounded))
                        
                        TextField("Price", value: $item.price, format: .number)
                            .keyboardType(.decimalPad)
                            .font(.system(.body, design: .rounded))
                    }
                }
                // Add or remove items if desired
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 2, y: 4)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: Editable Fields Management
    private func setupEditableFields(with details: ReceiptDetails) {
        editableMerchantName = details.merchant.name
        editablePaymentMethod = details.payment_method
        isClean = details.clean
        editableTax = String(details.tax)
        if let parsedDate = dateFormatter.date(from: details.date) {
            editableDate = parsedDate
        }
        editableItems = details.items
    }
    
    private func resetEditableFields() {
        guard let details = details else { return }
        setupEditableFields(with: details)
    }
    
    private func saveEdits() {
        guard var details = details else { return }
        
        // Merchant name, Payment method, Clean
        details.merchant.name = editableMerchantName
        details.payment_method = editablePaymentMethod
        details.clean = isClean
        
        // Date → string
        details.date = dateFormatter.string(from: editableDate)
        
        // Tax
        if let taxDouble = Double(editableTax) {
            details.tax = taxDouble
        }
        
        // Items
        details.items = editableItems
        
        // Fire update
        viewModel.updateReceiptDetails(details) { updated in
            // On success, refresh local
            self.details = updated
        }
    }
    
    // MARK: - UI Helpers
    private func infoSectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.white.opacity(0.8))
    }
}

// MARK: - A handy style for values in the detail card
extension Text {
    func infoSectionValueStyle() -> some View {
        self
            .font(.system(.title3, design: .rounded))
            .fontWeight(.semibold)
            .foregroundColor(.white)
    }
}

// MARK: - Preview
struct ReceiptDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Example basic "preview" receipt
        let mockReceipt = Receipt(id: 1,
                                  merchant: "Test Merchant",
                                  date: "Feb 20, 2025",
                                  total: 45.67)
        
        let viewModel = ReceiptViewModel()
        
        return NavigationView {
            // Updated parameter order: viewModel first, then receipt.
            ReceiptDetailView(viewModel: viewModel, receipt: mockReceipt)
        }
    }
}
