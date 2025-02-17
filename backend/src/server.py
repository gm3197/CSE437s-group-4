import db
import bottle
from google.oauth2 import id_token as google_auth
from google.auth.transport import requests as google_requests
from PIL import Image
import pytesseract
from openai import OpenAI
import json

openai_client = OpenAI()

@bottle.post("/auth/google/token")
def	google_auth_token():
	data = bottle.request.json
	if data is None or "idToken" not in data:
		bottle.response.status = 400
		return "Bad request"
	token_str = data["idToken"]
	token_data = google_auth.verify_oauth2_token(token_str, google_requests.Request(), "650383131525-anbr9ft0hfl03jbhbl21sokpgchc12tg.apps.googleusercontent.com")

	if not token_data["email_verified"]:
		bottle.response.status = 403
		return "Unauthorized"

	session_token = db.login_user(token_data["email"], token_data["name"])
	return {
		"session": session_token
	}

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


@bottle.post("/receipts/auto")
def add_receipt_auto():
	user_id, ok = db.check_session_token(bottle.request.get_header("Authorization"))
	if not ok:
		bottle.response.status = 403
		return "Unauthorized"

	img = Image.open(bottle.request.body)
	receipt_text = pytesseract.image_to_string(img, lang="eng", config="--psm 6")

	receipt_text = clean_receipt_text(receipt_text)

	res = openai_client.chat.completions.create(
		model="gpt-4o-mini",
		messages=[{
			"role": "system",
			"content": [{
				"type": "text",
				"text": "You will be provided with the OCR extracted text from a receipt. Parse the text and provide the requested JSON formatted output. OCR outputs are inherently messy, so extract only the relevant information."
			}]
		}, {
			"role": "user",
			"content": [{
				"type": "text",
				"text": receipt_text
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
									}
								},
								"required": [
									"description",
									"cost"
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

	receipt_id = save_receipt(user_id, receipt_json)

	return {
		"success": True,
		"receipt_id": receipt_id
	}

def clean_receipt_text(text):
	lines = text.split("\n")
	out = ""
	for line in lines:
		if "@" not in line:
			out += line + "\n"
	return out

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

def save_receipt(user_id, data):
	tax = round(data["total"] - data["subtotal"], 2)
	receipt_id = db.create_receipt(user_id, data["date"], data["name"], data["merchant_address"] or "", data["merchant_website"] or "", data["payment_method"] or "", tax, receipt_verify(data))
	for item in data["items"]:
		db.create_receipt_item(receipt_id, item["description"], round(item["cost"], 2))
	return receipt_id

db.init()
bottle.run(host='0.0.0.0', port=8080, debug=False)
