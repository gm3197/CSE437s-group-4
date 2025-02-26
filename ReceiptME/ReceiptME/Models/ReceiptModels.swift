// COPPIED FROM JIMMY'S APPNVAIGATION (REMOTE) BRANCH -- REPLCAES BACKEND TYPES FILE

//  ReceiptModels.swift
//  ReceiptME
//
//  Created by Jimmy Lancaster on 2/18/25.
//

import Foundation


struct Receipt: Identifiable, Codable {
    var id: Int
    var merchant: String
    var date: String
    var total: Double
}

// MARK: - Receipt Scan Response
struct ReceiptScanResult: Codable {
    var success: Bool
    var receipt_id: Int? // present if success == true
}

// MARK: - Receipt List
struct ReceiptList: Codable {
    var receipts: [ReceiptPreview]
}

struct ReceiptPreview: Codable, Identifiable {
    var id: Int
    var date: String
    var merchant: String
    var total: Double
    var clean: Bool
}

// MARK: - Receipt Details
struct ReceiptDetails: Codable {
    var id: Int
    var owner_id: Int
    var clean: Bool
    var date: String
    var merchant: Merchant
    var payment_method: String
    var items: [ReceiptItem]
    var tax: Double
}

struct Merchant: Codable {
    var name: String
    var address: String
    var domain: String
}

struct ReceiptItem: Codable, Identifiable {
    var id: Int
    var description: String
    var price: Double
}
