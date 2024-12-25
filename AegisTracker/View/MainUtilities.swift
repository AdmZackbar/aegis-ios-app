//
//  MainUtilities.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/16/24.
//

import SwiftUI

extension Int {
    func monthText() -> String {
        Calendar.current.monthSymbols[self - 1]
    }
    
    func shortMonthText() -> String {
        Calendar.current.shortMonthSymbols[self - 1]
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
    
    static func from(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}

extension DateInterval {
    static func monthOf(_ date: Date) -> DateInterval {
        return .init(start: .from(year: date.year, month: date.month, day: 1),
                     end: .from(year: date.year, month: date.month,
                                day: Calendar.current.range(of: .day, in: .month, for: date)!.upperBound - 1))
    }
    
    static func yearOf(_ date: Date) -> DateInterval {
        return .init(start: .from(year: date.year, month: 1, day: 1),
                     end: .from(year: date.year, month: 12,
                                day: Calendar.current.range(of: .day, in: .month, for: .from(year: date.year, month: 12, day: 1))!.upperBound - 1))
    }
    
    static func yearToDate(_ date: Date) -> DateInterval {
        return .init(start: .from(year: date.year, month: 1, day: 1),
                     end: .from(year: date.year, month: date.month,
                                day: Calendar.current.range(of: .day, in: .month, for: date)!.upperBound - 1))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 24) & 0xff) / 255,
            green: Double((hex >> 16) & 0xff) / 255,
            blue: Double((hex >> 08) & 0xff) / 255,
            opacity: Double((hex >> 00) & 0xff) / 255
        )
    }
    
    var hexValue: UInt? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        let multiplier = CGFloat(255.999999)

        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        
        return UInt(red * multiplier) << 24 | UInt(green * multiplier) << 16 | UInt(blue * multiplier) << 8 | UInt(alpha * multiplier)
    }
    
    var hexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        let multiplier = CGFloat(255.999999)

        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }

        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        }
        else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
}
