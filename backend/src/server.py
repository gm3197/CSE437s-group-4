import db

import bottle
from google.oauth2 import id_token as google_auth
from google.auth.transport import requests as google_requests

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

db.init()
bottle.run(host='0.0.0.0', port=8080, debug=False)
