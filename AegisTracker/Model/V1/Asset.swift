//
//  Asset.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/10/24.
//

import Foundation
import SwiftData

typealias Asset = SchemaV1.Asset

extension SchemaV1 {
    @Model
    final class Asset {
        var name: String = ""
        var purchaseDate: Date = Date()
        var totalCost: Price = Price.Cents(0)
        var valuations: [Valuation] = []
        var loan: Loan? = nil
        
        init(name: String, purchaseDate: Date, totalCost: Price, valuations: [Valuation], loan: Loan? = nil) {
            self.name = name
            self.purchaseDate = purchaseDate
            self.totalCost = totalCost
            self.valuations = valuations
            self.loan = loan
        }
        
        struct Valuation: Codable {
            var date: Date
            var amount: Price
        }
        
        struct Loan: Codable {
            var amount: Price = Price.Cents(0)
            var payments: [Payment] = []
            var metaData: MetaData = MetaData(lender: "", rate: 0.0, term: .Years(num: 0), category: "")
            // Computed values
            var totalPaid: Price {
                get {
                    payments.map({ $0.getAmount() }).reduce(.Cents(0), +)
                }
            }
            var principalPaid: Price {
                get {
                    payments.map({ $0.getPrincipal() }).reduce(.Cents(0), +)
                }
            }
            var remainingAmount: Price {
                get {
                    amount - principalPaid
                }
            }
            
            init(amount: Price, payments: [Payment], metaData: MetaData) {
                self.amount = amount
                self.payments = payments
                self.metaData = metaData
            }
            
            struct MetaData: Codable {
                var lender: String
                var rate: Double
                var term: Term
                var category: String
                
                enum Term: Codable {
                    case Years(num: Int)
                }
            }
            
            struct Payment: Codable {
                var date: Date = Date()
                var type: LoanType = LoanType.Principal(principal: .Cents(0))
                var notes: String = ""
                
                init(date: Date, type: LoanType, notes: String) {
                    self.date = date
                    self.type = type
                    self.notes = notes
                }
                
                func getAmount() -> Price {
                    switch type {
                    case .Regular(let details):
                        return details.total
                    case .Principal(let principal):
                        return principal
                    }
                }
                
                func getPrincipal() -> Price {
                    switch type {
                    case .Regular(let details):
                        return details.principal
                    case .Principal(let principal):
                        return principal
                    }
                }
                
                enum LoanType: Codable {
                    case Regular(details: RegularDetails)
                    case Principal(principal: Price)
                }
                
                struct RegularDetails: Codable {
                    var principal: Price
                    var interest: Price
                    var escrow: Price
                    var other: Price
                    var total: Price {
                        get {
                            principal + interest + escrow + other
                        }
                    }
                }
            }
        }
    }
}
