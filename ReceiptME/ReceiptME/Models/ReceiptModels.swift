//
//  ReceiptModels.swift
//  ReceiptME
//
//  Created by [Your Name] on [Date]
//

import Foundation

// MARK: - Basic Receipt List
struct ReceiptList: Codable {
    var receipts: [ReceiptPreview]
}

struct ReceiptPreview: Codable {
    var id: Int
    var merchant: String
    var date: String
    var total: Double
}

// MARK: - For Scan/Upload
struct ReceiptScanResult: Codable {
    let success: Bool
    let receipt_id: Int?
}

// MARK: - Core Receipt (simpler representation, if needed)
struct Receipt: Codable, Identifiable {
    var id: Int
    var merchant: String
    var date: String
    var total: Double
}

// MARK: - Detailed Receipt
struct ReceiptDetails: Codable, Identifiable {
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
    var id: Int?
    var name: String
}

struct ReceiptItem: Codable, Identifiable {
    // This id is generated locally and won't be decoded from the JSON.
    var id: UUID = UUID()
    var description: String
    var price: Double
    //var category: String?

    private enum CodingKeys: String, CodingKey {
        case description, price
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode name as optional; if missing, use "Unknown Item"
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? "Unknown Item"
        self.price = try container.decode(Double.self, forKey: .price)
    }
    
    // Standard initializer for convenience.
    init(description: String, price: Double) {
        self.description = description
        self.price = price
    }
}
