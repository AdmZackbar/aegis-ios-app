//
//  MainView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/10/24.
//

import SwiftData
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
    
    @Query var expenses: [Expense]
    
    @State private var path: [ViewType] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("View") {
                    Button {
                        path.append(.Dashboard)
                    } label: {
                        HStack {
                            Label("Dashboard", systemImage: "house")
                            Spacer()
                        }.frame(height: 36).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Button {
                        path.append(.NetWorth)
                    } label: {
                        HStack {
                            Label("Net Worth", systemImage: "dollarsign")
                            Spacer()
                        }.frame(height: 36).contentShape(Rectangle())
                    }.buttonStyle(.plain)
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
                    Button {
                        path.append(.AddLoan)
                    } label: {
                        HStack {
                            Label("Add Loan", systemImage: "plus")
                            Spacer()
                        }.frame(height: 36).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Button {
                        for expense in expenses {
                            switch expense.details {
                            case .Generic(let details):
                                expense.notes = details
                            case .Tag(let tag, let details):
                                expense.notes = details
                                expense.detailType = .Tag(name: tag)
                            case .Tip(let tip, let details):
                                expense.notes = details
                                expense.detailType = .Tip(amount: tip)
                            case .Bill(let details):
                                expense.notes = details.details ?? ""
                                expense.detailType = .Bill(details: .init(types: details.types, tax: details.tax))
                            case .Groceries(let list):
                                expense.detailType = .Foods(list: list)
                            case .Fuel(let amount, let rate, _, let user):
                                expense.detailType = .Fuel(details: .init(amount: amount, rate: rate, user: user))
                            default:
                                break
                            }
                            expense.details = nil
                        }
                    } label: {
                        HStack {
                            Label("Transfer Data", systemImage: "plus")
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
        case .Dashboard:
            DashboardYearView(path: $path)
        case .NetWorth:
            NetWorthView(path: $path)
        case .ListByCategory(let category):
            CategoryListView(path: $path, selectedCategory: category)
        case .ListByDate:
            DateListView(path: $path)
        case .ListByMonth(let month, let year):
            MonthListView(path: $path, month: month, year: year)
        case .AddExpense:
            ExpenseEditView(path: $path)
        case .EditExpense(let expense):
            ExpenseEditView(path: $path, expense: expense)
        case .ViewGroceryListExpense(let expense):
            ExpenseGroceryListView(path: $path, expense: expense)
        case .ViewLoan(let loan):
            LoanView(path: $path, loan: loan)
        case .AddLoan:
            EditLoanView(path: $path)
        case .EditLoan(let loan):
            EditLoanView(path: $path, loan: loan)
        }
    }
}

enum ViewType: Hashable {
    case Dashboard
    case NetWorth
    case ListByCategory(category: String? = nil)
    case ListByDate
    case ListByMonth(month: Int, year: Int)
    case AddExpense
    case EditExpense(expense: Expense)
    case ViewGroceryListExpense(expense: Expense)
    case ViewLoan(loan: Loan)
    case AddLoan
    case EditLoan(loan: Loan)
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    return MainView().modelContainer(container)
}
