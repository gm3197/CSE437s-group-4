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
    @State private var allCategories: [Category] = []
    
    // Creating a new receiptItem
    //    @State private var creatingNewItem: Bool = false
    @State private var newlyAddedItemIndex: Int? = nil
    
    
    
    
    // A simple DateFormatter. Adjust to match your desired format.
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        //        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        ZStack {
            // Background gradient
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
                if let details = details {
                    detailCard(for: details)
                } else {
                    // If details haven't loaded or there's an error
                    ProgressView("Loading details...")
                        .foregroundColor(.white)
                        .padding()
                }
            }
            // navigationLink to adding new receipt item
            if let idx = newlyAddedItemIndex {
                NavigationLink( destination: ReceiptItemView(
                    receiptId: details!.id, // force unwrap
                    receiptItem: $editableItems[idx],
                    saveAction: {
                        saveItemEdits()
                        newlyAddedItemIndex = nil    // reset after save
                    }
                ),
                                isActive: Binding(
                                    get: { newlyAddedItemIndex != nil },
                                    set: { isActive in
                                        if !isActive { newlyAddedItemIndex = nil }
                                    }
                                )
                ) {
                    EmptyView()
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
                    saveMetadataEdits()
                    // Refresh details after saving
                    viewModel.fetchReceiptDetails(receiptId: receipt.id) { result in
                        if case .success(let fetched) = result {
                            self.details = fetched
                            setupEditableFields(with: fetched)
                        }
                    }
                }
                isEditing.toggle()
            }
        )
        .navigationBarBackButtonHidden(isEditing)
        .onAppear {
            // Fetch details
            viewModel.fetchReceiptDetails(receiptId: receipt.id) { result in
                if case .success(let fetchedDetails) = result {
                    self.details = fetchedDetails
                    setupEditableFields(with: fetchedDetails)
                }
            }
            // Fetch categories for bulk apply
            APIService.shared.getCategories(year: nil, month: nil) { result in
                DispatchQueue.main.async {
                    if case .success(let cats) = result {
                        self.allCategories = cats
                    }
                }
            }
        }
    }
}

// MARK: - Subviews & Helpers
extension ReceiptDetailView {
    
    // MARK: Non-Editing State
    private func detailCard(for details: ReceiptDetails) -> some View {
        List {
            Section(header: Text("Tools")) {
                Menu {
                    ForEach(allCategories) { category in
                        Button(category.name) {
                            applyCategoryToAll(category)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "tag")
                        Text("Apply Category to All Items")
                    }
                    .font(.subheadline)
                    .padding(.vertical, 4)
                }
                NavigationLink(destination: {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [.pink, .purple, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            ScrollViewReader { sp in
                                AuthenticatedImage(url: "\(APIService.shared.baseURL)/receipts/\(receipt.id)/scan.png")
                                    .onLoad {
                                        sp.scrollTo(0, anchor: .center)
                                    }
                                    .id(0)
                            }
                        }
                    }
                    .navigationTitle("Original Receipt Image")
                }, label: {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("View Original Receipt Image")
                    }
                    .font(.subheadline)
                    .padding(.vertical, 4)
                })
            }
            .listRowBackground(Color.white.opacity(0.15))
            .scrollContentBackground(.hidden)

    
            
