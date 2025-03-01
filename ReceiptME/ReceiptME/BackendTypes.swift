// POST /receipts/auto
struct ReceiptScanResult: Codable {
	var success: Bool
	var receipt_id: Int? // present if success == true
}

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
  var auto: Bool // true if this receipt item was automatically added via scan, false if manually added by user
}

// Used in the following requests to create/edit a receipt item:
// POST /receipts/<id>/items
// PATCH /receipts/<id>/items/<item_id>
struct ReceiptItemRequestData: Codable {
    var description: String
    var price: Double
}
