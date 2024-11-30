//
//  Loan.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/28/24.
//

import Foundation
import SwiftData

typealias Loan = SchemaV1.Loan
typealias LoanPayment = SchemaV1.LoanPayment

extension SchemaV1 {
    @Model
    final class Loan {
        var name: String
        var startDate: Date
        var amount: Price
        var metaData: MetaData
        
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
        
        @Relationship(deleteRule: .cascade, inverse: \LoanPayment.loan)
        var payments: [LoanPayment] = []
        
        init(name: String, startDate: Date, amount: Price, metaData: MetaData) {
            self.name = name
            self.startDate = startDate
            self.amount = amount
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
    }
    
    @Model
    final class LoanPayment {
        var loan: Loan!
        var date: Date
        var type: LoanType
        var details: String
        
        init(loan: Loan? = nil, date: Date, type: LoanType, details: String) {
            self.loan = loan
            self.date = date
            self.type = type
            self.details = details
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
            case Regular(details: RegularPaymentDetails)
            case Principal(principal: Price)
        }
    }
    
    struct RegularPaymentDetails: Codable {
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
