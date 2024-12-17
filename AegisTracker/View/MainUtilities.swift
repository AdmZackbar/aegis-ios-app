//
//  MainUtilities.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/16/24.
//

import Foundation

extension Int {
    func monthText() -> String {
        Calendar.current.monthSymbols[self - 1]
    }
    
    func yearText() -> String {
        self.formatted(.number.grouping(.never))
    }
}

extension Date {
    var year: Int {
        get {
            Calendar.current.component(.year, from: self)
        }
    }
    var month: Int {
        get {
            Calendar.current.component(.month, from: self)
        }
    }
    var day: Int {
        get {
            Calendar.current.component(.day, from: self)
        }
    }
}
