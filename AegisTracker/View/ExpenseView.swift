//
//  ExpenseView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/12/24.
//

import SwiftData
import SwiftUI

struct ExpenseView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    let expense: Expense
    
    @Binding private var path: [ViewType]
    @State private var showDelete: Bool = false
    
    init(path: Binding<[ViewType]>, expense: Expense) {
        self._path = path
        self.expense = expense
    }
    
    var body: some View {
        VStack(spacing: 4) {
            headerView()
            Form {
                detailView()
                let relatedExpenses = expenses.filter({ $0.payee == expense.payee && $0.category == expense.category && $0 != expense })
                if !relatedExpenses.isEmpty {
                    payeeExpenseList(relatedExpenses)
                }
            }.scrollContentBackground(.hidden)
            footerActionsView()
        }.navigationTitle("View Expense")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.init(uiColor: UIColor.systemGroupedBackground))
            .confirmationDialog("Are you sure you want to delete this expense?", isPresented: $showDelete) {
                Button("Delete", role: .destructive, action: delete)
            } message: {
                Text("You cannot undo this action")
            }
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        Text(expense.amount.toString())
            .font(.system(size: 48, weight: .bold, design: .rounded))
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.category)
                        .textCase(.uppercase)
                        .font(.caption)
                        .fontWeight(.light)
                    Text(expense.payee)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .bold()
                }
                Spacer()
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            if !expense.notes.isEmpty {
                Text(expense.notes)
                    .font(.subheadline)
                    .lineLimit(5)
            }
        }.padding([.leading, .trailing], 28)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func detailView() -> some View {
        switch expense.details {
        case .Tip(let amount):
            HStack {
                Text("Tip:").bold()
                Spacer()
                Text(amount.toString()).italic()
            }
        case .Items(let list):
            itemDetailView(list)
        case .Fuel(let details):
            VStack(alignment: .leading, spacing: 4) {
                Text(details.user).bold()
                HStack {
                    Text("\(details.amount.formatted()) gallons")
                    Spacer()
                    Text("\(details.rate.formatted()) $/gal").italic()
                }
            }
        case .Bill(let details):
            billDetailView(details)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func itemDetailView(_ list: Expense.ItemList) -> some View {
        if !list.items.isEmpty {
            Section("Items") {
                ForEach(list.items, id: \.hashValue, content: ExpenseItemEntryView.init)
            }
        }
    }
    
    @ViewBuilder
    private func billDetailView(_ details: Expense.BillDetails) -> some View {
        if !details.bills.isEmpty {
            Section("Bills") {
                ForEach(details.bills, id: \.hashValue, content: ExpenseBillEntryView.init)
            }
        }
    }
    
    @ViewBuilder
    private func payeeExpenseList(_ expenses: [Expense]) -> some View {
        Section("\(expense.payee) \(expense.category)") {
            ForEach(expenses, id: \.hashValue) { e in
                Button {
                    path.append(.ViewExpense(expense: e))
                } label: {
                    ExpenseEntryView(expense: e, omitted: [.Category, .Payee])
                        .contentShape(Rectangle())
                }.foregroundStyle(.primary)
            }
        }
    }
    
    @ViewBuilder
    private func footerActionsView() -> some View {
        Grid {
            GridRow {
                Button {
                    path.append(.EditExpense(expense: expense))
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                        .bold()
                        .frame(maxWidth: .infinity, maxHeight: 30)
                }.tint(.blue)
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .bold()
                        .frame(maxWidth: .infinity, maxHeight: 30)
                }
            }.gridColumnAlignment(.center)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle)
        }.padding([.leading, .trailing], 20)
            .padding([.top, .bottom], 8)
    }
    
    private func delete() {
        modelContext.delete(expense)
        if !path.isEmpty {
            path.removeLast()
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    NavigationStack {
        ExpenseView(path: .constant([]), expense: .init(date: .now, payee: "Publix", amount: .Cents(34189), category: "Groceries", notes: "November grocery run", details: .Items(list: .init(items: [
            .init(name: "Chicken Thighs", brand: "Kirkland Signature", quantity: .Unit(num: 4.51, unit: "lb"), total: .Cents(3541)),
            .init(name: "Hot Chocolate", brand: "Swiss Miss", quantity: .Discrete(1), total: .Cents(799), discount: .Cents(300)),
            .init(name: "Chicken Chunks", brand: "Just Bare", quantity: .Discrete(2), total: .Cents(1499))
        ]))))
    }
}
