import psycopg
import random

def connect():
	try:
		conn = psycopg.connect("dbname=cse437 user=cse437 password=cse437test123")
	except Exception as e:
		raise e
	return conn

def init():
	with connect() as conn:
		cur = conn.cursor()
		cur.execute("CREATE TABLE IF NOT EXISTS users (email VARCHAR(255), full_name VARCHAR(255), session_token VARCHAR(255), CONSTRAINT email_unique UNIQUE(email))")

def login_user(email, full_name):
	session_token = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits) for _ in range(32))

	with connect() as conn:
		cur = conn.cursor()
		cur.execute(
				"INSERT INTO users (email, full_name, session_token) VALUES (%s, %s, %s) ON CONFLICT (email) DO UPDATE SET session_token = %s", 
				(email, full_name, session_token, session_token)
		)

	return session_token
