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
    case Fuel(validTypes: [String] = ["Gas", "Propane"])
    case Tip
    case Bill
    case Grocery
}

private let categoryInfo: [String : CategoryInfo] = {
    var map: [String : CategoryInfo] = [:]
    // Car
    map["Gas"] = .init(payee: "Gas Station", amount: "Total Cost", type: .Fuel(validTypes: ["Gas"]))
    map["Car Maintenance"] = .init(payee: "Seller", amount: "Price")
    map["Car Insurance"] = .init(payee: "Company", amount: "Bill", type: .Generic(detail: "Time Period"))
    map["Car Payment"] = .init(payee: "Seller")
    map["Parking"] = .init(payee: "Location")
    // Food
    map["Groceries"] = .init(payee: "Store", amount: "Total Cost", type: .Grocery)
    map["Snacks"] = .init(payee: "Store", amount: "Total Cost", type: .Grocery)
    map["Restaurant"] = .init(payee: "Restaurant", amount: "Bill", type: .Tip)
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
    map["Fuel"] = .init(payee: "Station", amount: "Total Cost", type: .Fuel())
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
    @State private var fuelDetails: FuelExpenseView.Details = FuelExpenseView.Details()
    @State private var tipDetails: TipExpenseView.Details = TipExpenseView.Details()
    @State private var billDetails: BillExpenseView.Details = BillExpenseView.Details()
    @State private var groceryDetails: GroceryExpenseView.Details = GroceryExpenseView.Details()
    
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
        case .Fuel(let validTypes):
            FuelExpenseView(details: $fuelDetails, validTypes: validTypes)
        case .Tip:
            TipExpenseView(details: $tipDetails, detailPlaceholder: "Details")
        case .Bill:
            BillExpenseView(details: $billDetails, detailPlaceholder: "Details")
        case .Grocery:
            GroceryExpenseView(details: $groceryDetails)
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
            tagDetails = TagExpenseView.Details.fromExpense(expense.details)
            fuelDetails = FuelExpenseView.Details.fromExpense(expense.details)
            tipDetails = TipExpenseView.Details.fromExpense(expense.details)
            billDetails = BillExpenseView.Details.fromExpense(expense.details)
            groceryDetails = GroceryExpenseView.Details.fromExpense(expense.details)
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
        case .Fuel:
            return fuelDetails.toExpense()
        case .Tip:
            return tipDetails.toExpense()
        case .Bill:
            return billDetails.toExpense()
        case .Grocery:
            return groceryDetails.toExpense()
        }
    }
    
    private func categoryView() -> some View {
        Section("Select Category") {
            ForEach(MainView.ExpenseCategories.sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { header, children in
                Menu {
                    ForEach(children, id: \.hashValue) { child in
                        Button(child) {
                            info.category = child
                        }
                    }
                } label: {
                    HStack {
                        Text(header)
                        Spacer()
                    }.frame(height: 36).contentShape(Rectangle())
                }.buttonStyle(.plain)
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
            case .Generic(let details):
                return Details(details: details)
            case .Tip(_, let details):
                return Details(details: details)
            case .Bill(let details):
                return Details(details: details.details)
            default:
                return Details()
            }
        }
        
        func toExpense() -> Expense.Details {
            .Tag(tag: tag, details: details)
        }
    }
}

private struct FuelExpenseView: View {
    let validTypes: [String]
    
    static let GasUsers: [String] = ["Personal Car", "Tools", "Other"]
    static let PropaneUsers: [String] = ["Grill", "Other"]
    
