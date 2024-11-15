//
//  Schema.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/9/24.
//

import SwiftData

typealias CurrentSchema = SchemaV1

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [Expense.self, Revenue.self]
    }
}
