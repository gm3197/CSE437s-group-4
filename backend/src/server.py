import db
import bottle
from google.oauth2 import id_token as google_auth
from google.auth.transport import requests as google_requests
from PIL import Image
import pytesseract
from openai import OpenAI
import json
import io
import os
from datetime import datetime

openai_client = OpenAI()

@bottle.post("/auth/google/token")
def	google_auth_token():
	data = bottle.request.json
	if data is None or "idToken" not in data:
		bottle.response.status = 400
		return "Bad request"
	token_str = data["idToken"]
	token_data = google_auth.verify_oauth2_token(token_str, google_requests.Request(), os.environ["GOOGLE_AUTH_CLIENT_ID"])

	if not token_data["email_verified"]:
		bottle.response.status = 403
		return "Unauthorized"

	session_token = db.login_user(token_data["email"], token_data["name"])
	return {
		"session": session_token
	}

@bottle.get("/categories")
def get_budget():
		return get_budget_for_month(datetime.now().year, datetime.now().month)

@bottle.get("/categories/<year>/<month>")
def get_budget_for_month(year, month):
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	try:
		year = int(year)
		month = int(month)
	except:
		bottle.response.status = 404
		return "Not Found"
		
	categories = db.get_budget_categories(user_id, year, month)

	return {
		"categories": categories
	}

@bottle.post("/categories")
def create_category():
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	req_data = bottle.request.json

	if "name" not in req_data or "monthly_goal" not in req_data:
		bottle.response.status = 400
		return "Bad request"

	try:
		monthly_goal = float(req_data["monthly_goal"])
	except:
		bottle.response.status = 400
		return "monthly_goal should be a double"

	category_id = db.create_category(user_id, req_data["name"], monthly_goal)

	return {
		"id": category_id,
		"name": req_data["name"],
		"monthly_goal": req_data["monthly_goal"],
		"month_spend": 0.0,
	}

@bottle.delete("/categories/<category_id>")
def delete_category(category_id):
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	category = db.get_category(category_id)
	if category is None:
		bottle.response.status = 404
		return "Not found"

	if category["user_id"] != user_id:
		bottle.response.status = 401
		return "Forbidden"

	db.delete_category(category_id)
	return "Deleted"

@bottle.get("/receipts")
def get_receipts():
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	return {
		"receipts": db.list_receipts(user_id)
	}

@bottle.get("/receipts/<receipt_id>")
def get_receipt(receipt_id):
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	receipt = db.get_receipt(receipt_id)

	if receipt is None:
		bottle.response.status = 404
		return "Not found"

	if receipt["owner_id"] != user_id:
		bottle.response.status = 401
		return "Forbidden"

	return receipt

@bottle.patch("/receipts/<receipt_id>")
def update_receipt(receipt_id):
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	receipt = db.get_receipt(receipt_id)

	if receipt is None:
		bottle.response.status = 404
		return "Not found"

	if receipt["owner_id"] != user_id:
		bottle.response.status = 401
		return "Forbidden"

	req_data = bottle.request.json
	if req_data is None or "merchant" not in req_data or "date" not in req_data:
		bottle.response.status = 400
		return "Bad request"

	db.update_receipt(receipt_id, req_data["merchant"], req_data["date"])

	bottle.response.status = 200
	return ""

@bottle.delete("/receipts/<receipt_id>")
def delete_receipt(receipt_id):
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	receipt = db.get_receipt(receipt_id)

	if receipt is None:
		bottle.response.status = 404
		return "Not found"

	if receipt["owner_id"] != user_id:
		bottle.response.status = 401
		return "Forbidden"

	db.delete_receipt(receipt_id)

	bottle.response.status = 200
	return ""

