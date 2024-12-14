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
    
    static let BillNames: [String] = ["Electric", "Water", "Sewer", "Trash", "Internet", "Other"]
    static let BillUnitMap: [String : String] = {
        var map: [String : String] = [:]
        map["Electric"] = "kWh"
        map["Water"] = "gal"
        map["Sewer"] = "gal"
        return map
    }()
    
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
    // Items
    @State private var items: [Expense.Item] = []
    @State private var itemSheetShowing: Bool = false
    @State private var item: EditItemView.Item = .init()
    @State private var itemIndex: Int = -1
    // Bill
    @State private var bills: [Expense.BillDetails.Bill] = []
    @State private var billSheetShowing: Bool = false
    @State private var bill: EditBillView.Bill = .init()
    @State private var billIndex: Int = -1
    // Fuel
    @State private var fuel: Expense.FuelDetails = .init(amount: 0.0, rate: 0.0, user: "")
    
    init(path: Binding<[ViewType]>, expense: Expense? = nil) {
        self._path = path
        self.expense = expense ?? Expense(date: Date(), payee: "", amount: .Cents(0), category: "", notes: "", details: nil)
        mode = expense == nil ? .Add : .Edit
    }
    
    var body: some View {
        Form {
            Section("Details") {
                DatePicker(selection: $date, displayedComponents: .date) {
                    HStack {
                        Image(systemName: "calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("Date:")
                    }
                }
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Amount:")
                    CurrencyField(value: $amount)
                }
                HStack {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Payee:")
                    TextField("required", text: $payee)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                HStack {
                    Image(systemName: "tag.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Category:")
                    TextField("required", text: $category)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    categoryDropDownMenu()
                }
                categoryAutoCompleteView()
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...9)
                    .textInputAutocapitalization(.sentences)
                if type == nil {
                    Menu {
                        ForEach(DetailType.allCases, id: \.rawValue) { type in
                            Button("\(type.getName())...") {
                                self.type = type
                            }
                        }
                    } label: {
                        HStack {
                            Label("Add Additional Details...", systemImage: "plus")
                            Spacer()
                        }.contentShape(Rectangle())
                    }
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
            .sheet(isPresented: $itemSheetShowing) {
                NavigationStack {
                    itemSheetView()
                }.presentationDetents([.medium])
            }
            .sheet(isPresented: $billSheetShowing) {
                NavigationStack {
                    billSheetView()
                }.presentationDetents([.medium])
            }
    }
    
    private func categoryDropDownMenu() -> some View {
        Menu {
            ForEach(MainView.ExpenseCategories.sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { category, children in
                Menu(category) {
                    ForEach(children, id: \.hashValue) { child in
                        Button(child) {
                            self.category = child
                        }
                    }
                }
            }
        } label: {
            VStack(spacing: 5){
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
    }
    
    @ViewBuilder
    private func categoryAutoCompleteView() -> some View {
        if !category.isEmpty && !isStandardCategory(category) {
            let options = getValidCategories(category)
            if !options.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(options, id: \.self) { name in
                            Button(name) {
                                self.category = name
                            }.padding([.leading, .trailing], 4)
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private func isStandardCategory(_ name: String) -> Bool {
        MainView.ExpenseCategories.values.contains(where: { $0.contains(where: { $0 == name }) })
    }
    
    private func getValidCategories(_ name: String) -> [String] {
        MainView.ExpenseCategories.values.flatMap({ $0 }).filter({ $0.contains(name) }).sorted()
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
                case .Items:
                    itemDetailView()
                case .Bill:
                    billDetailView()
                case .Fuel:
                    fuelDetailView()
                }
                Button(role: .destructive) {
                    self.type = nil
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash")
                        Text("Remove Additional Details")
                    }.bold()
                }
            }
        }
    }
    
    @ViewBuilder
    private func itemDetailView() -> some View {
        ForEach(items, id: \.hashValue) { item in
            Button {
                self.item = .fromExpenseItem(item)
                itemIndex = items.firstIndex(of: item) ?? -1
                itemSheetShowing = true
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(item.name).bold()
                            Spacer()
                            Text(item.total.toString()).italic()
                        }
                        if !item.brand.isEmpty || !item.quantity.summary.isEmpty {
                            HStack {
                                Text(item.brand)
                                Spacer()
                                Text(item.quantity.summary)
                            }.font(.subheadline).italic()
                        }
                    }
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(.blue)
                        .padding(.leading, 4)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
        Button {
            item = .init()
            itemIndex = -1
            itemSheetShowing = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                Text("Add Item")
            }.bold()
        }
    }
    
    @ViewBuilder
    private func itemSheetView() -> some View {
        EditItemView(item: $item)
            .navigationTitle(itemIndex >= 0 ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: hideItemSheet)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: saveItem)
                        .disabled(item.isInvalid())
                }
            }
    }
    
    private func hideItemSheet() {
        itemSheetShowing = false
    }
    
    private func saveItem() {
        if itemIndex < 0 {
            items.append(item.toExpenseItem())
        } else {
            items[itemIndex] = item.toExpenseItem()
        }
        hideItemSheet()
    }
    
    @ViewBuilder
    private func billDetailView() -> some View {
        ForEach(bills, id: \.hashValue) { bill in
            Button {
                self.bill = .fromExpenseBill(bill)
                billIndex = bills.firstIndex(of: bill) ?? -1
                billSheetShowing = true
            } label: {
                switch bill {
                case .Flat(let name, _):
                    HStack {
                        Text(name).bold()
                        Spacer()
                        Text(bill.getTotal().toString()).italic()
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(.blue)
                            .padding(.leading, 4)
                    }.contentShape(Rectangle())
                case .Variable(let name, _, let amount, let rate):
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(name).bold()
                                Spacer()
                                Text(bill.getTotal().toString()).italic()
                            }
                            if let unit = ExpenseEditView.BillUnitMap[name] {
                                HStack {
                                    Text("\(amount.formatted()) \(unit)")
                                    Spacer()
                                    Text("\(rate.formatted(.currency(code: "USD").precision(.fractionLength(2...7)))) / \(unit)")
                                }.font(.subheadline).italic()
                            }
                        }
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(.blue)
                            .padding(.leading, 4)
                    }.contentShape(Rectangle())
                }
            }.buttonStyle(.plain)
        }
        Button {
            bill = .init()
            billIndex = -1
            billSheetShowing = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                Text("Add Bill")
            }.bold()
        }
    }
    
    @ViewBuilder
    private func billSheetView() -> some View {
        EditBillView(bill: $bill)
            .navigationTitle(billIndex >= 0 ? "Edit Bill" : "Add Bill")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: hideBillSheet)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: saveBill)
                        .disabled(bill.isInvalid())
                }
            }
    }
    
    private func hideBillSheet() {
        billSheetShowing = false
    }
    
    private func saveBill() {
        if billIndex < 0 {
            bills.append(bill.toExpenseBill())
        } else {
            bills[billIndex] = bill.toExpenseBill()
        }
        hideBillSheet()
    }
    
    @ViewBuilder
    private func fuelDetailView() -> some View {
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
        HStack {
            Text("User:")
            TextField("required", text: $fuel.user)
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
            notes = expense.notes
            switch expense.details {
            case .Tag(let name):
                type = .Tag
                tag = name
            case .Tip(let amount):
                type = .Tip
                tip = amount.toCents()
            case .Items(let list):
                type = .Items
                items = list.items
            case .Bill(let details):
                type = .Bill
                bills = details.bills
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
            expense.details = .Tag(name: tag)
        case .Tip:
            expense.details = .Tip(amount: .Cents(tip))
        case .Items:
            expense.details = .Items(list: .init(items: items))
        case .Bill:
            expense.details = .Bill(details: .init(bills: bills))
        case .Fuel:
            expense.details = .Fuel(details: fuel)
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
        case Items
        case Tag
        case Tip
        case Bill
        case Fuel
        
        func getName() -> String {
            switch self {
            case .Items:
                "Items"
            case .Tag:
                "Sub-Category"
            case .Tip:
                "Tip"
            case .Bill:
                "Utility Bill"
            case .Fuel:
                "Gas"
            }
        }
    }
    
    private struct EditItemView: View {
        @Binding private var item: Item
        
        init(item: Binding<Item>) {
            self._item = item
        }
        
        var body: some View {
            Form {
                HStack {
                    Text("Name:")
                    TextField("required", text: $item.name)
                        .textInputAutocapitalization(.words)
                }
                HStack {
                    Text("Brand:")
                    TextField("optional", text: $item.brand)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                HStack {
                    Text("Total:")
                    CurrencyField(value: $item.totalPrice)
                }
                Toggle(isOn: $item.sale) {
                    HStack {
                        Text("Savings:")
                        if item.sale {
                            CurrencyField(value: $item.salePrice)
                        }
                    }
                }
                Picker("", selection: $item.quantityType) {
                    Text("Individual").tag(AmountType.Discrete)
                    Text("By Unit").tag(AmountType.Unit)
                }.pickerStyle(.segmented)
                let discreteFormatter = {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.maximumFractionDigits = 0
                    return formatter
                }()
                let unitFormatter = {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.maximumFractionDigits = 3
                    return formatter
                }()
                switch item.quantityType {
                case .Discrete:
                    HStack {
                        Text("Quantity:")
                        Stepper {
                            TextField("required", value: $item.discrete, formatter: discreteFormatter)
                                .keyboardType(.numberPad)
                        } onIncrement: {
                            item.discrete += 1
                        } onDecrement: {
                            if item.discrete > 1 {
                                item.discrete -= 1
                            }
                        }
                    }
                case .Unit:
                    HStack {
                        Text("Amount:")
                        TextField("required", value: $item.unitAmount, formatter: unitFormatter)
                            .keyboardType(.decimalPad)
                        Divider()
                        Text("Unit:")
                        TextField("required", text: $item.unit)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
            }
        }
        
        struct Item {
            var name: String
            var brand: String
            var quantityType: AmountType
            var discrete: Int
            var unitAmount: Double
            var unit: String
            var totalPrice: Int
            var sale: Bool
            var salePrice: Int
            
            init(name: String = "", brand: String = "", quantityType: AmountType = .Discrete, discrete: Int = 1, unitAmount: Double = 1.0, unit: String = "", totalPrice: Int = 0, sale: Bool = false, salePrice: Int = 0) {
                self.name = name
                self.brand = brand
                self.quantityType = quantityType
                self.discrete = discrete
                self.unitAmount = unitAmount
                self.unit = unit
                self.totalPrice = totalPrice
                self.sale = sale
                self.salePrice = salePrice
            }
            
            static func fromExpenseItem(_ item: Expense.Item) -> Item {
                switch item.quantity {
                case .Discrete(let num):
                    return .init(name: item.name, brand: item.brand, quantityType: .Discrete, discrete: num, totalPrice: item.total.toCents(), sale: item.discount != nil, salePrice: item.discount?.toCents() ?? 0)
                case .Unit(let num, let unit):
                    return .init(name: item.name, brand: item.brand, quantityType: .Unit, unitAmount: num, unit: unit, totalPrice: item.total.toCents(), sale: item.discount != nil, salePrice: item.discount?.toCents() ?? 0)
                }
            }
            
            func toExpenseItem() -> Expense.Item {
                let discount: Price? = sale ? .Cents(salePrice) : nil
                switch quantityType {
                case .Discrete:
                    return .init(name: name, brand: brand, quantity: .Discrete(discrete), total: .Cents(totalPrice), discount: discount)
                case .Unit:
                    return .init(name: name, brand: brand, quantity: .Unit(num: unitAmount, unit: unit), total: .Cents(totalPrice), discount: discount)
                }
            }
            
            func isInvalid() -> Bool {
                name.isEmpty || isQuantityInvalid()
            }
            
            func isQuantityInvalid() -> Bool {
                switch quantityType {
                case .Discrete:
                    return discrete <= 0
                case .Unit:
                    return unitAmount <= 0 || unit.isEmpty
                }
            }
        }
        
        enum AmountType {
            case Discrete
            case Unit
        }
    }
    
    private struct EditBillView: View {
        @Binding private var bill: Bill
        
        private let formatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 7
            formatter.zeroSymbol = ""
            return formatter
        }()
        
        init(bill: Binding<Bill>) {
            self._bill = bill
        }
        
        var body: some View {
            Form {
                HStack {
                    Text("Type:")
                    Picker("", selection: $bill.type) {
                        Text("Flat").tag(BillType.Flat)
                        Text("Variable").tag(BillType.Variable)
                    }.pickerStyle(.segmented)
                }
                Picker("Name:", selection: $bill.name) {
                    ForEach(ExpenseEditView.BillNames, id: \.hashValue) { name in
                        Text(name).tag(name)
                    }
                }
                HStack {
                    Text("Base Charge:")
                    CurrencyField(value: $bill.base)
                }
                if bill.type == .Variable {
                    let unit = ExpenseEditView.BillUnitMap[bill.name]
                    HStack {
                        Text("Usage:")
                        TextField("required", value: $bill.amount, formatter: formatter)
                            .keyboardType(.decimalPad)
                        if let unit {
                            Text(unit)
                        }
                    }
                    HStack {
                        Text("Rate:")
                        TextField("required", value: $bill.rate, formatter: formatter)
                            .keyboardType(.decimalPad)
                        if let unit {
                            Text("$/\(unit)")
                        }
                    }
                }
            }
        }
        
        enum BillType: Codable, Equatable, Hashable {
            case Flat
            case Variable
        }
        
        struct Bill: Codable, Hashable, Equatable {
            var type: BillType
            var name: String
            var base: Int
            var amount: Double
            var rate: Double
            
            init(type: BillType = .Flat, name: String = "Electric", base: Int = 0, amount: Double = 0.0, rate: Double = 0.0) {
                self.type = type
                self.name = name
                self.base = base
                self.amount = amount
                self.rate = rate
            }
            
            static func fromExpenseBill(_ bill: Expense.BillDetails.Bill) -> Bill {
                switch bill {
                case .Flat(let name, let base):
                    return .init(type: .Flat, name: name, base: base.toCents())
                case .Variable(let name, let base, let amount, let rate):
                    return .init(type: .Variable, name: name, base: base.toCents(), amount: amount, rate: rate)
                }
            }
            
            func toExpenseBill() -> Expense.BillDetails.Bill {
                switch type {
                case .Flat:
                    return .Flat(name: name, base: .Cents(base))
                case .Variable:
                    return .Variable(name: name, base: .Cents(base), amount: amount, rate: rate)
                }
            }
            
            func isInvalid() -> Bool {
                switch type {
                case .Flat:
                    return name.isEmpty || base <= 0
                case .Variable:
                    return name.isEmpty || base <= 0 || amount <= 0 || rate <= 0
                }
            }
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    return NavigationStack {
        ExpenseEditView(path: .constant([]), expense: .init(date: Date(), payee: "Costco", amount: .Cents(34156), category: "Groceries", notes: "Test run", details: .Items(list: .init(items: [
            .init(name: "Chicken Thighs", brand: "Kirkland Signature", quantity: .Unit(num: 4.51, unit: "lb"), total: .Cents(3541)),
            .init(name: "Hot Chocolate", brand: "Swiss Miss", quantity: .Discrete(1), total: .Cents(799), discount: .Cents(300)),
            .init(name: "Chicken Chunks", brand: "Just Bare", quantity: .Discrete(2), total: .Cents(1499))
        ]))))
    }.modelContainer(container)
}
