//
//  BudgetCategoryEditView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/23/24.
//

import SwiftData
import SwiftUI

struct BudgetCategoryEditView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    private let category: BudgetCategory
    
    @State private var sheetType: BudgetCategoryWrapper.SheetType? = nil
    @State private var showAddAlert: Bool = false
    @State private var childName: String = ""
    @State private var showAssetAlert: Bool = false
    @State private var assetName: String = ""
    @State private var selectedCategory: BudgetCategory? = nil
    
    init(category: BudgetCategory) {
        self.category = category
    }
    
    var body: some View {
        Form {
            Section {
                Text("Name: \(category.name)")
                if category.parent != nil {
                    HStack {
                        Text("Color:")
                        Text(category.color?.hexString ?? "Default")
                            .foregroundStyle(category.color ?? .primary)
                    }
                }
            } header: {
                HStack {
                    Text("Main")
                    Spacer()
                    Button {
                        sheetType = .main(category)
                    } label: {
                        Text("Edit")
                    }
                }
            }.headerProminence(.increased)
            budgetView()
            subcategoryView()
        }.navigationTitle(category.parent == nil ? "View Budget" : "View Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        assetName = category.assetType ?? ""
                        showAssetAlert = true
                    } label: {
                        Label("Set Asset Category", systemImage: "pencil")
                    }
                }
            }
            .alert("Add Subcategory", isPresented: $showAddAlert) {
                TextField("Name", text: $childName)
                    .textInputAutocapitalization(.words)
                Button("Cancel") {
                    showAddAlert = false
                }
                Button("Save", action: addSubcategory)
                    .disabled(childName.isEmpty)
            }
            .alert("Set Asset Name", isPresented: $showAssetAlert) {
                TextField("Name", text: $assetName)
                    .textInputAutocapitalization(.words)
                Button("Cancel") {
                    showAssetAlert = false
                }
                Button("Save", action: setAssetName)
            }
            .sheet(item: $sheetType) { sheet in
                switch sheet {
                case .main(let category):
                    BudgetCategoryEditMainSheet(category: .init(category: category), sheetType: $sheetType)
                case .budget(let category):
                    BudgetCategoryEditBudgetSheet(category: .init(category: category), sheetType: $sheetType)
                }
            }
    }
    
    private func hideSheet() {
        sheetType = nil
    }
    
    @ViewBuilder
    private func budgetView() -> some View {
        Section {
            VStack(alignment: .leading) {
                Text("Monthly Amount: \(category.monthlyBudget?.toString() ?? "N/A")")
                if let children = category.children, children.map({ $0.monthlyBudget?.toCents() ?? 0 }).reduce(0, +) > 0 {
                    let data: [CategoryData] = {
                        let data: [CategoryData] = children.map({ .init(category: $0.name, amount: $0.monthlyBudget ?? .Cents(0)) })
                        if let otherAmount = category.amount {
                            return data + [.init(category: category.parent == nil ? "Other" : category.name, amount: otherAmount)]
                        }
                        return data
                    }()
                    Section {
                        CategoryPieChart(categories: children, data: data, selectedCategory: $selectedCategory)
                            .frame(height: 180)
                    }
                }
            }
        } header: {
            HStack {
                Text("Budget")
                Spacer()
                Button {
                    sheetType = .budget(category)
                } label: {
                    Text("Edit")
                }
            }
        }.headerProminence(.increased)
    }
    
    @ViewBuilder
    private func subcategoryView() -> some View {
        Section {
            let sorted = (category.children ?? [])
                .sorted(by: { $0.name < $1.name })
                .sorted(by: { ($0.monthlyBudget ?? .Cents(0)) > ($1.monthlyBudget ?? .Cents(0)) })
            ForEach(sorted, id: \.hashValue) { child in
                Button {
                    navigationStore.push(ExpenseViewType.editCategory(category: child))
                } label: {
                    HStack {
                        Text(child.name)
                            .foregroundStyle(child.color ?? .primary)
                        Spacer()
                        if let budget = child.monthlyBudget {
                            Text(budget.toString())
                        }
                    }.bold().contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit Name/Color") {
                            sheetType = .main(child)
                        }
                        Button("Edit Budget Amount") {
                            sheetType = .budget(child)
                        }
                    }
            }.onDelete { indices in
                for index in indices {
                    modelContext.delete(sorted[index])
                }
            }
        } header: {
            HStack {
                Text(category.parent == nil ? "Categories" : "Subcategories")
                Spacer()
                Button {
                    childName = ""
                    showAddAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }.headerProminence(.increased)
    }
    
    private func addSubcategory() {
        let child = BudgetCategory(name: childName)
        child.parent = category
        modelContext.insert(child)
        showAddAlert = false
    }
    
    private func setAssetName() {
        category.assetType = assetName.isEmpty ? nil : assetName
        assetName = ""
        showAssetAlert = false
    }
}

