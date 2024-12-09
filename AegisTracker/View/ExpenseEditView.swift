//
//  ExpenseEditView.swift
//  Aegis
//
//  Created by Zach Wassynger on 12/8/24.
//

import SwiftData
import SwiftUI

struct ExpenseEditView: View {
    @Environment(\.modelContext) var modelContext
    
    private let expense: Expense
    private let mode: Mode
    
    @Binding private var path: [ViewType]
    
    // Main
    @State private var date: Date = .now
    @State private var amount: Int = 0
    @State private var payee: String = ""
    @State private var category: String = ""
    @State private var notes: String = ""
    @State private var type: DetailType? = nil
    // Tag
    @State private var tag: String = ""
    // Tip
    @State private var tip: Int = 0
    // Bill
    @State private var bills: [Expense.BillType] = []
    @State private var billTax: Int = 0
    // Food
    @State private var food: [Expense.GroceryList.Food] = []
    // Fuel
    @State private var fuel: Expense.FuelDetails = .init(amount: 0.0, rate: 0.0, user: "")
    
    init(path: Binding<[ViewType]>, expense: Expense? = nil) {
        self._path = path
        self.expense = expense ?? Expense(date: Date(), payee: "", amount: .Cents(0), category: "", notes: "", detailType: nil, details: .Generic(details: ""))
        mode = expense == nil ? .Add : .Edit
    }
    
    var body: some View {
        Form {
            DatePicker("Date:", selection: $date, displayedComponents: .date)
            HStack {
                Text("Amount:")
                CurrencyField(value: $amount)
            }
            HStack {
                Text("Payee:")
                TextField("", text: $payee).multilineTextAlignment(.trailing)
            }
            HStack {
                Text("Category:")
                TextField("", text: $category).multilineTextAlignment(.trailing)
            }
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...9)
            if type == nil {
                Menu {
                    ForEach(DetailType.allCases, id: \.rawValue) { type in
                        Button(type.getName()) {
                            self.type = type
                        }
                    }
                } label: {
                    Label("Add Additional Details...", systemImage: "plus")
                }
            }
            detailsView()
        }.navigationTitle(mode.getTitle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear(perform: tryLoad)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back", action: back)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: save)
                        .disabled(payee.isEmpty || amount <= 0 || category.isEmpty)
                }
            }
    }
    
    @ViewBuilder
    private func detailsView() -> some View {
        if let type {
            Section(type.getName()) {
                switch type {
                case .Tag:
                    HStack {
                        Text("Name:")
                        TextField("", text: $tag)
                    }
                case .Tip:
                    HStack {
                        Text("Amount:")
                        CurrencyField(value: $tip)
                    }
                case .Bill:
                    Text("Bill")
                case .Foods:
                    Text("Foods")
                case .Fuel:
                    let formatter = {
                        let formatter = NumberFormatter()
                        formatter.maximumFractionDigits = 6
                        formatter.zeroSymbol = ""
                        return formatter
                    }()
                    HStack {
                        Text("Gallons:")
                        TextField("required", value: $fuel.amount, formatter: formatter)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Rate:")
                        TextField("required", value: $fuel.rate, formatter: formatter)
                            .keyboardType(.decimalPad)
                    }
                    TextField("User", text: $fuel.user)
                }
                Button("Remove Additional Details", role: .destructive) {
                    self.type = nil
                }
            }
        }
    }
    
    private func back() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    private func tryLoad() {
        if mode == .Edit {
            date = expense.date
            payee = expense.payee
            amount = expense.amount.toCents()
            category = expense.category
            notes = expense.notes ?? ""
            switch expense.detailType {
            case .Tag(let name):
                type = .Tag
                tag = name
            case .Tip(let amount):
                type = .Tip
                tip = amount.toCents()
            case .Bill(let details):
                type = .Bill
                bills = details.types
                billTax = details.tax.toCents()
            case .Foods(let list):
                type = .Foods
                food = list.foods
            case .Fuel(let details):
                type = .Fuel
                fuel = details
            default:
                type = nil
            }
        }
    }
    
    private func save() {
        expense.date = date
        expense.payee = payee
        expense.amount = .Cents(amount)
        expense.category = category
        expense.notes = notes
        switch type {
        case .Tag:
            expense.detailType = .Tag(name: tag)
        case .Tip:
            expense.detailType = .Tip(amount: .Cents(tip))
        case .Bill:
            expense.detailType = .Bill(details: .init(types: bills, tax: .Cents(billTax)))
        case .Foods:
            expense.detailType = .Foods(list: .init(foods: food))
        case .Fuel:
            expense.detailType = .Fuel(details: fuel)
        default:
            break
        }
        if mode == .Add {
            modelContext.insert(expense)
        }
        back()
    }
    
    enum Mode {
        case Add
        case Edit
        
        func getTitle() -> String {
            switch self {
            case .Add:
                "Add Expense"
            case .Edit:
                "Edit Expense"
            }
        }
    }
    
    enum DetailType: String, CaseIterable {
        case Tag
        case Tip
        case Bill
        case Foods
        case Fuel
        
        func getName() -> String {
            switch self {
            case .Tag:
                "Sub-Category"
            case .Tip:
                "Tip"
            case .Bill:
                "Utility Bill"
            case .Foods:
                "Foods"
            case .Fuel:
                "Gas"
            }
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    return NavigationStack {
        ExpenseEditView(path: .constant([]))
    }.modelContainer(container)
}
