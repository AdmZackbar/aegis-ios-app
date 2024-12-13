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
    // Items
    @State private var items: [Expense.Item] = []
    @State private var itemSheetShowing: Bool = false
    @State private var item: EditItemView.Item = .init()
    @State private var itemIndex: Int = -1
    // Bill
    @State private var bills: [Expense.BillDetails.Bill] = []
    @State private var billTax: Int = 0
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
                    Text("Bill")
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
                billTax = details.tax.toCents()
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
            expense.details = .Bill(details: .init(bills: bills, tax: .Cents(billTax)))
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
            
            init(name: String = "", brand: String = "", quantityType: AmountType = .Discrete, discrete: Int = 1, unitAmount: Double = 1.0, unit: String = "", totalPrice: Int = 0) {
                self.name = name
                self.brand = brand
                self.quantityType = quantityType
                self.discrete = discrete
                self.unitAmount = unitAmount
                self.unit = unit
                self.totalPrice = totalPrice
            }
            
            static func fromExpenseItem(_ item: Expense.Item) -> Item {
                switch item.quantity {
                case .Discrete(let num):
                    return .init(name: item.name, brand: item.brand, quantityType: .Discrete, discrete: num, totalPrice: item.total.toCents())
                case .Unit(let num, let unit):
                    return .init(name: item.name, brand: item.brand, quantityType: .Unit, unitAmount: num, unit: unit, totalPrice: item.total.toCents())
                }
            }
            
            func toExpenseItem() -> Expense.Item {
                switch quantityType {
                case .Discrete:
                    return .init(name: name, brand: brand, quantity: .Discrete(discrete), total: .Cents(totalPrice))
                case .Unit:
                    return .init(name: name, brand: brand, quantity: .Unit(num: unitAmount, unit: unit), total: .Cents(totalPrice))
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
}

#Preview {
    let container = createTestModelContainer()
    return NavigationStack {
        ExpenseEditView(path: .constant([]), expense: .init(date: Date(), payee: "Costco", amount: .Cents(34156), category: "Groceries", notes: "Test run", details: .Items(list: .init(items: [.init(name: "Chicken Thighs", brand: "Kirkland Signature", quantity: .Unit(num: 3.3, unit: "lbs"), total: .Cents(3135))]))))
    }.modelContainer(container)
}