struct BudgetCategoryWrapper {
    private var category: BudgetCategory
    
    var name: String
    var hasColor: Bool
    var color: Color
    var hasBudget: Bool
    var amount: Int
    var children: [BudgetCategory]?
    
    init(category: BudgetCategory) {
        self.category = category
        name = category.name
        hasColor = category.color != nil
        color = category.color ?? .gray
        hasBudget = category.amount != nil
        amount = category.amount?.toCents() ?? 0
        children = category.children
    }
    
    mutating func save() {
        category.name = name
        category.color = hasColor ? color : nil
        category.amount = hasBudget ? .Cents(amount) : nil
        category.children = children
    }
    
    enum SheetType: Identifiable {
        var id: String {
            switch self {
            case .main(_):
                "Main"
            case .budget(_):
                "Budget"
            }
        }
        
        case main(_ category: BudgetCategory)
        case budget(_ category: BudgetCategory)
    }
}

struct BudgetCategoryEditMainSheet: View {
    @Binding private var sheetType: BudgetCategoryWrapper.SheetType?
    @State private var category: BudgetCategoryWrapper
    
    init(category: BudgetCategoryWrapper, sheetType: Binding<BudgetCategoryWrapper.SheetType?>) {
        self.category = category
        self._sheetType = sheetType
    }
    
    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Text("Name:")
                    TextField("required", text: $category.name)
                }
                Toggle("Custom Color:", isOn: $category.hasColor)
                if category.hasColor {
                    ColorPicker("Color:", selection: $category.color)
                }
            }.navigationTitle("Edit Category")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: hide)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            category.save()
                            hide()
                        }
                    }
                }
        }.presentationDetents([.medium])
    }
    
    private func hide() {
        sheetType = nil
    }
}

struct BudgetCategoryEditBudgetSheet: View {
    @Binding private var sheetType: BudgetCategoryWrapper.SheetType?
    @State private var category: BudgetCategoryWrapper
    
    init(category: BudgetCategoryWrapper, sheetType: Binding<BudgetCategoryWrapper.SheetType?>) {
        self.category = category
        self._sheetType = sheetType
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Monthly Budget") {
                    let hasChildBudgets: Bool = {
                        if let children = category.children {
                            return children.map({ $0.monthlyBudget?.toCents() ?? 0 }).reduce(0, +) > 0
                        }
                        return false
                    }()
                    if hasChildBudgets {
                        Text("Per Month: \(computeBudget())")
                    }
                    Toggle(isOn: $category.hasBudget) {
                        HStack {
                            Text(hasChildBudgets ? "Additional:" : "Amount:")
                            if category.hasBudget {
                                CurrencyField(value: $category.amount)
                            } else {
                                Text(hasChildBudgets ? "None" : "N/A")
                            }
                        }
                    }
                }
            }.navigationTitle("Edit Category")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: hide)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            category.save()
                            hide()
                        }
                    }
                }
        }.presentationDetents([.medium])
    }
    
    private func computeBudget() -> String {
        if let childrenTotal = category.children?.total {
            return (childrenTotal + .Cents(category.hasBudget ? category.amount : 0)).toString()
        }
        return category.hasBudget ? Price.Cents(category.amount).toString() : "N/A"
    }
    
    private func hide() {
        sheetType = nil
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    @Previewable @Environment(\.modelContext) var modelContext
    var query = FetchDescriptor<BudgetCategory>(predicate: #Predicate { $0.parent == nil })
    query.fetchLimit = 1
    let category: BudgetCategory = try! modelContext.fetch(query).first!
    return NavigationStack(path: $navigationStore.path) {
        BudgetCategoryEditView(category: category)
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
