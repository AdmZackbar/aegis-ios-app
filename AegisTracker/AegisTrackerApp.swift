//
//  AegisApp.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/9/24.
//

import SwiftUI
import SwiftData

@main
struct AegisApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(CurrentSchema.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            try tryAddDefaultBudgetCategories(container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    private static func tryAddDefaultBudgetCategories(_ container: ModelContainer) throws {
        var query = FetchDescriptor<BudgetCategory>()
        query.fetchLimit = 1
        guard try container.mainContext.fetch(query).isEmpty else { return }
        let mainCategory: BudgetCategory = .init(name: "Main Budget", children: [
            .init(name: "Housing", colorValue: Color.init(hex: "#0056D6").hexValue),
            .init(name: "Food", colorValue: Color.init(hex: "#99244F").hexValue),
            .init(name: "Transportation", colorValue: Color.init(hex: "#D38301").hexValue),
            .init(name: "Healthcare", colorValue: Color.init(hex: "#01C7FC").hexValue),
            .init(name: "Personal", colorValue: Color.init(hex: "#FF6250").hexValue),
            .init(name: "Entertainment", colorValue: Color.init(hex: "#D357FE").hexValue)
        ])
        container.mainContext.insert(mainCategory)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }.modelContainer(sharedModelContainer)
    }
}
