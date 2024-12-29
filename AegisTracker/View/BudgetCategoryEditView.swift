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
    
    @State private var name: String = ""
    @State private var hasColor: Bool = false
    @State private var color: Color = .gray
    @State private var hasBudget: Bool = false
    @State private var amount: Int = 0
    @State private var sheetType: SheetType? = nil
    @State private var showAddAlert: Bool = false
    @State private var childName: String = ""
    @State private var showAssetAlert: Bool = false
    @State private var assetName: String = ""
    @State private var selectedData: CategoryData? = nil
    
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
                        sheetType = .main
                    } label: {
                        Text("Edit")
                    }
                }
            }.headerProminence(.increased)
            budgetView()
            subcategoryView()
        }.navigationTitle(category.parent == nil ? "View Budget" : "View Category")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: load)
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
                case .main:
                    NavigationStack {
                        MainEditView(name: $name, hasColor: $hasColor, color: $color)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel", action: hideSheet)
                                }
                                ToolbarItem(placement: .primaryAction) {
                                    Button("Save") {
                                        category.name = name
                                        category.color = hasColor ? color : nil
                                        hideSheet()
                                    }
                                }
                            }
                    }.presentationDetents([.medium])
                case .budget:
                    NavigationStack {
                        BudgetEditView(children: category.children ?? [], hasBudget: $hasBudget, amount: $amount)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel", action: hideSheet)
                                }
                                ToolbarItem(placement: .primaryAction) {
                                    Button("Save") {
                                        category.amount = hasBudget ? .Cents(amount) : nil
                                        hideSheet()
                                    }
                                }
                            }
                    }.presentationDetents([.medium])
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
                        CategoryPieChart(categories: children, data: data, selectedData: $selectedData)
                            .frame(height: 180)
                    }
                }
            }
        } header: {
            HStack {
                Text("Budget")
                Spacer()
                Button {
                    sheetType = .budget
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
    
    private func load() {
        name = category.name
        hasColor = category.color != nil
        color = category.color ?? .gray
        hasBudget = category.amount != nil
        amount = category.amount?.toCents() ?? 0
    }
    
    private enum SheetType: String, Identifiable {
        var id: String {
            rawValue
        }
        
        case main
        case budget
    }
    
    private struct MainEditView: View {
        @Binding private var name: String
        @Binding private var hasColor: Bool
        @Binding private var color: Color
        
        init(name: Binding<String>, hasColor: Binding<Bool>, color: Binding<Color>) {
            self._name = name
            self._hasColor = hasColor
            self._color = color
        }
        
        var body: some View {
            Form {
                HStack {
                    Text("Name:")
                    TextField("required", text: $name)
                }
                Toggle("Custom Color:", isOn: $hasColor)
                if hasColor {
                    ColorPicker("Color:", selection: $color)
                }
            }.navigationTitle("Edit Main Information")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
        }
    }
    
    private struct BudgetEditView: View {
        let children: [BudgetCategory]
        
        @Binding private var hasBudget: Bool
        @Binding private var amount: Int
        
        init(children: [BudgetCategory], hasBudget: Binding<Bool>, amount: Binding<Int>) {
            self.children = children
            self._hasBudget = hasBudget
            self._amount = amount
        }
        
        var body: some View {
            Form {
                Section("Monthly Budget") {
                    if !children.isEmpty {
                        Text("Per Month: \(computeBudget())")
                        Toggle(isOn: $hasBudget) {
                            HStack {
                                Text("Additional:")
                                if hasBudget {
                                    CurrencyField(value: $amount)
                                } else {
                                    Text("None")
                                }
                            }
                        }
                    } else {
                        Toggle(isOn: $hasBudget) {
                            HStack {
                                Text("Amount:")
                                if hasBudget {
                                    CurrencyField(value: $amount)
                                } else {
                                    Text(computeBudget())
                                }
                            }
                        }
                    }
                }
            }.navigationTitle("Edit Budget")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
        }
        
        private func computeBudget() -> String {
            if let childrenTotal = children.total {
                return (childrenTotal + .Cents(hasBudget ? amount : 0)).toString()
            }
            return hasBudget ? Price.Cents(amount).toString() : "N/A"
        }
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
