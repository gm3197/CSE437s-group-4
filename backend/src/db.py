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
		cur.execute("CREATE TABLE IF NOT EXISTS receipt_items (id SERIAL PRIMARY KEY, receipt_id INTEGER REFERENCES receipts, description VARCHAR(255), price DOUBLE PRECISION)")

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
		user_id = cur.fetchone()[0]
		if user_id is None:
			return None, False
		return user_id, True

def create_receipt(user_id, date, merchant, merchant_address, merchant_domain, payment_method, tax, clean):
	with connect() as conn:
		cur = conn.cursor()
		cur.execute(
			"INSERT INTO receipts (owner_id, date, merchant, merchant_address, merchant_domain, payment_method, tax, clean) VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING id", 
			(user_id, date, merchant, merchant_address, merchant_domain, payment_method, tax, clean)
		)
		return cur.fetchone()[0]

def create_receipt_item(receipt_id, description, price):
	with connect() as conn:
		cur = conn.cursor()
		cur.execute(
			"INSERT INTO receipt_items (receipt_id, description, price) VALUES (%s, %s, %s) RETURNING id", 
			(receipt_id, description, price)
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
				"total": row[3],
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
			"SELECT id, description, price FROM receipt_items WHERE receipt_id = %s",
			(receipt_id,)
		)
		items = cur.fetchall()

		out_items = []
		for item in items:
			out_items.append({
				"id": item[0],
				"description": item[1],
				"price": item[2]
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
