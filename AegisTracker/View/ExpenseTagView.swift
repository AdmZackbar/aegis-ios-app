//
//  ExpenseTagView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 4/20/26.
//

import SwiftData
import SwiftUI

extension ExpenseTag {
    var startDate: Date? {
        expenses.min(by: { $0.date < $1.date })?.date
    }
    var endDate: Date? {
        expenses.max(by: { $0.date < $1.date })?.date
    }
    
    func computeClosestTime(date: Date) -> TimeInterval? {
        if expenses.isEmpty {
            return nil
        }
        if (startDate!...endDate!).contains(date) {
            return .zero
        }
        let start = abs(date.timeIntervalSince(startDate!))
        let end = abs(date.timeIntervalSince(endDate!))
        return start < end ? start : end
    }
}

struct ExpenseTagView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    let tag: ExpenseTag
    
    @State private var showAdd = false
    @State private var filter = ""
    @State private var showFilter = true
    @State private var deleteShowing = false
    @State private var deleteItem: Expense? = nil
    
    var body: some View {
        VStack {
            if !tag.expenses.isEmpty {
                headerView()
                Form {
                    Section {
                        expenseListView()
                    } header: {
                        HStack {
                            Text("Expenses")
                            Spacer()
                            Button {
                                showAdd = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    if !expenses.isEmpty {
                        Section("Suggestions") {
                            suggestedExpenses()
                        }
                    }
                }
            } else {
                Form {
                    Button("Add Expense(s)") {
                        showAdd = true
                    }
                    if !expenses.isEmpty {
                        Section("Suggestions") {
                            suggestedExpenses()
                        }
                    }
                }
            }
        }.navigationTitle(tag.name)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.init(uiColor: UIColor.secondarySystemBackground))
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    List(expenses.filter({ !$0.tags.contains(tag) && isExpenseFiltered($0) })) { expense in
                        Button {
                            withAnimation {
                                tag.expenses.append(expense)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                ExpenseEntryView(expense: expense)
                            }.contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }.navigationTitle("Select Expense(s)")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    showAdd = false
                                } label: {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                }.searchable(text: $filter, isPresented: $showFilter)
            }
    }
    
    private func isExpenseFiltered(_ expense: Expense) -> Bool {
        if filter.isEmpty {
            return true
        }
        return expense.category.localizedCaseInsensitiveContains(filter) || expense.payee.localizedCaseInsensitiveContains(filter) || expense.notes.localizedCaseInsensitiveContains(filter)
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        Text(tag.totalAmount.toString())
            .font(.system(size: 48, weight: .bold, design: .rounded))
        VStack(alignment: .leading, spacing: 6) {
            let earliest = tag.startDate!.formatted(date: .abbreviated, time: .omitted)
            let latest = tag.endDate!.formatted(date: .abbreviated, time: .omitted)
            if earliest != latest {
                HStack {
                    Text(earliest)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text(latest)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            } else {
                Text(earliest)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }.padding([.leading, .trailing], 28)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func expenseListView() -> some View {
        ForEach(tag.expenses.sorted(by: { $0.date > $1.date }), id: \.hashValue) { expense in
            expenseEntry(expense)
                .swipeActions {
                    deleteButton(expense)
                }
                .contextMenu {
                    Button {
                        navigationStore.push(ExpenseViewType.byCategory(name: expense.category))
                    } label: {
                        Label("View '\(expense.category)'", systemImage: "tag")
                    }
                    Button {
                        navigationStore.push(ExpenseViewType.byPayee(name: expense.payee))
                    } label: {
                        Label("View '\(expense.payee)'", systemImage: "person")
                    }
                    Divider()
                    deleteButton(expense)
                }
        }.alert("Remove Tag from Expense?", isPresented: $deleteShowing) {
            Button("Remove", role: .destructive) {
                if let item = deleteItem {
                    withAnimation {
                        tag.expenses.removeAll(where: { $0 == item })
                        try? modelContext.save()
                    }
                }
            }
        }
    }
    
    private func deleteButton(_ expense: Expense) -> some View {
        Button {
            deleteItem = expense
            deleteShowing = true
        } label: {
            Label("Remove", systemImage: "trash").tint(.red)
        }
    }
    
    @ViewBuilder
    private func expenseEntry(_ expense: Expense) -> some View {
        Button {
            navigationStore.push(ExpenseViewType.view(expense: expense))
        } label: {
            ExpenseEntryView(expense: expense)
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func suggestedExpenses() -> some View {
        var list: [Expense] {
            if tag.expenses.isEmpty {
                expenses.filter({ !$0.tags.contains(tag) })
            } else {
                expenses.filter({ !$0.tags.contains(tag) })
                    .sorted(by: { tag.computeClosestTime(date: $0.date)! < tag.computeClosestTime(date: $1.date)! })
            }
        }
        ForEach(list.prefix(6)) { expense in
            HStack {
                Button {
                    withAnimation {
                        tag.expenses.append(expense)
                    }
                } label: {
                    Image(systemName: "plus")
                        .bold()
                }
                expenseEntry(expense)
            }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        ExpenseTagsView()
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
            .environmentObject(navigationStore)
    }
}
