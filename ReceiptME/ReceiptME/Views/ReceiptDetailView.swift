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
    
    // add receiptItem state var here:
//    @State private var newItem = ReceiptItem(id: UUID(), description: "", price: 0.0) // initializing
    
    // A simple DateFormatter. Adjust to match your desired format.
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
//        formatter.dateStyle = .medium
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
                    // REFRESH RECEIPT AFTER UPDATING
                    // Fetch the full details for this receipt
                    viewModel.fetchReceiptDetails(receiptId: receipt.id) { result in
                        switch result {
                        case .success(let fetchedDetails):
                            self.details = fetchedDetails
                            setupEditableFields(with: fetchedDetails)
                        case .failure(let error):
                            print("Error fetching full details (b): \(error)")
                        }
                    }
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
            // ERROR: The compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions
            // SOLN: Create subviews and call them within this VStack
    
            merchantSection(details)
            dateSection(details)
            totalSection(details)
            paymentMethodSection(details)
            taxSection(details)
            cleanSection(details)
            itemsSection()
            additionalInfoSection(details)
            
        } // end of vstack
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 6, x: 3, y: 4)
    }
    
    // subviews that will be called wihtin detailCard VStack
    private func merchantSection(_ details: ReceiptDetails) -> some View {
        VStack {
            infoSectionHeader("Merchant")
            Text(details.merchant)
                .infoSectionValueStyle()
            Divider().background(Color.white.opacity(0.3))
        }
    }
    private func dateSection(_ details: ReceiptDetails) -> some View {
        VStack {
            infoSectionHeader("Date")
            Text(details.date)
                .infoSectionValueStyle()
            Divider().background(Color.white.opacity(0.3))
        }
    }
    private func totalSection(_ details: ReceiptDetails) -> some View {
        VStack {
            infoSectionHeader("Total")
            Text(String(format: "$%.2f", receipt.total))
                .infoSectionValueStyle()
            Divider().background(Color.white.opacity(0.3))
        }
    }
    private func taxSection(_ details: ReceiptDetails) -> some View {
        VStack {
            infoSectionHeader("Tax")
            Text(String(format: "$%.2f", details.tax))
                .infoSectionValueStyle()
            Divider().background(Color.white.opacity(0.3))
        }
    }

    private func cleanSection(_ details: ReceiptDetails) -> some View {
        VStack {
            infoSectionHeader("Clean?")
            Text(details.clean ? "Yes" : "No")
                .infoSectionValueStyle()
            Divider().background(Color.white.opacity(0.3))
        }
    }

    private func itemsSection() -> some View {
        VStack {
            infoSectionHeader("Items")
            ForEach(editableItems.indices, id: \.self) { index in
                NavigationLink(destination: ReceiptItemView(
//                    item_id: $editableItems[index].id,
//                    item_name: $editableItems[index].description,
//                    item_price: $editableItems[index].price
                    receiptItem: $editableItems[index], // pass object instead of seperate items
                    saveAction: saveEdits
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(editableItems[index].description)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white)
                        Text(String(format: "$%.2f", editableItems[index].price))
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                }
                Divider().background(Color.white.opacity(0.2))
            }
        }
    }

    private func additionalInfoSection(_ details: ReceiptDetails) -> some View {
        VStack {
            Divider().background(Color.white.opacity(0.3))
            infoSectionHeader("Owner ID")
            Text("\(details.owner_id)").infoSectionValueStyle()
            infoSectionHeader("Receipt ID")
            Text("\(details.id)").infoSectionValueStyle()
        }
    }

    // end subviews
    
    private func paymentMethodSection(_ details: ReceiptDetails) -> some View {
        VStack {
            infoSectionHeader("Payment Method")
            Text(details.payment_method)
                .infoSectionValueStyle()
            Divider().background(Color.white.opacity(0.3))
        }
    }

    

    // MARK: Editing State
    private var editForm: some View {
        Form {
                Section(header: Text("Edit Receipt").font(.system(.headline, design: .rounded))) {
                    TextField("Merchant Name", text: $editableMerchantName)
                        .font(.system(.body, design: .rounded))
                    
                    DatePicker("Date", selection: $editableDate, displayedComponents: .date)
                        .font(.system(.body, design: .rounded))
                                
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
        editableMerchantName = details.merchant
        editablePaymentMethod = details.payment_method
        isClean = details.clean
        editableTax = String(details.tax)
        
        if let parsedDate = dateFormatter.date(from: details.date) {
            editableDate = parsedDate
        }
        else {
            print("Error converting date to Date object")
        }
        editableItems = details.items
    }
    
    private func resetEditableFields() {
        guard let details = details else { return }
        setupEditableFields(with: details)
    }
    
    private func saveEdits() {
        guard var details = details else { return }
        
        print("detials in saveEdits func: \(details)\n")
        
        // Merchant name, Payment method, Clean
        details.merchant = editableMerchantName
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
