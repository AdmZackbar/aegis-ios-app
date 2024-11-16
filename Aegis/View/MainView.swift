//
//  MainView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/10/24.
//

import SwiftUI

struct MainView: View {
    static let ExpenseCategories: [String : [String]] = {
        var map: [String : [String]] = [:]
        map["Car"] = ["Gas", "Car Maintenance", "Car Insurance", "Car Payment", "Parking"]
        map["Food"] = ["Groceries", "Snacks", "Restaurant", "Fast Food", "Cookware", "Grocery Membership"]
        map["Housing"] = ["Rent", "Mortgage Bill", "Housing Payment", "Utility Bill", "Housing Maintenance", "Appliances", "Furniture", "Decor", "Fuel"]
        map["Media"] = ["Video Games", "Music", "TV", "Books", "Games", "Other Media"]
        map["Medicine"] = ["Dental", "Vision", "Medicine", "Clinic", "Physical Therapy", "Hospital"]
        map["Personal"] = ["Apparel", "Hygiene", "Haircut"]
        map["Recreation"] = ["Sports Facility", "Sports Gear", "Sports Event", "Recreation Event"]
        map["Technology"] = ["Tech Devices", "Device Accessories", "Computer Parts", "Peripherals", "Software", "Tech Service", "Digital Assets"]
        map["Travel"] = ["Accomodations", "Rental Car", "Airfare", "Rideshare"]
        map["Other"] = ["Gift", "Charity", "Taxes", "Contributions"]
        return map
    }()
    
    @State private var path: [ViewType] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("View") {
                    Button {
                        path.append(.ListByCategory())
                    } label: {
                        HStack {
                            Label("List By Category", systemImage: "folder")
                            Spacer()
                        }.frame(height: 36).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Button {
                        path.append(.ListByDate)
                    } label: {
                        HStack {
                            Label("List By Date", systemImage: "calendar")
                            Spacer()
                        }.frame(height: 36).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
                Section("Record") {
                    Button {
                        path.append(.AddExpense)
                    } label: {
                        HStack {
                            Label("Add Expense", systemImage: "cart.badge.plus")
                            Spacer()
                        }.frame(height: 36).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }.navigationTitle("Aegis")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: ViewType.self, destination: computeDestination)
        }
    }
    
    @ViewBuilder
    private func computeDestination(viewType: ViewType) -> some View {
        switch viewType {
        case .ListByCategory(let category):
            CategoryListView(path: $path, selectedCategory: category)
        case .ListByDate:
            DateListView(path: $path)
        case .AddExpense:
            EditExpenseView(path: $path)
        case .EditExpense(let expense):
            EditExpenseView(path: $path, expense: expense)
        case .ViewGroceryListExpense(let expense):
            GroceryListExpenseView(path: $path, expense: expense)
        }
    }
}

enum ViewType: Hashable {
    case ListByCategory(category: String? = nil)
    case ListByDate
    case AddExpense
    case EditExpense(expense: Expense)
    case ViewGroceryListExpense(expense: Expense)
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    return MainView().modelContainer(container)
}
