//
//  ExpenseEditView.swift
//  Aegis
//
//  Created by Zach Wassynger on 12/8/24.
//

import SwiftData
import SwiftUI

private enum SheetType: String, Identifiable {
    case Item
    case Bill
    case Recent
    
    var id: String {
        get {
            rawValue
        }
    }
}

struct ExpenseEditView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
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
    
    // Main
    @State private var date: Date = .now
    @State private var amount: Int = 0
    @State private var payee: String = ""
    @State private var category: String = ""
    @State private var notes: String = ""
    @State private var type: DetailType? = nil
    @State private var sheetType: SheetType? = nil
    // Tip
    @State private var tip: Int = 0
    // Items
    @State private var items: [Expense.Item] = []
    @State private var item: EditItemView.Item = .init()
    @State private var itemIndex: Int = -1
    @State private var recentItemFilter: String = ""
    @State private var recentItemSearchShowing: Bool = false
    // Bill
    @State private var bills: [Expense.BillDetails.Bill] = []
    @State private var bill: EditBillView.Bill = .init()
    @State private var billIndex: Int = -1
    // Fuel
    @State private var fuel: Expense.FuelDetails = .init(amount: 0.0, rate: 0.0, user: "")
    
    init(expense: Expense? = nil, mode: Mode? = nil) {
        self.expense = expense ?? .init()
        self.mode = mode ?? (expense == nil ? .Add : .Edit)
    }
    
    var body: some View {
        let payees = Set(expenses.map({ $0.payee })).sorted()
        let categories = Set(MainView.MainExpenseCategories + expenses.map({ $0.category })).sorted()
        let names = Set(expenses.map(getItemNames).flatMap({ $0 })).sorted()
        let brands = Set(expenses.map(getItemBrands).flatMap({ $0 })).sorted()
        let recentItems: [Expense.Item] = {
            var map: [String : Expense.Item] = [:]
            expenses.map(getItems)
                .flatMap({ $0 })
                .filter({ isItemFiltered($0) })
                .forEach({ item in
                if map[item.name] == nil {
                    map[item.name] = item
                }
            })
            return map.values.sorted(by: { $0.name < $1.name })
        }()
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
                payeeAutoCompleteView(payees)
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
                categoryAutoCompleteView(categories)
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
            .onAppear(perform: load)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back", action: back)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: save)
                        .disabled(payee.isEmpty || amount <= 0 || category.isEmpty)
                }
            }
            .sheet(item: $sheetType) { sheet in
                switch sheet {
                case .Item:
                    NavigationStack {
                        itemSheetView(names: names, brands: brands)
                    }.presentationDetents([.medium])
                case .Bill:
                    NavigationStack {
                        billSheetView()
                    }.presentationDetents([.medium])
                case .Recent:
                    NavigationStack {
                        recentItemSheetView(recentItems: recentItems)
                            .navigationTitle("Create New Item")
                            .navigationBarTitleDisplayMode(.inline)
                            .searchable(text: $recentItemFilter, isPresented: $recentItemSearchShowing)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") {
                                        sheetType = nil
                                    }
                                }
                            }
                    }.presentationDetents([.large])
                }
            }
    }
    
    private func isItemFiltered(_ item: Expense.Item) -> Bool {
        if recentItemFilter.isEmpty {
            return true
        }
        return item.name.localizedCaseInsensitiveContains(recentItemFilter) || item.brand.localizedCaseInsensitiveContains(recentItemFilter)
    }
    
    private func getItems(_ expense: Expense) -> [Expense.Item] {
        switch expense.details {
        case .Items(let list):
            return list.items
        default:
            return []
        }
    }
    
    private func getItemNames(_ expense: Expense) -> [String] {
        switch expense.details {
        case .Items(let list):
            return list.items.map({ $0.name })
        default:
            return []
        }
    }
    
    private func getItemBrands(_ expense: Expense) -> [String] {
        switch expense.details {
        case .Items(let list):
            return list.items.map({ $0.brand })
        default:
            return []
        }
    }
    
    @ViewBuilder
    private func payeeAutoCompleteView(_ payees: [String]) -> some View {
        if !payee.isEmpty && !payees.contains(payee) {
            let options = getFilteredEntries(payee, payees)
            if !options.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(options, id: \.self) { name in
                            Button(name) {
                                self.payee = name
                            }.padding([.leading, .trailing], 4)
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private func categoryDropDownMenu() -> some View {
        Menu {
            ForEach(MainView.MainExpenseCategories, id: \.hashValue) { category in
                Button(category) {
                    self.category = category
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
    private func categoryAutoCompleteView(_ categories: [String]) -> some View {
        if !category.isEmpty && !categories.contains(category) {
            let options = getFilteredEntries(category, categories)
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
    
    private func getFilteredEntries(_ text: String, _ entries: [String]) -> [String] {
        entries.filter({ $0.localizedCaseInsensitiveContains(text) }).sorted()
    }
    
    @ViewBuilder
    private func detailsView() -> some View {
        if let type {
            Section(type.getName()) {
                switch type {
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
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
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
                sheetType = .Item
            } label: {
                HStack {
                    ExpenseItemEntryView(item: item)
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(.blue)
                        .padding(.leading, 4)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
                .contextMenu {
                    Button {
                        self.item = .fromExpenseItem(item)
                        itemIndex = items.firstIndex(of: item) ?? -1
                        sheetType = .Item
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                    Button(role: .destructive) {
                        items.removeAll(where: { $0 == item })
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }.onDelete(perform: { indexSet in
            items.remove(atOffsets: indexSet)
        })
        Button {
            item = .init()
            itemIndex = -1
            sheetType = .Item
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("New Item")
            }.bold()
        }
        Button {
            recentItemFilter = ""
            sheetType = .Recent
            recentItemSearchShowing = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "doc.on.doc")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Existing Item")
            }.bold()
        }
    }
    
    @ViewBuilder
    private func itemSheetView(names: [String], brands: [String]) -> some View {
        EditItemView(item: $item, names: names, brands: brands)
            .navigationTitle(itemIndex >= 0 ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: hideItemSheet)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: saveItem)
                        .disabled(item.invalid)
                }
            }
    }
    
    private func hideItemSheet() {
        sheetType = nil
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
    private func recentItemSheetView(recentItems: [Expense.Item]) -> some View {
        Form {
            if !recentItems.isEmpty {
                ForEach(recentItems, id: \.hashValue) { i in
                    Button {
                        item = .fromExpenseItem(i)
                        itemIndex = -1
                        sheetType = .Item
                    } label: {
                        ExpenseItemEntryView(item: i)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            } else {
                Button {
                    item = .init(name: recentItemFilter)
                    itemIndex = -1
                    sheetType = .Item
                } label: {
                    Text(recentItemFilter.isEmpty ? "Create New Entry" : "Create New Entry: \(recentItemFilter)")
                }
            }
        }
    }
    
    @ViewBuilder
    private func billDetailView() -> some View {
        ForEach(bills, id: \.hashValue) { bill in
            Button {
                self.bill = .fromExpenseBill(bill)
                billIndex = bills.firstIndex(of: bill) ?? -1
                sheetType = .Bill
            } label: {
                HStack {
                    ExpenseBillEntryView(bill: bill)
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(.blue)
                        .padding(.leading, 4)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
                .contextMenu {
                    Button {
                        self.bill = .fromExpenseBill(bill)
                        billIndex = bills.firstIndex(of: bill) ?? -1
                        sheetType = .Bill
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                    Button(role: .destructive) {
                        bills.removeAll(where: { $0 == bill })
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }.onDelete(perform: { indexSet in
            bills.remove(atOffsets: indexSet)
        })
        Button {
            bill = .init()
            billIndex = -1
            sheetType = .Bill
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
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
        sheetType = nil
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
        navigationStore.pop()
    }
    
    private func load() {
        date = expense.date
        payee = expense.payee
        amount = expense.amount.toCents()
        category = expense.category
        notes = expense.notes
        switch expense.details {
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
    
    private func save() {
        expense.date = date
        expense.payee = payee
        expense.amount = .Cents(amount)
        expense.category = category
        expense.notes = notes
        switch type {
        case .Tip:
            expense.details = .Tip(amount: .Cents(tip))
        case .Items:
            expense.details = .Items(list: .init(items: items))
        case .Bill:
            expense.details = .Bill(details: .init(bills: bills))
        case .Fuel:
            expense.details = .Fuel(details: fuel)
        case .none:
            expense.details = nil
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
        case Tip
        case Bill
        case Fuel
        
        func getName() -> String {
            switch self {
            case .Items:
                "Items"
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
        let names: [String]
        let brands: [String]
        
        @Binding private var item: Item
        
        init(item: Binding<Item>, names: [String], brands: [String]) {
            self._item = item
            self.names = names
            self.brands = brands
        }
        
        var body: some View {
            Form {
                HStack {
                    Text("Name:")
                    TextField("required", text: $item.name)
                        .textInputAutocapitalization(.words)
                }
                nameAutoCompleteView(names)
                HStack {
                    Text("Brand:")
                    TextField("optional", text: $item.brand)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                brandAutoCompleteView(brands)
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
        
        @ViewBuilder
        private func nameAutoCompleteView(_ names: [String]) -> some View {
            if !item.name.isEmpty && !names.contains(item.name) {
                let options = getFilteredEntries(item.name, names)
                if !options.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(options, id: \.self) { name in
                                Button(name) {
                                    item.name = name
                                }.padding([.leading, .trailing], 4)
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        
        @ViewBuilder
        private func brandAutoCompleteView(_ brands: [String]) -> some View {
            if !item.brand.isEmpty && !brands.contains(item.brand) {
                let options = getFilteredEntries(item.brand, brands)
                if !options.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(options, id: \.self) { name in
                                Button(name) {
                                    item.brand = name
                                }.padding([.leading, .trailing], 4)
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        
        private func getFilteredEntries(_ text: String, _ entries: [String]) -> [String] {
            entries.filter({ $0.localizedCaseInsensitiveContains(text) }).sorted()
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
            
            var invalid: Bool {
                get {
                    name.isEmpty || quantityInvalid
                }
            }
            var quantityInvalid: Bool {
                get {
                    switch quantityType {
                    case .Discrete:
                        return discrete <= 0
                    case .Unit:
                        return unitAmount <= 0 || unit.isEmpty
                    }
                }
            }
            
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
                    return name.isEmpty || amount <= 0 || rate <= 0
                }
            }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        ExpenseEditView().navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
