//
//  Item.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/9/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
