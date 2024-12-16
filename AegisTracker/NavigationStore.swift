//
//  NavigationStore.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/15/24.
//

import SwiftUI

@MainActor
final class NavigationStore: ObservableObject {
    @Published var path = NavigationPath()
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    func encoded() -> Data? {
        try? path.codable.map(encoder.encode)
    }
    
    func restore(from data: Data) {
        do {
            let codable = try decoder.decode(
                NavigationPath.CodableRepresentation.self, from: data
            )
            path = NavigationPath(codable)
        } catch {
            path = NavigationPath()
        }
    }
    
    func push(_ value: any Hashable) {
        path.append(value)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func replace(_ value: any Hashable) {
        pop()
        push(value)
    }
}
