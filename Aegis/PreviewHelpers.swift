//
//  PreviewHelpers.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/10/24.
//

import Foundation
import SwiftData

func createTestModelContainer() -> ModelContainer {
    let schema = Schema(CurrentSchema.models)
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    return container
}
