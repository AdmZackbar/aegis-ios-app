//
//  EditExpenseView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/12/24.
//

import SwiftUI

private enum Mode {
    case Add, Edit
}

private struct ExpenseInfo {
    var date: Date = Date()
    var payee: String = ""
    var amount: Int = 0
    var category: String = ""
}

private struct CategoryInfo {
    let payee: String
    let amount: String
    let type: CategoryType
}

private enum CategoryType {
    case Generic(detailName: String, required: Bool = false)
    case Gas
}

private let categoryInfo: [String : CategoryInfo] = {
    var map: [String : CategoryInfo] = [:]
    map["Gas"] = CategoryInfo(payee: "Gas Station", amount: "Total Cost", type: .Gas)
    map["Computer Hardware"] = CategoryInfo(payee: "Manufacturer", amount: "Price", type: .Generic(detailName: "Name", required: true))
    map["Computer Software"] = CategoryInfo(payee: "Company", amount: "Price", type: .Generic(detailName: "Name", required: true))
    map["Mortgage Bill"] = CategoryInfo(payee: "Lender", amount: "Amount", type: .Generic(detailName: "Billing Month"))
    map["Mortgage Payment"] = CategoryInfo(payee: "Lender", amount: "Amount", type: .Generic(detailName: "Details"))
    return map
}()

struct EditExpenseView: View {
    @Environment(\.modelContext) var modelContext
    
    private let expense: Expense
    private let mode: Mode
    
    private let currencyFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    @Binding private var path: [ViewType]
    
    @State private var info: ExpenseInfo = ExpenseInfo()
    @State private var genericDetails: GenericExpenseView.Details = GenericExpenseView.Details()
    @State private var gasDetails: GasExpenseView.Details = GasExpenseView.Details()
    
    init(path: Binding<[ViewType]>, expense: Expense? = nil) {
        self._path = path
        self.expense = expense ?? Expense(date: Date(), payee: "", amount: .Cents(0), category: "", details: .Generic(details: ""))
        mode = expense == nil ? .Add : .Edit
    }
    
    var body: some View {
        Form {
            if info.category.isEmpty {
                categoryView()
            } else {
                Section {
                    DatePicker("Date:", selection: $info.date, displayedComponents: .date)
                    let info = categoryInfo[info.category, default: CategoryInfo(payee: "Seller", amount: "Amount", type: .Generic(detailName: "Details"))]
                    payeeTextField(info.payee)
                    amountTextField(info.amount)
                    switch info.type {
                    case .Generic(let detailName, let required):
                        GenericExpenseView(details: $genericDetails, placeholder: detailName, required: required)
                    case .Gas:
                        GasExpenseView(details: $gasDetails)
                    }
                } header: {
                    HStack {
                        Text(info.category)
                        Button {
                            info.category = ""
                        } label: {
                            Label("Edit", systemImage: "pencil.circle").labelStyle(.iconOnly)
                        }
                    }
                }
            }
        }.navigationTitle(mode == .Add ? "Add Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear(perform: tryLoad)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back", action: back)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: save)
                        .disabled(info.payee.isEmpty || info.amount <= 0 || info.category.isEmpty)
                }
            }
    }
    
    private func payeeTextField(_ placeholder: String) -> some View {
        HStack {
            Text("\(placeholder):")
            TextField("required", text: $info.payee)
        }
    }
    
    private func amountTextField(_ placeholder: String) -> some View {
        HStack {
            Text("\(placeholder):")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $info.amount)
        }
    }
    
    private func back() {
        if info.category.isEmpty && !expense.category.isEmpty {
            info.category = expense.category
        } else if !path.isEmpty {
            path.removeLast()
        }
    }
    
    private func tryLoad() {
        if mode == .Edit {
            info.date = expense.date
            info.payee = expense.payee
            switch expense.amount {
            case .Cents(let amount):
                info.amount = amount
            }
            info.category = expense.category
            genericDetails = GenericExpenseView.Details.fromExpense(expense.details)
            gasDetails = GasExpenseView.Details.fromExpense(expense.details)
        }
    }
    
    private func save() {
        expense.date = info.date
        expense.payee = info.payee
        expense.amount = .Cents(info.amount)
        expense.category = info.category
        expense.details = computeDetails()
        if mode == .Add {
            modelContext.insert(expense)
        }
        back()
    }
    
    private func computeDetails() -> Expense.Details {
        switch categoryInfo[info.category]?.type ?? .Generic(detailName: "") {
        case .Generic(_, _):
            return genericDetails.toExpense()
        case .Gas:
            return gasDetails.toExpense()
        }
    }
    
    private let categories: [String : [String]] = {
        var map: [String : [String]] = [:]
        map["Food"] = ["Groceries", "Fast Food", "Restaurant"]
        map["Housing"] = ["Mortgage Bill", "Mortgage Payment", "Housing Maintenance", "Housing Utilities"]
        map["Car"] = ["Gas", "Car Maintenance", "Car Fees"]
        map["Media"] = ["Video Games", "Music", "Movies", "Games"]
        map["Technology"] = ["Computer Hardware", "Computer Software"]
        map["Other"] = ["Charity", "Gift"]
        return map
    }()
    
    private func categoryView() -> some View {
        ForEach(categories.sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { header, children in
            Section(header) {
                ForEach(children, id: \.hashValue) { child in
                    Button(child) {
                        info.category = child
                    }.tint(.primary)
                }
            }
        }
    }
}

private struct GenericExpenseView: View {
    let placeholder: String
    let required: Bool
    
    @Binding private var details: Details
    
    init(details: Binding<Details>, placeholder: String, required: Bool = false) {
        self._details = details
        self.placeholder = placeholder
        self.required = required
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(placeholder):")
            TextField(required ? "required" : "optional", text: $details.details, axis: .vertical)
                .lineLimit(2...8)
        }
    }
    
    struct Details {
        var details: String = ""
        
        static func fromExpense(_ details: Expense.Details) -> Details {
            switch details {
            case .Generic(let str):
                return Details(details: str)
            default:
                return Details()
            }
        }
        
        func toExpense() -> Expense.Details {
            .Generic(details: details)
        }
    }
}

private struct GasExpenseView: View {
    static let OctaneValues: [Int] = [87, 89, 91, 93]
    
    private let formatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        formatter.zeroSymbol = ""
        return formatter
    }()
    private let currencyFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    @Binding private var details: Details
    
    init(details: Binding<Details>) {
        self._details = details
    }
    
    var body: some View {
        HStack {
            Text("Gallons:")
            TextField("required", value: $details.gallons, formatter: formatter)
                .keyboardType(.decimalPad)
        }
        HStack {
            Text("Rate:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $details.price)
        }
        HStack {
            Text("Octane:")
            Picker("", selection: $details.octane) {
                ForEach(GasExpenseView.OctaneValues, id: \.hashValue) { value in
                    Text("\(value)").tag(value)
                }
            }.pickerStyle(.segmented)
        }
    }
    
    struct Details {
        var gallons: Double = 0.0
        var price: Int = 0
        var octane: Int = 87
        
        static func fromExpense(_ details: Expense.Details) -> Details {
            switch details {
            case .Gas(let gallons, let price, let octane):
                switch price {
                case .Cents(let cents):
                    return Details(gallons: gallons, price: cents, octane: octane)
                }
            default:
                return Details()
            }
        }
        
        func toExpense() -> Expense.Details {
            .Gas(numGallons: gallons, costPerGallon: .Cents(price), octane: octane)
        }
    }
}

#Preview {
    NavigationStack {
        EditExpenseView(path: .constant([]))
    }
}
