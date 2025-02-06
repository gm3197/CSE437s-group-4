import bottle

@bottle.get("/")
def hello_world():
		return "hello world"

bottle.run(host='0.0.0.0', port=8080, debug=False)