@bottle.post("/receipts/<receipt_id>/items")
def add_receipt_item(receipt_id):
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	receipt = db.get_receipt(receipt_id)

	if receipt is None:
		bottle.response.status = 404
		return "Not found"

	if receipt["owner_id"] != user_id:
		bottle.response.status = 401
		return "Forbidden"

	req_data = bottle.request.json
	if req_data is None or "price" not in req_data or "description" not in req_data:
		bottle.response.status = 400
		return "Bad request"

	category_id = None
	if "category" in req_data:
		category_id = req_data["category"]

	item_id = db.insert_receipt_item(receipt_id, req_data["price"], req_data["description"], category_id)

	bottle.response.status = 200
	return {
		"item_id": item_id
	}

@bottle.patch("/receipts/<receipt_id>/items/<item_id>")
def edit_receipt_item(receipt_id, item_id):
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	receipt_item = db.get_receipt_item(receipt_id, item_id)	
	if receipt_item is None:
		bottle.response.status = 404
		return "Not found"

	if receipt_item["owner_id"] != user_id:
		bottle.response.status = 401
		return "Forbidden"

	req_data = bottle.request.json
	if req_data is None or "price" not in req_data or "description" not in req_data:
		bottle.response.status = 400
		return "Bad request"

	category_id = req_data["category"] if "category" in req_data else None

	db.update_receipt_item(item_id, req_data["price"], req_data["description"], category_id)

	bottle.response.status = 200
	return

@bottle.delete("/receipts/<receipt_id>/items/<item_id>")
def delete_receipt_item(receipt_id, item_id):
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	receipt_item = db.get_receipt_item(receipt_id, item_id)	
	if receipt_item is None:
		bottle.response.status = 404
		return "Not found"

	if receipt_item["owner_id"] != user_id:
		bottle.response.status = 401
		return "Forbidden"

	db.delete_receipt_item(receipt_id, item_id)
	bottle.response.status = 200
	return


@bottle.get("/receipts/<receipt_id>/scan.png")
def get_receipt_img(receipt_id):
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	receipt = db.get_receipt(receipt_id)

	if receipt is None:
		bottle.response.status = 404
		return "Not found"

	if receipt["owner_id"] != user_id:
		bottle.response.status = 401
		return "Forbidden"

	return bottle.static_file(f"{receipt_id}.png", "receipts")

@bottle.get("/receipts/<receipt_id>/items/<item_id>/scan.png")
def get_receipt_item_img(receipt_id, item_id):
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	receipt_item = db.get_receipt_item(receipt_id, item_id)	
	if receipt_item is None:
		bottle.response.status = 404
		return "Not found"

	if receipt_item["owner_id"] != user_id:
		bottle.response.status = 401
		return "Forbidden"

	bbox = receipt_item["bbox"]

	if bbox["left"] is None:
		bottle.response.status = 404
		return "Not found"

	img = Image.open(f"receipts/{receipt_id}.png")
	img_crop = img.crop((bbox["left"], bbox["top"], bbox["right"], bbox["bottom"]))

	img_byte_arr = io.BytesIO()
	img_crop.save(img_byte_arr, format='PNG')
	img_byte_arr = img_byte_arr.getvalue()

	bottle.response.content_type = "image/png"
	return img_byte_arr


