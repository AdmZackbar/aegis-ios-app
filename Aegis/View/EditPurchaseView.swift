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
    @State private var gasAmount: Double = 0.0
    @State private var gasPrice: Int = 0
    @State private var gasOctane: Int = 87
    
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
            switch purchase.category {
            case .Basic(let name, let details):
                category = Category(name)
                self.details = details
            case .Gas(let numGallons, let costPerGallon, let octane):
                gasAmount = numGallons
                switch costPerGallon {
                case .Cents(let p):
                    gasPrice = p
                }
                gasOctane = octane
            default:
                break
            }
        default:
            break
        }
    }
    
    private func save() {
        purchase.date = date
        purchase.seller = seller
        purchase.price = .Cents(price)
        if let category = category {
            switch category.name {
            case "Gas":
                purchase.category = .Gas(numGallons: gasAmount, costPerGallon: .Cents(gasPrice), octane: gasOctane)
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
                }.tint(.black)
            }
        }
    }
    
    @ViewBuilder
    private func createCategoryView(_ categoryName: String) -> some View {
        switch categoryName {
        case "Gas":
            gasEditor()
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
            TextField("required", value: $gasAmount, formatter: formatter)
                .keyboardType(.decimalPad)
        }
        HStack {
            Text("Cost per Gallon:")
            CurrencyTextField(numberFormatter: currencyFormatter, value: $gasPrice)
        }
        HStack {
            Text("Octane:")
            Spacer()
            Picker("", selection: $gasOctane) {
                Text("87").tag(87)
                Text("89").tag(89)
                Text("91").tag(91)
                Text("93").tag(93)
            }.pickerStyle(.segmented)
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
            .init("Additional Mortgage Payment"),
            .init("Housing Maintenance"),
            .init("Housing Improvements"),
            .init("Housing Utilities", children: [
                .init("Electric Bill"),
                .init("Water Bill"),
                .init("Other Utility Bill"),
                .init("Internet Bill")
            ])
        ]),
        .init("Food", children: [
            .init("Groceries"),
            .init("Fast Food"),
            .init("Restaurant")
        ]),
        .init("Car", children: [
            .init("Gas"),
            .init("Maintenance"),
            .init("Car Fees")
        ]),
        .init("Sports", children: [
            .init("Gym"),
            .init("Equipment"),
            .init("Events")
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
            .init("Medicine"),
            .init("Healthcare")
        ])
    ]
}

#Preview {
    let container = createTestModelContainer()
    return NavigationStack {
        EditPurchaseView(path: .constant([]))
    }.modelContainer(container)
}
