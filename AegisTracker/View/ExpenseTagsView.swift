//
//  ExpenseTagsView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 4/20/26.
//

import SwiftData
import SwiftUI

struct ExpenseTagsView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \ExpenseTag.name) var tags: [ExpenseTag]
    
    @State private var showAdd = false
    @State private var showEdit = false
    @State private var showDelete = false
    @State private var name = ""
    @State private var editTag: ExpenseTag? = nil
    
    var body: some View {
        List(tags) { tag in
            Button {
                navigationStore.push(ExpenseViewType.viewTag(tag: tag))
            } label: {
                tagView(tag)
            }.buttonStyle(.plain)
                .contextMenu {
                    editButton(tag)
                    deleteButton(tag).tint(.red)
                }
                .swipeActions {
                    deleteButton(tag).tint(.red)
                    editButton(tag).tint(.blue)
                }
        }.navigationTitle("View Expense Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add New Group", systemImage: "plus")
                    }
                }
            }
            .alert("Add New Group:", isPresented: $showAdd) {
                TextField("Name", text: $name)
                Button("Cancel") {
                    showAdd = false
                }
                Button("Add") {
                    modelContext.insert(ExpenseTag(name: name))
                    name = ""
                    showAdd = false
                }.disabled(isNameInvalid())
            }
            .alert("Edit Group Name:", isPresented: $showEdit) {
                TextField("Name", text: $name)
                Button("Cancel") {
                    showEdit = false
                }
                Button("Save") {
                    if let tag = editTag {
                        withAnimation {
                            tag.name = name
                        }
                    }
                    name = ""
                    showEdit = false
                }.disabled(isNameInvalid())
            }
            .alert("Delete \(editTag?.name ?? "tag")?", isPresented: $showDelete) {
                Button("Delete", role: .destructive) {
                    if let tag = editTag {
                        withAnimation {
                            modelContext.delete(tag)
                        }
                    }
                    showDelete = false
                }.disabled(editTag == nil)
            }
    }
    
    private func editButton(_ tag: ExpenseTag) -> some View {
        Button {
            name = tag.name
            editTag = tag
            showEdit = true
        } label: {
            Label("Edit Name", systemImage: "pencil.circle")
        }
    }
    
    private func deleteButton(_ tag: ExpenseTag) -> some View {
        Button {
            editTag = tag
            showDelete = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func tagView(_ tag: ExpenseTag) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(tag.name)
                Spacer()
                Text(tag.totalAmount.toString())
            }.fontWeight(.bold)
            if !tag.expenses.isEmpty {
                HStack {
                    Text("\(tag.expenses.count) expense(s)")
                    Spacer()
                    let start = tag.startDate!.formatted(date: .abbreviated, time: .omitted)
                    let end = tag.endDate!.formatted(date: .abbreviated, time: .omitted)
                    if start == end {
                        Text(start)
                    } else {
                        Text("\(start) - \(end)")
                    }
                }.font(.subheadline)
            }
        }.contentShape(Rectangle())
    }
    
    private func isNameInvalid() -> Bool {
        if (name.isEmpty) {
            return true
        }
        return tags.contains(where: { $0.name == name })
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
