//
//  EditPurchaseView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/10/24.
//

import SwiftUI

struct EditPurchaseView: View {
    @Environment(\.modelContext) var modelContext
    
    let purchase: Purchase
    let mode: Mode
    
    private let currencyFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    @Binding private var path: [ViewType]
    
    @State private var date: Date = Date()
    @State private var category: Category? = nil
    @State private var seller: String = ""
    @State private var price: Int = 0
    @State private var details: String = ""
    @State private var gasDetails: GasDetails = GasDetails()
    @State private var restaurantDetails: RestaurantDetails = RestaurantDetails()
    @State private var billDetails: BillDetails = BillDetails()
    @State private var computerDetails: ComputerDetails = ComputerDetails()
    
    init(path: Binding<[ViewType]>, purchase: Purchase? = nil) {
        self._path = path
        self.purchase = purchase ?? Purchase(date: Date(), category: .Basic(name: "", details: ""), seller: "", price: .Cents(0))
        mode = purchase == nil ? .Add : .Edit
    }
    
    var body: some View {
        Form {
            if let category = category {
                editCategoryButton(category.name)
                DatePicker("Date:", selection: $date, displayedComponents: .date)
                createCategoryView(category.name)
            } else {
                categorySection()
            }
        }.navigationTitle(mode.getTitle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear(perform: load)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(mode.getBackAction()) {
                        back()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        save()
                        back()
                    }.disabled(seller.isEmpty || price <= 0)
                }
            }
    }
    
    private func back() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    private func load() {
        switch(mode) {
        case .Edit:
            date = purchase.date
            seller = purchase.seller
            switch purchase.price {
            case .Cents(let amount):
                price = amount
            }
            category = Category(purchase.category.getName())
            details = computeDetails(purchase.category)
            gasDetails = GasDetails.fromCategory(purchase.category)
            restaurantDetails = RestaurantDetails.fromCategory(purchase.category)
            billDetails = BillDetails.fromCategory(purchase.category)
            computerDetails = ComputerDetails.fromCategory(purchase.category)
        default:
            break
        }
    }
    
    private func computeDetails(_ category: Purchase.Category) -> String {
        switch category {
        case .Basic(_, let details):
            return details
        case .Restaurant(let details, _):
            return details
        case .Charity(_, let details):
            return details
        case .Gift(_, let details):
            return details
        default:
            return ""
        }
    }
    
    private func save() {
        purchase.date = date
        purchase.seller = seller
        purchase.price = .Cents(price)
        if let category = category {
            switch category.name {
            case "Gas":
                purchase.category = gasDetails.toCategory()
            case "Restaurant":
                purchase.category = restaurantDetails.toCategory()
            case "Electric Bill":
                purchase.category = billDetails.toCategory()
            case "Water Bill":
                purchase.category = billDetails.toCategory()
            case "Other Utility Bill":
                purchase.category = billDetails.toCategory()
            case "Computer Hardware":
                purchase.category = computerDetails.toHardware()
            case "Computer Software":
                purchase.category = computerDetails.toSoftware()
            default:
                purchase.category = .Basic(name: category.name, details: details)
            }
        }
        switch mode {
        case .Add:
            modelContext.insert(purchase)
        default:
            break
        }
    }
    
    private func editCategoryButton(_ name: String) -> some View {
        HStack {
            Text("Category: \(name)")
            Spacer()
            Button("Change") {
                self.category = nil
            }
        }
    }
    
    private func categorySection() -> some View {
        Section("Category") {
            OutlineGroup(EditPurchaseView.Categories, id: \.name, children: \.children) { c in
                Button(c.name) {
                    category = c
                }.tint(.primary)
            }
        }
    }
    
    @ViewBuilder
    private func createCategoryView(_ categoryName: String) -> some View {
        switch categoryName {
        case "Gas":
            gasEditor()
        case "Restaurant":
            restaurantEditor()
        case "Electric Bill":
            billEditor()
        case "Water Bill":
            billEditor()
        case "Other Utility Bill":
            billEditor()
        case "Computer Hardware":
            computerEditor()
        case "Computer Software":
            computerEditor()
        default:
            HStack {
                Text("Seller:")
                TextField("required", text: $seller)
            }
            CurrencyTextField(numberFormatter: currencyFormatter, value: $price)
            TextField("details", text: $details, axis: .vertical).lineLimit(3...5)
        }
    }
    
    @ViewBuilder
    private func gasEditor() -> some View {
        let formatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 3
            formatter.zeroSymbol = ""
            return formatter
        }()
        HStack {
            Text("Gas Station:")
            TextField("required", text: $seller)
        }
        HStack {
            Text("Total Cost:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $price)
        }
        HStack {
            Text("Amount (Gallons):")
            TextField("required", value: $gasDetails.gallons, formatter: formatter)
                .keyboardType(.decimalPad)
        }
        HStack {
            Text("Cost per Gallon:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $gasDetails.price)
        }
        HStack {
            Text("Octane:")
            Spacer()
            Picker("", selection: $gasDetails.octane) {
                Text("87").tag(87)
                Text("89").tag(89)
                Text("91").tag(91)
                Text("93").tag(93)
            }.pickerStyle(.segmented)
        }
    }
    
    @ViewBuilder
    private func restaurantEditor() -> some View {
        HStack {
            Text("Restaurant:")
            TextField("required", text: $seller)
        }
        HStack {
            Text("Total Bill:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $price)
        }
        HStack {
            Text("Tip:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $restaurantDetails.tip)
        }
        TextField("Details", text: $restaurantDetails.details, axis: .vertical).lineLimit(3...5)
    }
    
    @ViewBuilder
    private func billEditor() -> some View {
        let formatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 3
            formatter.zeroSymbol = ""
            return formatter
        }()
        Picker("Utility:", selection: $billDetails.name) {
            Text("Electric").tag("Electric")
            Text("Water").tag("Water")
        }
        HStack {
            Text("Total:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $price)
        }
        HStack {
            Text("Usage \(billDetails.unit):")
            TextField("required", value: $billDetails.usage, formatter: formatter)
                .keyboardType(.decimalPad)
        }
        HStack {
            Text("Rate:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $billDetails.rate)
        }
    }
    
    @ViewBuilder
    private func computerEditor() -> some View {
        HStack {
            Text("Manufacturer:")
            TextField("required", text: $seller)
        }
        HStack {
            Text("Name:")
            TextField("required", text: $computerDetails.name)
        }
        HStack {
            Text("Price:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $price)
        }
    }
    
    enum Mode {
        case Add, Edit
        
        func getTitle() -> String {
            switch self {
            case .Add:
                return "Add Purchase"
            case .Edit:
                return "Edit Purchase"
            }
        }
        
        func getBackAction() -> String {
            switch self {
            case .Add:
                return "Back"
            case .Edit:
                return "Cancel"
            }
        }
    }
    
    struct Category: Identifiable, Hashable {
        var id: String {
            get { name }
        }
        
        let name: String
        let children: [Category]?
        
        init(_ name: String, children: [Category]? = nil) {
            self.name = name
            self.children = children
        }
    }
    
    static let Categories: [Category] = [
        .init("Housing", children: [
            .init("Mortgage Bill"),
            .init("Mortgage Payment"),
            .init("Housing Maintenance"),
            .init("Housing Improvements"),
            .init("Housing Utilities", children: [
                .init("Electric Bill"),
                .init("Water Bill"),
                .init("Other Utility Bill"),
                .init("Internet Bill")
            ]),
            .init("Rent")
        ]),
        .init("Food", children: [
            .init("Groceries"),
            .init("Fast Food"),
            .init("Restaurant")
        ]),
        .init("Car", children: [
            .init("Gas"),
            .init("Car Maintenance"),
            .init("Car Insurance"),
            .init("Car Tags")
        ]),
        .init("Sports", children: [
            .init("Gym"),
            .init("Equipment"),
            .init("Events"),
            .init("Outdoor Access")
        ]),
        .init("Charity"),
        .init("Gift"),
        .init("Media", children: [
            .init("Video Games"),
            .init("Games"),
            .init("Music"),
            .init("Movies")
        ]),
        .init("Technology", children: [
            .init("Computer Software"),
            .init("Computer Hardware")
        ]),
        .init("Self Care", children: [
            .init("Eyes"),
            .init("Haircut"),
            .init("Medicine"),
            .init("Healthcare")
        ])
    ]
    
    private struct GasDetails {
        var gallons: Double = 0.0
        var price: Int = 0
        var octane: Int = 87
        
        static func fromCategory(_ category: Purchase.Category) -> GasDetails {
            switch category {
            case .Gas(let gallons, let price, let octane):
                switch price {
                case .Cents(let cents):
                    return GasDetails(gallons: gallons, price: cents, octane: octane)
                }
            default:
                return GasDetails()
            }
        }
        
        func toCategory() -> Purchase.Category {
            .Gas(numGallons: gallons, costPerGallon: .Cents(price), octane: octane)
        }
    }
    
    private struct RestaurantDetails {
        var details: String = ""
        var tip: Int = 0
        
        static func fromCategory(_ category: Purchase.Category) -> RestaurantDetails {
            switch category {
            case .Restaurant(let details, let tip):
                switch tip {
                case .Cents(let cents):
                    return RestaurantDetails(details: details, tip: cents)
                }
            default:
                return RestaurantDetails()
            }
        }
        
        func toCategory() -> Purchase.Category {
            .Restaurant(details: details, tip: .Cents(tip))
        }
    }
    
    private struct BillDetails {
        var name: String = ""
        var unit: String = ""
        var usage: Double = 0.0
        var rate: Int = 0
        
        static func fromCategory(_ category: Purchase.Category) -> BillDetails {
            switch category {
            case .UtilityBill(let name, let unit, let usage, let rate):
                switch rate {
                case .Cents(let cents):
                    return BillDetails(name: name, unit: unit, usage: usage, rate: cents)
                }
            default:
                return BillDetails()
            }
        }
        
        func toCategory() -> Purchase.Category {
            .UtilityBill(name: name, unit: unit, usage: usage, rate: .Cents(rate))
        }
    }
    
    private struct ComputerDetails {
        var name: String = ""
        
        static func fromCategory(_ category: Purchase.Category) -> ComputerDetails {
            switch category {
            case .Software(let name):
                return ComputerDetails(name: name)
            case .Hardware(let name):
                return ComputerDetails(name: name)
            default:
                return ComputerDetails()
            }
        }
        
        func toSoftware() -> Purchase.Category {
            .Software(name: name)
        }
        
        func toHardware() -> Purchase.Category {
            .Hardware(name: name)
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    return NavigationStack {
        EditPurchaseView(path: .constant([]))
    }.modelContainer(container)
}
