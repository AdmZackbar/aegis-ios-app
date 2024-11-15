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
    
    init(payee: String = "Payee", amount: String = "Amount", type: CategoryType = .Generic()) {
        self.payee = payee
        self.amount = amount
        self.type = type
    }
}

private enum CategoryType {
    case Generic(detail: String = "Details")
    case Tag(tag: String, detail: String = "Details")
    case Gas
    case Tip
    case Bill
    case Grocery
}

private let categoryInfo: [String : CategoryInfo] = {
    var map: [String : CategoryInfo] = [:]
    // Car
    map["Gas"] = .init(payee: "Gas Station", amount: "Total Cost", type: .Gas)
    map["Car Maintenance"] = .init(payee: "Seller", amount: "Price")
    map["Car Insurance"] = .init(payee: "Company", amount: "Bill", type: .Generic(detail: "Time Period"))
    map["Car Payment"] = .init(payee: "Seller")
    map["Parking"] = .init(payee: "Location")
    // Food
    map["Groceries"] = .init(payee: "Store", amount: "Total Cost", type: .Grocery)
    map["Snacks"] = .init(payee: "Store", amount: "Total Cost", type: .Grocery)
    map["Restaurants"] = .init(payee: "Restaurant", amount: "Bill", type: .Tip)
    map["Fast Food"] = .init(payee: "Restaurant", amount: "Cost")
    map["Cookware"] = .init(payee: "Seller", amount: "Total Cost")
    map["Grocery Membership"] = .init(payee: "Store", amount: "Price", type: .Generic(detail: "Time Period"))
    // Housing
    map["Rent"] = .init(payee: "Landlord", type: .Generic(detail: "Time Period"))
    map["Mortgage Bill"] = .init(payee: "Lender", type: .Generic(detail: "Time Period"))
    map["Housing Payment"] = .init(payee: "Recipient")
    map["Utility Bill"] = .init(payee: "Company", amount: "Total Cost", type: .Bill)
    map["Housing Maintenance"] = .init(payee: "Seller", amount: "Cost")
    map["Appliances"] = .init(payee: "Seller", amount: "Total Cost")
    map["Furniture"] = .init(payee: "Seller", amount: "Total Cost")
    map["Decor"] = .init(payee: "Seller", amount: "Total Cost")
    // Media
    map["Video Games"] = .init(payee: "Platform", amount: "Price")
    map["Music"] = .init(payee: "Platform", amount: "Price")
    map["TV"] = .init(payee: "Platform", amount: "Price")
    map["Books"] = .init(payee: "Seller", amount: "Price")
    map["Games"] = .init(payee: "Seller", amount: "Price")
    map["Other Media"] = .init(payee: "Seller", amount: "Price")
    // Medical
    map["Dental"] = .init(amount: "Total Cost")
    map["Vision"] = .init(amount: "Total Cost")
    map["Medicine"] = .init(payee: "Seller", amount: "Total Cost")
    map["Clinic"] = .init(payee: "Clinic", amount: "Total Cost")
    map["Physical Therapy"] = .init(payee: "Clinic", amount: "Total Cost")
    map["Hospital"] = .init(payee: "Hospital", amount: "Total Cost")
    // Personal
    map["Apparel"] = .init(payee: "Seller", amount: "Price")
    map["Hygiene"] = .init(payee: "Seller", amount: "Price")
    map["Haircut"] = .init(payee: "Barbershop", amount: "Total Cost", type: .Tip)
    // Recreation
    map["Sports Facility"] = .init(amount: "Total Cost", type: .Tag(tag: "Sport"))
    map["Sports Gear"] = .init(payee: "Seller", amount: "Price", type: .Tag(tag: "Sport"))
    map["Sports Event"] = .init(payee: "Organization", amount: "Price", type: .Tag(tag: "Sport"))
    map["Recreation Event"] = .init(payee: "Organization", amount: "Price")
    // Technology
    map["Tech Devices"] = .init(payee: "Seller", amount: "Price")
    map["Device Accessories"] = .init(payee: "Seller", amount: "Price")
    map["Computer Parts"] = .init(payee: "Seller", amount: "Price")
    map["Peripherals"] = .init(payee: "Seller", amount: "Price")
    map["Software"] = .init(payee: "Seller", amount: "Price")
    map["Tech Service"] = .init(payee: "Seller", amount: "Price")
    map["Digital Assets"] = .init(payee: "Seller", amount: "Price")
    // Travel
    map["Accommodations"] = .init(payee: "Company", amount: "Total Cost")
    map["Rental Car"] = .init(payee: "Company", amount: "Total Cost")
    map["Airfare"] = .init(payee: "Company", amount: "Total Cost")
    map["Rideshare"] = .init(payee: "Company", amount: "Total Cost", type: .Tip)
    // Other
    map["Gift"] = .init(payee: "Recipient")
    map["Charity"] = .init(payee: "Organization")
    map["Taxes"] = .init(payee: "Type", amount: "Total Amount", type: .Generic(detail: "Time Period"))
    map["Contributions"] = .init(payee: "Bank")
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
    @State private var tagDetails: TagExpenseView.Details = TagExpenseView.Details()
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
                    let info = categoryInfo[info.category, default: .init()]
                    payeeTextField(info.payee)
                    amountTextField(info.amount)
                    detailsView(info.type)
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
    
    @ViewBuilder
    private func detailsView(_ type: CategoryType) -> some View {
        switch type {
        case .Generic(let detail):
            GenericExpenseView(details: $genericDetails, placeholder: detail)
        case .Tag(let tag, let detail):
            TagExpenseView(details: $tagDetails, tagPlaceholder: tag, detailPlaceholder: detail)
        case .Gas:
            GasExpenseView(details: $gasDetails)
        // TODO
        default:
            GenericExpenseView(details: $genericDetails, placeholder: "Details")
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
        switch categoryInfo[info.category]?.type ?? .Generic(detail: "") {
        case .Generic(_):
            return genericDetails.toExpense()
        case .Tag(_, _):
            return tagDetails.toExpense()
        case .Gas:
            return gasDetails.toExpense()
        // TODO
        default:
            return genericDetails.toExpense()
        }
    }
    
    private let categories: [String : [String]] = {
        var map: [String : [String]] = [:]
        map["Car"] = ["Gas", "Car Maintenance", "Car Insurance", "Car Payment", "Parking"]
        map["Food"] = ["Groceries", "Snacks", "Restaurant", "Fast Food", "Cookware", "Grocery Membership"]
        map["Housing"] = ["Rent", "Mortgage Bill", "Housing Payment", "Utility Bill", "Housing Maintenance", "Appliances", "Furniture", "Decor"]
        map["Media"] = ["Video Games", "Music", "TV", "Books", "Games", "Other Media"]
        map["Medicine"] = ["Dental", "Vision", "Medicine", "Clinic", "Physical Therapy", "Hospital"]
        map["Personal"] = ["Apparel", "Hygiene", "Haircut"]
        map["Recreation"] = ["Sports Facility", "Sports Gear", "Sports Event", "Recreation Event"]
        map["Technology"] = ["Tech Devices", "Device Accessories", "Computer Parts", "Peripherals", "Software", "Tech Service", "Digital Assets"]
        map["Travel"] = ["Accomodations", "Rental Car", "Airfare", "Rideshare"]
        map["Other"] = ["Gift", "Charity", "Taxes", "Contributions"]
        return map
    }()
    
    private func categoryView() -> some View {
        Section("Select Category") {
            ForEach(categories.sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { header, children in
                Menu {
                    ForEach(children, id: \.hashValue) { child in
                        Button(child) {
                            info.category = child
                        }
                    }
                } label: {
                    HStack {
                        Text(header).tint(.primary)
                        Spacer()
                    }.clipShape(Rectangle())
                }
            }
        }
    }
}

private struct GenericExpenseView: View {
    let placeholder: String
    
    @Binding private var details: Details
    
    init(details: Binding<Details>, placeholder: String) {
        self._details = details
        self.placeholder = placeholder
    }
    
    var body: some View {
        TextField(placeholder, text: $details.details, axis: .vertical)
            .lineLimit(3...9)
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

private struct TagExpenseView: View {
    let tagPlaceholder: String
    let detailPlaceholder: String
    
    @Binding private var details: Details
    
    init(details: Binding<Details>, tagPlaceholder: String, detailPlaceholder: String) {
        self._details = details
        self.tagPlaceholder = tagPlaceholder
        self.detailPlaceholder = detailPlaceholder
    }
    
    var body: some View {
        TextField(tagPlaceholder, text: $details.tag)
        TextField(detailPlaceholder, text: $details.details, axis: .vertical)
            .lineLimit(3...9)
    }
    
    struct Details {
        var tag: String = ""
        var details: String = ""
        
        static func fromExpense(_ details: Expense.Details) -> Details {
            switch details {
            case .Tag(let tag, let str):
                return Details(tag: tag, details: str)
            default:
                return Details()
            }
        }
        
        func toExpense() -> Expense.Details {
            .Tag(tag: tag, details: details)
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
        var user: String = ""
        
        static func fromExpense(_ details: Expense.Details) -> Details {
            switch details {
            case .Gas(let gallons, let price, let octane, let user):
                switch price {
                case .Cents(let cents):
                    return Details(gallons: gallons, price: cents, octane: octane, user: user)
                }
            default:
                return Details()
            }
        }
        
        func toExpense() -> Expense.Details {
            .Gas(amount: gallons, rate: .Cents(price), octane: octane, user: user)
        }
    }
}

#Preview {
    NavigationStack {
        EditExpenseView(path: .constant([]))
    }
}
