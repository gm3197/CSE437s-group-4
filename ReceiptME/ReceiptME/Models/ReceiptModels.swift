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
    var clean: Bool?
}

// MARK: - Detailed Receipt
struct ReceiptDetails: Codable, Identifiable {
    var id: Int
    var owner_id: Int
    var clean: Bool
    var date: String
    var merchant: String
    var merchant_address: String
    var merchant_domain: String
    var payment_method: String
    var items: [ReceiptItem]
    var tax: Double
}

// no ID on this request, the ID will be assigned after item is created in backend, see APIService.addReceiptItem
struct NewReceiptItemRequest: Codable {
    var description: String
    var price: Double
    var category: Int?
}

struct NewReceiptItemResponse: Codable {
    var item_id: Int
}

struct ReceiptItem: Codable, Identifiable {
    // This id is generated locally and won't be decoded from the JSON.
    var id: Int // UUID = UUID() // HAVE TO GET + REASSIGN THIS VALUE WHEN RECEIPT ITEM IS CREATED
    var description: String
    var price: Double
    var category: Int?

    private enum CodingKeys: String, CodingKey {
        case id, description, price, category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode name as optional; if missing, use "Unknown Item"
        
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? "Unknown Item"
        self.price = try container.decode(Double.self, forKey: .price)
        self.category = try container.decodeIfPresent(Int.self, forKey: .category) ?? nil
    }
    
    // Standard initializer for convenience.
    init(description: String, price: Double, id: Int, category: Int?) {
        // NEW
        self.id = id
        self.description = description
        self.price = price
        self.category = category
    }
}

// MARK: - Categories
struct GetCategoriesResponse: Codable {
    var categories: [Category]
}

struct Category: Codable, Identifiable {
    var id: Int
    var name: String
    var monthly_goal: Double
    var month_spend: Double
}

struct CreateCategoryRequest: Codable {
    var name: String
    var monthly_goal: Double
}

typealias UpdateCategoryRequest = CreateCategoryRequest
