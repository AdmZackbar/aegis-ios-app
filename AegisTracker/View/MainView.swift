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
    
    static let ExpenseCategoryColors: [String : Color] = [
        "Car": Color.indigo,
        "Food": Color.blue,
        "Housing": Color.red,
        "Media": Color.cyan,
        "Medicine": Color.pink,
        "Personal": Color.orange,
        "Recreation": Color.yellow,
        "Technology": Color.green,
        "Travel": Color.purple,
        "Other": Color.gray
    ]
    
    @StateObject private var navigationStore = NavigationStore()
    
    @SceneStorage("navigation")
    private var navigationData: Data?
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            List {
                Section {
                    Button {
                        navigationStore.path.append(ViewType.dashboard)
                    } label: {
                        button("Dashboard", icon: "house")
                    }.buttonStyle(.plain)
                }
                Section("Expenses") {
                    Button {
                        navigationStore.path.append(RecordType.addExpense)
                    } label: {
                        button("Add Expense", icon: "text.badge.plus")
                    }.buttonStyle(.plain)
                    Button {
                        navigationStore.path.append(ViewType.date)
                    } label: {
                        button("View By Date", icon: "calendar")
                    }.buttonStyle(.plain)
                    Button {
                        navigationStore.path.append(ViewType.category())
                    } label: {
                        button("View By Category", icon: "folder")
                    }.buttonStyle(.plain)
                    Button {
                        navigationStore.path.append(ViewType.payee())
                    } label: {
                        button("View By Payee", icon: "person")
                    }.buttonStyle(.plain)
                }
            }.navigationTitle("Aegis")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: ViewType.self, destination: Self.computeDestination)
                .navigationDestination(for: RecordType.self, destination: Self.computeDestination)
        }.environmentObject(navigationStore)
    }
    
    @ViewBuilder
    func button(_ text: String, icon: String) -> some View {
        HStack {
            Label(text, systemImage: icon)
            Spacer()
        }.frame(height: 36).contentShape(Rectangle())
    }
    
    @ViewBuilder
    static func computeDestination(type: ViewType, navigationStore: NavigationStore) -> some View {
        Self.computeDestination(type: type)
            .environmentObject(navigationStore)
    }
    
    @ViewBuilder
    static func computeDestination(type: ViewType) -> some View {
        switch type {
        case .dashboard:
            DashboardYearView()
        case .category(let name):
            if let name {
                ExpenseCategoryView(category: name)
            } else {
                ExpenseCategoryListView()
            }
        case .date:
            DateListView()
        case .month(let year, let month):
            MonthListView(month: month, year: year)
        case .payee(let name):
            if let name {
                ExpensePayeeView(payee: name)
            } else {
                ExpensePayeeListView()
            }
        case .expense(let expense):
            ExpenseView(expense: expense)
        }
    }
    
    @ViewBuilder
    static func computeDestination(type: RecordType, navigationStore: NavigationStore) -> some View {
        Self.computeDestination(type: type)
            .environmentObject(navigationStore)
    }
    
    @ViewBuilder
    static func computeDestination(type: RecordType) -> some View {
        switch type {
        case .addExpense:
            ExpenseEditView()
        case .editExpense(let expense):
            ExpenseEditView(expense: expense)
        }
    }
}

enum ViewType: Hashable {
    case dashboard
    case category(name: String? = nil)
    case date
    case month(year: Int, month: Int)
    case payee(name: String? = nil)
    case expense(expense: Expense)
}

enum RecordType: Hashable {
    case addExpense
    case editExpense(expense: Expense)
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    MainView()
}
