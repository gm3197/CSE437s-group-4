import SwiftUI
import Foundation

struct DashboardView: View {
    @ObservedObject var viewModel = ReceiptViewModel()
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasFetched = false
    
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
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.pink, .purple, .blue]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Content State
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            loadingView
        } else if let errorMessage = errorMessage {
            errorView(message: errorMessage)
        } else {
            listView
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
    
    // MARK: - Main List View
    private var listView: some View {
        List {
            // Budget Categories Section
            Section(header: Text("Budget").font(.headline)) {
                // Month navigation
                HStack {
                    Button(action: {
                        if month == 1 {
                            month = 12; year -= 1
                        } else { month -= 1 }
                        fetchCategories()
                    }) {
                        Image(systemName: "arrow.left")
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                    Text(verbatim: "\(Calendar.current.monthSymbols[month - 1]) \(year)")
                        .font(.title.bold())
                    Spacer()
                    Button(action: {
                        if month == 12 {
                            month = 1; year += 1
                        } else { month += 1 }
                        fetchCategories()
                    }) {
                        Image(systemName: "arrow.right")
                    }
                    .buttonStyle(.borderless)
                }
                .listRowBackground(Color.white.opacity(0.15))
                .listRowSeparator(.hidden, edges: .all)

                // Header with new category button
                HStack {
                    Text("Categories")
                        .font(.headline)
                    Spacer()
                    NewCategoryButton(parent: self)
                }
                .listRowBackground(Color.white.opacity(0.15))

                // Category rows
                ForEach(categories) { category in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .font(.system(size: 14, design: .rounded))
                        HStack(spacing: 6) {
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
                    .padding(.vertical, 8)
                    .listRowBackground(Color.white.opacity(0.15))
                }
                .onDelete(perform: deleteCategory)
                
                // Total & toggle
                HStack {
                    Text(String(format: "Total: $%.2f", categories.map { $0.month_spend }.reduce(0, +)))
                        .font(.body.bold())
                    Spacer()
                    Picker("Type", selection: $categoryShowing) {
                        Text("$").tag(BudgetValue.amount)
                        Text("%").tag(BudgetValue.percentage)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                }
                .listRowBackground(Color.white.opacity(0.15))
            }
            
            // Receipts Section
            Section(header: Text("Receipts").font(.headline)) {
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
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - New Category Button
    private struct NewCategoryButton: View {
        @State private var presented = false
        @State private var name = ""
        @State private var spendGoal = ""
        @State private var errorStr: String?
        @State private var errorPresented = false
        private var parent: DashboardView
        init(parent: DashboardView) { self.parent = parent }
        var body: some View {
            Button(action: {
                name = ""; spendGoal = ""; presented = true
            }) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .alert("New Category", isPresented: $presented) {
                TextField("Name", text: $name)
                TextField("Monthly Goal", text: $spendGoal)
                    .keyboardType(.decimalPad)
                Button("Save") {
                    guard let goal = Double(spendGoal) else {
                        errorStr = "Enter a valid amount"; errorPresented = true; return
                    }
                    APIService.shared.createCategory(name: name, spending_goal: goal) { result in
                        switch result {
                        case .success:
                            DispatchQueue.main.async { parent.fetchCategories() }
                        case .failure(let err):
                            DispatchQueue.main.async { errorStr = err.localizedDescription; errorPresented = true }
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert(errorStr ?? "Error creating category", isPresented: $errorPresented) {
                Button("OK", role: .cancel) { }
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
    
    // MARK: - Delete Category
    private func deleteCategory(at offsets: IndexSet) {
        let toDelete = offsets.map { categories[$0] }
        categories.remove(atOffsets: offsets)
        toDelete.forEach { category in
            APIService.shared.deleteCategory(categoryId: category.id) { result in
                DispatchQueue.main.async {
                    if case .failure(let err) = result {
                        errorMessage = err.localizedDescription
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Receipts
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let receipt = viewModel.receipts[index]
            viewModel.deleteReceipt(receipt)
        }
    }
    
    // MARK: - Fetch Categories
    private func fetchCategories() {
        APIService.shared.getCategories(year: year, month: month) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cats):
                    categories = cats
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
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
                    viewModel.receipts = list.receipts.map { preview in
                        Receipt(id: preview.id,
                                merchant: preview.merchant,
                                date: preview.date,
                                total: preview.total)
                    }
                case .failure(let err):
                    errorMessage = err.localizedDescription
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