    private let formatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.zeroSymbol = ""
        return formatter
    }()
    
    @Binding private var details: Details
    
    init(details: Binding<Details>, validTypes: [String] = ["Gas", "Propane"]) {
        self._details = details
        self.validTypes = validTypes
        if !validTypes.contains(details.wrappedValue.type) {
            details.wrappedValue.type = validTypes.first ?? ""
        }
    }
    
    var body: some View {
        HStack {
            Text("Gallons:")
            TextField("required", value: $details.gallons, formatter: formatter)
                .keyboardType(.decimalPad)
        }
        HStack {
            Text("Rate:")
            TextField("required", value: $details.rate, formatter: formatter)
                .keyboardType(.decimalPad)
        }
        if validTypes.count > 1 {
            Picker("Type", selection: $details.type) {
                ForEach(validTypes, id: \.hashValue) { type in
                    Text(type).tag(type)
                }
            }.pickerStyle(.segmented)
        } else if validTypes.isEmpty {
            TextField("Type", text: $details.type)
        }
        if details.type == "Gas" {
            Picker("", selection: $details.user) {
                ForEach(FuelExpenseView.GasUsers, id: \.hashValue) { user in
                    Text(user).tag(user)
                }
            }.pickerStyle(.segmented)
        } else if details.type == "Propane" {
            Picker("", selection: $details.user) {
                ForEach(FuelExpenseView.PropaneUsers, id: \.hashValue) { user in
                    Text(user).tag(user)
                }
            }.pickerStyle(.segmented)
        } else {
            TextField("User", text: $details.user)
        }
    }
    
    struct Details {
        var gallons: Double = 0.0
        var rate: Double = 0.0
        var type: String = "Gas"
        var user: String = "Personal Car"
        
        static func fromExpense(_ details: Expense.Details) -> Details {
            switch details {
            case .Fuel(let gallons, let rate, let type, let user):
                return Details(gallons: gallons, rate: rate, type: type, user: user)
            default:
                return Details()
            }
        }
        
        func toExpense() -> Expense.Details {
            .Fuel(amount: gallons, rate: rate, type: type, user: user)
        }
    }
}

private struct TipExpenseView: View {
    let detailPlaceholder: String
    
    @Binding private var details: Details
    
    private let currencyFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    init(details: Binding<Details>, detailPlaceholder: String) {
        self._details = details
        self.detailPlaceholder = detailPlaceholder
    }
    
    var body: some View {
        HStack {
            Text("Tip:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $details.tip)
        }
        TextField(detailPlaceholder, text: $details.details, axis: .vertical)
            .lineLimit(3...9)
    }
    
    struct Details {
        var tip: Int = 0
        var details: String = ""
        
        static func fromExpense(_ details: Expense.Details) -> Details {
            switch details {
            case .Tip(let tip, let str):
                switch tip {
                case .Cents(let amount):
                    return Details(tip: amount, details: str)
                }
            case .Generic(let details):
                return Details(details: details)
            case .Tag(_, let details):
                return Details(details: details)
            case .Bill(let details):
                return Details(details: details.details)
            default:
                return Details()
            }
        }
        
        func toExpense() -> Expense.Details {
            .Tip(tip: .Cents(tip), details: details)
        }
    }
}

private struct BillExpenseView: View {
    enum BillType: Codable, Equatable, Hashable {
        case Flat
        case Variable
    }
    
    let detailPlaceholder: String
    
    @Binding private var details: Details
    @State private var typeDetails: TypeDetails = TypeDetails()
    @State private var itemIndex: Int = -1
    @State private var sheetShowing: Bool = false
    
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
    
    init(details: Binding<Details>, detailPlaceholder: String) {
        self._details = details
        self.detailPlaceholder = detailPlaceholder
    }
    
