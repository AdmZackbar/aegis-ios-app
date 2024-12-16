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
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }.modelContainer(sharedModelContainer)
    }
}