            Section {
                ForEach(editableItems.indices, id: \.self) { index in
                    NavigationLink(destination: ReceiptItemView(
                        receiptId: details.id,
                        receiptItem: $editableItems[index], // pass object instead of seperate items
                        saveAction: saveItemEdits
                    )) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(editableItems[index].description)
                                .lineLimit(nil)
                            Spacer()
                            Text(String(format: "$%.2f", editableItems[index].price))
                        }
                    }
                }
                .onDelete(perform: deleteItems)
                
                // add receiptItem button
                Button(action: addReceiptItem) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Item")
                    }
                    .font(.subheadline)
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                
            } header: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(details.merchant)
                        .font(.title)
                        .foregroundStyle(.white)
                    HStack(alignment: .center) {
                        Text(details.date)
                            .font(.caption)
                            .foregroundStyle(.white)
                        Spacer()
                        Text(details.payment_method)
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
                    .padding(.bottom, 8)
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center) {
                        Text("Tax")
                            .foregroundStyle(.white)
                            .font(.system(size: 18))
                        Spacer()
                        Text(String(format: "$%.2f", details.tax))
                            .foregroundStyle(.white)
                            .font(.system(size: 18))
                    }
                    HStack(alignment: .center) {
                        Text("Total")
                            .foregroundStyle(.white)
                            .font(.system(size: 18, weight: .bold))
                        Spacer()
                        Text(String(format: "$%.2f", details.items.map({ item in
                            item.price
                        }).reduce(0, +) + details.tax))
                            .foregroundStyle(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .padding(.top, 8)
            }
                .listRowBackground(Color.white.opacity(0.15))
                .textCase(nil)
            
           
            .listRowBackground(Color.white.opacity(0.15))
        }
            .scrollContentBackground(.hidden)
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
        VStack {
            Form {
                Section(header: Text("Edit Receipt")) {
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
    
    private func saveMetadataEdits() {
        guard var details = details else { return }
        
//        print("detials in saveMetadataEdits func: \(details)\n")
        
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
    
    /// Bulk‑assign a single category to every line item, by calling your item‑level API on each.
    private func applyCategoryToAll(_ category: Category) {
        guard let details = details else { return }

        // 1) Update your UI immediately
        editableItems = editableItems.map { item in
            var copy = item
            copy.category = category.id
            return copy
        }

        // 2) Push that change to *each* line‑item via the same API you already use
        for item in editableItems {
            viewModel.updateReceiptItem(item,
                                       receipt_id: details.id) { result in
                if case .failure(let error) = result {
                    print("Failed to update item \(item.id): \(error)")
                }
            }
        }

        // (Optional) If you want to re‑fetch the full details after all are done:
        // viewModel.fetchReceiptDetails(receiptId: details.id) { ... }
    }
    
private func saveItemEdits() {
        guard var updatedDetails = details else {
            print("ERROR: No details available")
            return
        }
        let originalItems = updatedDetails.items
//        print("PRE UPDATE details in saveItemEdits func: \(originalItems)\n")

        let allItems = editableItems

//        print("POST UPDATE details in saveItemEdits func: \(updatedDetails)\n")
        
        if let newItem = allItems.last, newItem.id <= 0 {
//            print("Adding new receipt item")
            print("Calling addReceiptItem for placeholder ID \(newItem.id)")

            viewModel.addReceiptItem(newItem, receiptId: updatedDetails.id) { updatedDetails in
                DispatchQueue.main.async {
                    self.details = updatedDetails
                    self.editableItems = updatedDetails.items
                    self.newlyAddedItemIndex = nil
                }
            }
            
        } else {
            print("Updating existing receipt item")
            let changedItem = findChangedItems(originalItems: originalItems, updatedItems: allItems)
            
            viewModel.updateReceiptItem(changedItem, receipt_id: updatedDetails.id) { updated in
    //            print("4. Completion handler reached with updated details")
                DispatchQueue.main.async {
//                    self.details = updated
    //                self.editableItems = updated.items // idk
    //                print("5. UI has been updated")
                }
                
            }
            
        }
        
    }
    
    
    private func deleteItems(at offsets: IndexSet) {
        print("Delete items function starting")
        guard let details = details else { return }
        let receiptId = details.id
        
        for idx in offsets {
            let itemId = editableItems[idx].id
            
            print("delete receipt item func being called")
            viewModel.deleteReceiptItem(itemId, within_receipt_with_id: details.id) { result in
                switch result {
                case .success:
                    print("Initial succes")
//                    DispatchQueue.main.async {
//                        // sync local UI with server
//                        editableItems.remove(atOffsets: offsets)
//                    }
                    viewModel.fetchReceiptDetails(receiptId: receiptId) { fetchResult in
                        switch fetchResult {
                        case .success(let updatedDetails):
                            DispatchQueue.main.async {
                                print("Re-fetching receipt details after item deletion")
                                self.details = updatedDetails
                                self.editableItems = updatedDetails.items
                            }
                        case .failure(let error):
                            print("Error re‑fetching receipt after delete:", error)
                        }
                    }
                    
                    
                case .failure(let error):
                    print("Failed to delete item:", error)
                }
            }
        }
    }
    
    
    private func findChangedItems(originalItems: [ReceiptItem], updatedItems: [ReceiptItem]) -> ReceiptItem {
        
        // Create a dictionary of original items keyed by ID for faster lookup
        let originalItemDict = Dictionary(uniqueKeysWithValues: originalItems.map { ($0.id, $0) })
        
//        // if mismatched lenghts (new item was created)
//        if updatedItems.count > originalItems.count {
//            let newOnes = updatedItems.filter { originalItemDict[$0.id] == nil }
//            if let newItem = newOnes.first { // will only work with one item added at a time ??
//                return newItem
//            }
//        }
        
        // loop through existing items
        for updatedItem in updatedItems {
            if let originalItem = originalItemDict[updatedItem.id] {
                // Check if description or price has changed
                if originalItem.description != updatedItem.description ||
                    originalItem.price != updatedItem.price  || originalItem.category != updatedItem.category {
                    return updatedItem
                }
            }
        }
        print("ERROR: No changes in receipt items found")
        return updatedItems[0]
    }
    
    // MARK: - UI Helpers
    private func infoSectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.white.opacity(0.8))
    }
    
    private func addReceiptItem() {
        // create a temp item with a negative ID (backend should replace it on save)
        let newItem = ReceiptItem(description: "New Item", price: 0.0, id: Int.random(in: -9999...(-1)), category: nil)
        editableItems.append(newItem)
        
        // go to receiptItemView so user can edit values
        newlyAddedItemIndex = editableItems.count - 1
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
