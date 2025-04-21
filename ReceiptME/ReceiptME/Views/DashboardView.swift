import SwiftUI
import Foundation

struct DashboardView: View {
    @ObservedObject var viewModel = ReceiptViewModel()
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasFetched = false // Prevent repeated API calls
    @State private var selectedSortOption = "Sort By: " // Default dropdown text
   
    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var categories: [Category] = []
    
    enum BudgetValue: CaseIterable, Identifiable {
        case percentage, amount
        var id: Self { self }
    }
    @State private var categoryShowing: BudgetValue = .percentage
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                contentView
                    .refreshable {
                        fetchReceipts()
                        fetchCategories()
                    }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                if !hasFetched {
                    isLoading = true
                    fetchReceipts()
                    fetchCategories()
                    hasFetched = true
                }
            }
        }
    }
    
    // Add sorting methods
    private func sortReceiptsByDate() { // date is stored as a string !!
        viewModel.receipts.sort { $0.date < $1.date }
        
//        let date
        
    }
    
    private func sortReceiptsByTotal() {
        viewModel.receipts.sort { $0.total < $1.total }
    }
    private func sortReceiptsByMerchant() {
        viewModel.receipts.sort { $0.merchant.localizedCaseInsensitiveCompare($1.merchant) == .orderedAscending }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.pink, .purple, .blue]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            loadingView
        } else if let errorMessage = errorMessage {
            errorView(message: errorMessage)
        } else if !viewModel.receipts.isEmpty {
            listView
        } else {
            emptyView
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ProgressView("Loading receipts...")
            .font(.system(.title3, design: .rounded))
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        Text(message)
            .font(.system(.title3, design: .rounded))
            .foregroundColor(.red)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        Text("No receipts available.")
            .font(.system(.title3, design: .rounded))
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
        .refreshable {
            print("Page refreshed !!")
            fetchReceipts()
        }
    }
    
    // MARK: - List View
    private var listView: some View {
        List {
            Section() {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        Button("", systemImage: "arrow.left", action: {
                            if month == 1 {
                                month = 12
                                year -= 1
                            } else {
                                month -= 1
                            }
                            fetchCategories()
                        })
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                        Spacer()
                        Text(verbatim: "\(Calendar.current.monthSymbols[month - 1]) \(year)")
                            .font(.title.bold())
                        Spacer()
                        Button("", systemImage: "arrow.right", action: {
                            if month == 12 {
                                month = 1
                                year += 1
                            } else {
                                month += 1
                            }
                            fetchCategories()
                        })
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                    }
                    HStack(alignment: .center) {
                        Text("Budget Categories")
                            .font(.headline)
                        Spacer()
                        NewCategoryButton(parent: self)
                    }
                    ForEach(categories) { category in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.system(size: 14))
                            HStack(alignment: .center, spacing: 4) {
                                ProgressView(value: category.month_spend / category.monthly_goal)
                                if categoryShowing == .percentage {
                                    Text(String(format: "%.0f%%", category.month_spend / category.monthly_goal * 100))
                                        .font(.footnote)
                                } else {
                                    Text(String(format: "$%.2f", category.month_spend))
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                    HStack() {
                        Text(String(format: "Total: $%.2f", categories.map { element in
                            element.month_spend
                        }.reduce(0, +)))
                            .font(.body.bold())
                        Spacer()
                        Picker("Number Type", selection: $categoryShowing) {
                            Text("$").tag(BudgetValue.amount)
                            Text("%").tag(BudgetValue.percentage)
                        }
                            .pickerStyle(.segmented)
                            .frame(width: 80)
                    }
                }
                    .listRowBackground(Color.white.opacity(0.15))
            }
            Section(header: Text("Receipts")) {
                ForEach(viewModel.receipts) { receipt in
                    NavigationLink(
                        destination: ReceiptDetailView(viewModel: viewModel, receipt: receipt)
                    ) {
                        ReceiptRow(receipt: receipt)
                    }
                    .listRowBackground(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 2)
                }
                .onDelete(perform: deleteItems)
            }
        }
        .scrollContentBackground(.hidden) // iOS 16+ to let the gradient show through
    }
    
    private struct NewCategoryButton: View {
        @State private var presented = false
        @State private var name = ""
        @State private var spendGoal = ""
        @State private var errorStr: String? = nil
        @State private var errorPresented = false
        
        private var parent: DashboardView
        
        init(parent: DashboardView) {
            self.parent = parent
        }
        
        var body: some View {
            Button("New Category", systemImage: "plus") {
                name = ""
                spendGoal = ""
                presented = true
            }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .alert("New Category", isPresented: $presented, actions: {
                    TextField("Category Name", text: $name)
                    TextField("Monthly Spend Goal", text: $spendGoal)
                        .keyboardType(.decimalPad)
                    Button("Save") {
                        guard let goal = Double(spendGoal) else {
                            errorPresented = true
                            errorStr = "Please enter a valid dollar amount"
                            return
                        }
                        APIService.shared.createCategory(name: name, spending_goal: goal) { result in
                            switch result {
                            case .success:
                                presented = false
                                parent.fetchCategories()
                            case .failure(let err):
                                presented = false
                                errorPresented = true
                                errorStr = err.localizedDescription
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        presented = false
                    }
                })
                .alert(errorStr ?? "Unable to create category", isPresented: $errorPresented) {
                    Button("OK", role: .cancel) {
                        errorPresented = false
                        presented = true
                    }
                }
        }
    }
    
    // MARK: - Receipt Row Subview
    private struct ReceiptRow: View {
        let receipt: Receipt
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(receipt.merchant)
                    .font(.system(.headline, design: .rounded))
                Text(receipt.date)
                    .font(.system(.subheadline, design: .rounded))
                Text(String(format: "$%.2f", receipt.total))
                    .font(.system(.subheadline, design: .rounded))
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Delete Items
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let receiptToDelete = viewModel.receipts[index]
            viewModel.deleteReceipt(receiptToDelete)
        }
        // If you want rows to vanish immediately, uncomment:
        // viewModel.receipts.remove(atOffsets: offsets)
    }
    
    private func fetchCategories() {
        APIService.shared.getCategories(year: year, month: month) { result in
            switch result {
            case .success(let categories):
                self.categories = categories
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Fetch Receipts
    private func fetchReceipts() {
        APIService.shared.fetchReceipts { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let list):
                    print("Successfully fetched receipts")
                    // Convert [ReceiptPreview] -> [Receipt]
                    viewModel.receipts = list.receipts.map { preview in
                        Receipt(
                            id: preview.id,
                            merchant: preview.merchant,
                            date: preview.date,
                            total: preview.total
                        )
                    }
                case .failure(let error):
                    print("Failed to fetch receipts")
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