    var body: some View {
        HStack {
            Text("Tax:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $details.tax)
        }
        TextField(detailPlaceholder, text: $details.details, axis: .vertical)
            .lineLimit(3...9)
        ForEach(details.types, id: \.hashValue) { type in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.name).bold()
                    Text("Base Charge: \(Price.Cents(type.base).toString())")
                        .font(.subheadline).italic()
                    if type.type == .Variable {
                        Text("Amount: \(type.amount.formatted())").font(.caption).italic()
                        Text("Rate: \(type.rate.formatted())").font(.caption).italic()
                    }
                }
                Spacer()
                Button("Edit") {
                    itemIndex = details.types.firstIndex(of: type)!
                    typeDetails = type
                    sheetShowing = true
                }
            }
        }
        Button("Add Charge") {
            typeDetails = TypeDetails()
            itemIndex = -1
            sheetShowing = true
        }.sheet(isPresented: $sheetShowing) {
            NavigationStack {
                Form {
                    BillTypeView(typeDetails: $typeDetails)
                }.navigationTitle(itemIndex < 0 ? "Add Bill" : "Edit Bill")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                sheetShowing = false
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button("Save") {
                                if itemIndex >= 0 && itemIndex < details.types.count {
                                    details.types[itemIndex] = typeDetails
                                } else {
                                    details.types.append(typeDetails)
                                }
                                sheetShowing = false
                            }
                        }
                    }
            }.presentationDetents([.height(340)])
        }
    }
    
    struct BillTypeView: View {
        @Binding private var typeDetails: TypeDetails
        
        private let formatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 7
            formatter.zeroSymbol = ""
            return formatter
        }()
        private let currencyFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            return formatter
        }()
        private let names: [String] = ["Electric", "Water", "Sewer", "Trash", "Internet", "Other"]
        
        init(typeDetails: Binding<TypeDetails>) {
            self._typeDetails = typeDetails
        }
        
        var body: some View {
            HStack {
                Text("Type:")
                Picker("", selection: $typeDetails.type) {
                    Text("Flat").tag(BillType.Flat)
                    Text("Variable").tag(BillType.Variable)
                }.pickerStyle(.segmented)
            }
            Picker("Name:", selection: $typeDetails.name) {
                ForEach(names, id: \.hashValue) { name in
                    Text(name).tag(name)
                }
            }
            HStack {
                Text("Base Charge:")
                CurrencyTextField(numberFormatter: currencyFormatter, value: $typeDetails.base)
            }
            if typeDetails.type == .Variable {
                HStack {
                    Text("Usage:")
                    TextField("", value: $typeDetails.amount, formatter: formatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Rate:")
                    TextField("", value: $typeDetails.rate, formatter: formatter)
                        .keyboardType(.decimalPad)
                }
            }
        }
    }
    
    struct TypeDetails: Codable, Hashable, Equatable {
        var type: BillType = .Flat
        var name: String = "Electric"
        var base: Int = 0
        var amount: Double = 0.0
        var rate: Double = 0.0
    }
    
    struct Details {
        var types: [TypeDetails] = []
        var tax: Int = 0
        var details: String = ""
        
        static func fromExpense(_ details: Expense.Details) -> Details {
            switch details {
            case .Bill(let details):
                switch details.tax {
                case .Cents(let cents):
                    return Details(types: details.types.map(toType), tax: cents, details: details.details)
                }
            default:
                return Details()
            }
        }
        
        private static func toType(_ type: Expense.BillType) -> TypeDetails {
            switch type {
            case .Flat(let name, let base):
                switch base {
                case .Cents(let cents):
                    return .init(type: .Flat, name: name, base: cents)
                }
            case .Variable(let name, let base, let amount, let rate):
                switch base {
                case .Cents(let cents):
                    return .init(type: .Variable, name: name, base: cents, amount: amount, rate: rate)
                }
            }
        }
        
        func toExpense() -> Expense.Details {
            return .Bill(details: .init(types: types.map(toBillType), tax: .Cents(tax), details: details))
        }
        
        private func toBillType(_ type: TypeDetails) -> Expense.BillType {
            switch type.type {
            case .Flat:
                return .Flat(name: type.name, base: .Cents(type.base))
            case .Variable:
                return .Variable(name: type.name, base: .Cents(type.base), amount: type.amount, rate: type.rate)
            }
        }
    }
}

private struct GroceryExpenseView: View {
    @Binding private var details: Details
    @State private var foodDetails: FoodDetails = FoodDetails()
    @State private var itemIndex: Int = -1
    @State private var sheetShowing: Bool = false
    
    init(details: Binding<Details>) {
        self._details = details
    }
    
