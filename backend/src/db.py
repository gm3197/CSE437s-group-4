import psycopg
import random
import string

def connect():
	try:
		conn = psycopg.connect("dbname=cse437 user=cse437 password=cse437test123")
	except Exception as e:
		raise e
	return conn

def init():
	with connect() as conn:
		cur = conn.cursor()
		cur.execute("CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, email VARCHAR(255) UNIQUE, full_name VARCHAR(255), session_token VARCHAR(255))")
		cur.execute("CREATE TABLE IF NOT EXISTS receipts (id SERIAL PRIMARY KEY, owner_id integer REFERENCES users, date DATE, merchant VARCHAR(255), merchant_address TEXT, merchant_domain VARCHAR(255), payment_method VARCHAR(255), tax DOUBLE PRECISION, clean BOOLEAN)")
		cur.execute("CREATE TABLE IF NOT EXISTS receipt_items (id SERIAL PRIMARY KEY, receipt_id INTEGER REFERENCES receipts, description VARCHAR(255), price DOUBLE PRECISION, bbox_left INTEGER, bbox_top INTEGER, bbox_right INTEGER, bbox_bottom INTEGER)")

def login_user(email, full_name):
	session_token = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(32))

	with connect() as conn:
		cur = conn.cursor()
		cur.execute(
			"INSERT INTO users (email, full_name, session_token) VALUES (%s, %s, %s) ON CONFLICT (email) DO UPDATE SET session_token = %s", 
			(email, full_name, session_token, session_token)
		)

	return session_token

def check_session_token(token):
	with connect() as conn:
		cur = conn.cursor()
		cur.execute(
			"SELECT id FROM users WHERE session_token = %s", 
			(token,)
		)
		user = cur.fetchone()
		if user is None:
			return None, False
		return user[0], True

def create_receipt(user_id, date, merchant, merchant_address, merchant_domain, payment_method, tax, clean):
	with connect() as conn:
		cur = conn.cursor()
		cur.execute(
			"INSERT INTO receipts (owner_id, date, merchant, merchant_address, merchant_domain, payment_method, tax, clean) VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING id", 
			(user_id, date, merchant, merchant_address, merchant_domain, payment_method, tax, clean)
		)
		return cur.fetchone()[0]

def create_receipt_item(receipt_id, description, price, bbox_left, bbox_top, bbox_right, bbox_bottom):
	with connect() as conn:
		cur = conn.cursor()
		cur.execute(
			"INSERT INTO receipt_items (receipt_id, description, price, bbox_left, bbox_top, bbox_right, bbox_bottom) VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id", 
			(receipt_id, description, price, bbox_left, bbox_top, bbox_right, bbox_bottom)
		)
		return cur.fetchone()[0]

def list_receipts(user_id):
	with connect() as conn:
		cur = conn.cursor()
		cur.execute(
			"SELECT id, date, merchant, (SELECT SUM(price) FROM receipt_items WHERE receipt_items.receipt_id = receipts.id) + tax AS total, clean FROM receipts WHERE owner_id = %s ORDER BY date DESC",
			(user_id,)
		)
		rows = cur.fetchall()
		receipts = []
		for row in rows:
			receipts.append({
				"id": row[0],
				"date": row[1].__str__(),
				"merchant": row[2],
				"total": round(row[3], 2) if row[3] is not None else 0.00,
				"clean": row[4]
			})

		return receipts

def get_receipt(receipt_id):
	with connect() as conn:
		cur = conn.cursor()
		cur.execute(
			"SELECT id, owner_id, date, merchant, merchant_address, merchant_domain, payment_method, tax, clean FROM receipts WHERE id = %s",
			(receipt_id,)
		)
		receipt = cur.fetchone()

		if receipt is None:
			return None

		cur.execute(
			"SELECT id, description, price, bbox_left FROM receipt_items WHERE receipt_id = %s",
			(receipt_id,)
		)
		items = cur.fetchall()

		out_items = []
		for item in items:
			out_items.append({
				"id": item[0],
				"description": item[1],
				"price": round(item[2], 2),
				"auto": True if item[3] is not None else False,
			})

		return {
			"id": receipt[0],
			"owner_id": receipt[1],
			"clean": receipt[8],
			"date": receipt[2].__str__(),
			"merchant": {
				"name": receipt[3],
				"address": receipt[4],
				"domain": receipt[5]
			},
			"payment_method": receipt[6],
			"items": out_items,
			"tax": receipt[7]
		}

def get_receipt_item(receipt_id, item_id):
	with connect() as conn:
		cur = conn.cursor()

		cur.execute("SELECT owner_id FROM receipts WHERE id = %s", (receipt_id,))
		receipt = cur.fetchone()
		if receipt is None:
			return None
		owner_id = receipt[0]

		cur.execute("SELECT description, price, bbox_left, bbox_top, bbox_right, bbox_bottom FROM receipt_items WHERE id = %s AND receipt_id = %s", (item_id, receipt_id))
		row = cur.fetchone()
		if row is None:
			return None

		return {
			"id": item_id,
			"receipt_id": receipt_id,
			"owner_id": owner_id,
			"description": row[0],
			"price": row[1],
			"bbox": {
				"left": row[2],
				"top": row[3],
				"right": row[4],
				"bottom": row[5]
			}
		}

def insert_receipt_item(receipt_id, price, description):
	with connect() as conn:
		cur = conn.cursor()
		cur.execute("INSERT INTO receipt_items (receipt_id, description, price) VALUES (%s, %s, %s) RETURNING id", (receipt_id, description, price))
		return cur.fetchone()[0]

def update_receipt_item(item_id, price, description):
	with connect() as conn:
		cur = conn.cursor()
		cur.execute("UPDATE receipt_items SET price = %s, description = %s WHERE id = %s", (price, description, item_id))

def delete_receipt_item(receipt_id, item_id):
	with connect() as conn:
		cur = conn.cursor()
		cur.execute("DELETE FROM receipt_items WHERE id = %s AND receipt_id = %s", (item_id, receipt_id))
