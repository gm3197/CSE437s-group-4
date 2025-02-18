// GET /receipts
struct ReceiptList: Codable {
	var receipts: [ReceiptPreview]
}

struct ReceiptPreview: Codable {
	var id: Int
	var date: String
	var merchant: String
	var total: Double
	var clean: Bool
}

// GET /receipts/<id>
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

struct ReceiptItem: Codable {
	var id: Int
	var description: String
	var price: Double
}