@bottle.post("/receipts/auto")
def add_receipt_auto():
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	img = Image.open(bottle.request.body)
	receipt_lines = get_receipt_lines(img)

	message = "\n".join(f"Line {i}: {line['text']}" for i, line in enumerate(receipt_lines))

	res = openai_client.chat.completions.create(
		model="gpt-4o-mini",
		messages=[{
			"role": "system",

			"content": [{
				"type": "text",
				"text": "You will be provided with the OCR extracted text from a receipt with line numbers. Parse the text and provide the requested JSON formatted output. OCR outputs are inherently messy, so extract only the relevant information. For the individual receipt items, do not use information from more than one line to construct an item entry."
			}]
		}, {
			"role": "user",
			"content": [{
				"type": "text",
				"text": message
			}]
		}],
		response_format={
			"type": "json_schema",
			"json_schema": {
				"name": "payment_receipt",
				"strict": False,
				"schema": {
					"type": "object",
					"properties": {
						"name": {
							"type": "string",
							"description": "Name of the merchant"
						},
						"date": {
							"type": "string",
							"description": "The date on the receipt, in the format MM-DD-YYYY"
						},
						"merchant_address": {
							"type": "string",
							"description": "Address of the merchant"
						},
						"merchant_website": {
							"type": "string",
							"description": "Merchant's domain name"
						},
						"items": {
							"type": "array",
							"description": "List of items included in the payment receipt.",
							"items": {
								"type": "object",
								"properties": {
									"description": {
										"type": "string",
										"description": "A brief description of the item. Remove any nonsensical or unnecessary words and normalize capitalization."
									},
									"cost": {
										"type": "number",
										"description": "Cost of the individual item."
									},
									"line_number": {
										"type": "number",
										"description": "The line number that you got this information from."
									}
								},
								"required": [
									"description",
									"cost",
									"line_number"
								],
								"additionalProperties": False
							}
						},
						"subtotal": {
							"type": "number",
							"description": "Total cost of items before any additional charges."
						},
						"total": {
							"type": "number",
							"description": "Total amount due including any additional charges or taxes."
						},
						"payment_method": {
							"type": "string",
							"description": "Description of the payment method (network and card number if credit card), modality name otherwise"
						}
					},
					"required": [
						"items",
						"subtotal",
						"total"
					],
					"additionalProperties": False
				}
			}
		}
	)
	try:
		receipt_json = json.loads(res.choices[0].message.content)
	except:
		return {
			"success": False
		}

	required_fields = ["items", "subtotal", "date", "total", "name"]
	for required_field in required_fields:
		if required_field not in receipt_json:
			print("missing field: ", required_field)
			return False

	receipt_id = save_receipt(user_id, receipt_json, receipt_lines)

	img.save(f"receipts/{receipt_id}.png", "PNG")

	return {
		"success": True,
		"receipt_id": receipt_id
	}

def get_receipt_lines(img):
	tesseract_data = pytesseract.image_to_data(img, output_type=pytesseract.Output.DICT, config="--psm 6")
	lines = []
	for i in range(len(tesseract_data["text"])):
		line_no = tesseract_data["line_num"][i]
		left = tesseract_data["left"][i]
		top = tesseract_data["top"][i]
		height = tesseract_data["height"][i]
		width = tesseract_data["width"][i]
		text = tesseract_data["text"][i]
		
		if text == "":
			text = " "

		if line_no + 1 > len(lines):
			lines.append({
				"text": text,
				"left": left,
				"top": top,
				"right": left + width,
				"bottom": top + height,
			})
		else:
			lines[line_no]["text"] += text + " "
			if left + width > lines[line_no]["right"]:
				lines[line_no]["right"] = left + width
			if top + height > lines[line_no]["bottom"]:
				lines[line_no]["bottom"] = top + height
	out_lines = []
	for line in lines:
		if "@" not in line["text"]:
			out_lines.append(line)
	return out_lines

def receipt_verify(data):
	items_subtotal = 0
	for item in data["items"]:
		if "cost" not in item:
			print("item has no cost")
			return False
		items_subtotal += item["cost"]

	if data["subtotal"] != round(items_subtotal, 2):
		print("items dont sum to subtotal")
		return False
	
	return True

def save_receipt(user_id, data, receipt_lines):
	tax = round(data["total"] - data["subtotal"], 2)
	receipt_id = db.create_receipt(user_id, data["date"], data["name"], data["merchant_address"] or "", data["merchant_website"] or "", data["payment_method"] or "", tax, receipt_verify(data))
	for item in data["items"]:
		receipt_line = receipt_lines[item["line_number"]]
		db.create_receipt_item(receipt_id, item["description"], round(item["cost"], 2), receipt_line["left"], receipt_line["top"], receipt_line["right"], receipt_line["bottom"])
	return receipt_id

if not os.path.exists("receipts"):
	os.makedirs("receipts")

db.init()
bottle.run(host='0.0.0.0', port=8080, debug=False)