    var body: some View {
        ForEach(details.foods, id: \.hashValue) { food in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(food.name).bold()
                        if food.quantity != 1.0 {
                            Text("(x\(food.quantity.formatted(.number.precision(.fractionLength(0...2)))))")
                                .font(.subheadline)
                        }
                    }
                    Text("\(food.category) | Total: \((Price.Cents(food.price) * food.quantity).toString())")
                        .font(.subheadline).italic()
                }
                Spacer()
                Button("Edit") {
                    itemIndex = details.foods.firstIndex(of: food)!
                    foodDetails = food
                    sheetShowing = true
                }
            }
        }
        Button("Add Food") {
            foodDetails = FoodDetails()
            itemIndex = -1
            sheetShowing = true
        }.sheet(isPresented: $sheetShowing) {
            NavigationStack {
                Form {
                    FoodDetailView(foodDetails: $foodDetails)
                }.navigationTitle(itemIndex < 0 ? "Add Food" : "Edit Food")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                sheetShowing = false
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button("Save") {
                                if itemIndex >= 0 && itemIndex < details.foods.count {
                                    details.foods[itemIndex] = foodDetails
                                } else {
                                    details.foods.append(foodDetails)
                                }
                                sheetShowing = false
                            }
                        }
                    }
            }.presentationDetents([.height(300)])
        }
    }
    
    struct FoodDetailView: View {
        private let categories: [String] = ["Carbs", "Dairy", "Fruits", "Ingredients", "Meal", "Meat", "Sweets", "Vegetables"]
        
        @Binding private var foodDetails: FoodDetails
        
        private let formatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            formatter.zeroSymbol = ""
            return formatter
        }()
        private let currencyFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            return formatter
        }()
        
        init(foodDetails: Binding<FoodDetails>) {
            self._foodDetails = foodDetails
        }
        
        var body: some View {
            HStack {
                Text("Name:")
                TextField("required", text: $foodDetails.name)
                    .textInputAutocapitalization(.words)
            }
            HStack {
                Text("Unit Price:")
                CurrencyTextField(numberFormatter: currencyFormatter, value: $foodDetails.price)
            }
            HStack {
                Text("Quantity:")
                Stepper() {
                    TextField("required", value: $foodDetails.quantity, formatter: formatter)
                        .keyboardType(.decimalPad)
                } onIncrement: {
                    foodDetails.quantity += 1
                } onDecrement: {
                    if foodDetails.quantity > 1 {
                        foodDetails.quantity -= 1
                    }
                }
            }
            Picker("Category:", selection: $foodDetails.category) {
                ForEach(categories, id: \.hashValue) { category in
                    Text(category).tag(category)
                }
            }
        }
    }
    
    struct FoodDetails: Codable, Hashable, Equatable {
        var name: String = ""
        var price: Int = 0
        var quantity: Double = 1.0
        var category: String = "Carbs"
    }
    
    struct Details {
        var foods: [FoodDetails] = []
        
        static func fromExpense(_ details: Expense.Details) -> Details {
            switch details {
            case .Groceries(let list):
                return Details(foods: list.foods.map(toFood))
            default:
                return Details()
            }
        }
        
        private static func toFood(_ food: Expense.GroceryList.Food) -> FoodDetails {
            switch food.unitPrice {
            case .Cents(let cents):
                FoodDetails(name: food.name, price: cents, quantity: food.quantity, category: food.category)
            }
        }
        
        func toExpense() -> Expense.Details {
            return .Groceries(list: .init(foods: foods.map(toExpenseFood)))
        }
        
        private func toExpenseFood(_ food: FoodDetails) -> Expense.GroceryList.Food {
            return .init(name: food.name, unitPrice: .Cents(food.price), quantity: food.quantity, category: food.category)
        }
    }
}

#Preview {
    NavigationStack {
        EditExpenseView(path: .constant([]), expense: .init(date: .now, payee: "Costco", amount: .Cents(60110), category: "Groceries", details: .Groceries(list: .init(foods: [.init(name: "Chicken Thighs", unitPrice: .Cents(2134), quantity: 2.0, category: "Meat")]))))
    }
}
