# ControllerServer — scripts/autoload/controller_server.gd
# Role: Serves controller HTML/CSS/JS via HTTP, detects local IP
# Owns: TCP server lifecycle for controller file serving
# Listens on: 0.0.0.0 on port 8000
#
# Usage: Starts automatically with game
extends Node

var _tcp_server: TCPServer = null
var _host_ip: String = ""
var _port: int = GameConfig.CONTROLLER_HTTP_PORT
var _is_listening: bool = false
var _pending_clients: Array[Dictionary] = []

const HOST_IP_ENV_KEY = "NUTCASE_HOST_IP"
const HOST_IP_SETTING_KEY = "nutcase/network/preferred_host_ip"
const CONTROLLER_DIR_PATH = "res://web-controller" # Configurable: can rename folder and update this path

func _ready() -> void:
	_host_ip = _get_local_ip()
	start_server()

func _process(_delta: float) -> void:
	if _is_listening and _tcp_server:
		_accept_connections()
		_service_pending_clients()

func start_server() -> void:
	if _is_listening:
		return
	
	var started = false
	for candidate_port in range(_port, _port + 11):
		var candidate = TCPServer.new()
		var error = candidate.listen(candidate_port, "0.0.0.0")
		if error == OK:
			_tcp_server = candidate
			_port = candidate_port
			started = true
			break

	if not started:
		push_error("Failed to start controller server: no free port in range %d-%d" % [_port, _port + 10])
		return
	
	_is_listening = true
	_pending_clients.clear()
	print("✓ Controller server started on http://localhost:%d" % _port)
	if _host_ip:
		print("✓ Available at: http://%s:%d" % [_host_ip, _port])

func stop_server() -> void:
	if _tcp_server:
		_tcp_server.close()
		_is_listening = false
		_pending_clients.clear()
		print("✓ Controller server stopped")

func get_host_ip() -> String:
	return _host_ip

func get_controller_url() -> String:
	if not _host_ip:
		return "http://localhost:%d" % _port
	return "http://%s:%d" % [_host_ip, _port]

func _accept_connections() -> void:
	while _tcp_server.is_connection_available():
		var connection = _tcp_server.take_connection()
		if connection:
			_pending_clients.append({
				"peer": connection,
				"accepted_ms": Time.get_ticks_msec()
			})

func _service_pending_clients() -> void:
	var now_ms = Time.get_ticks_msec()
	for i in range(_pending_clients.size() - 1, -1, -1):
		var entry = _pending_clients[i]
		var peer: StreamPeerTCP = entry["peer"]
		var accepted_ms: int = entry["accepted_ms"]

		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_pending_clients.remove_at(i)
			continue

		if peer.get_available_bytes() > 0:
			_process_request(peer)
			peer.disconnect_from_host()
			_pending_clients.remove_at(i)
			continue

		# Avoid hanging dead connections forever.
		if now_ms - accepted_ms > 1500:
			peer.disconnect_from_host()
			_pending_clients.remove_at(i)

func _process_request(client: StreamPeerTCP) -> void:
	# Read HTTP request
	var request_text = ""
	while client.get_available_bytes() > 0:
		request_text += client.get_utf8_string(client.get_available_bytes())
	
	if request_text.is_empty():
		return
	
	# Parse request line
	var lines = request_text.split("\r\n")
	var request_parts = lines[0].split(" ")
	
	if request_parts.size() < 2:
		return
	
	var path = request_parts[1]
	var query_index = path.find("?")
	if query_index >= 0:
		path = path.substr(0, query_index)
	
	# Normalize path
	if path == "/" or path == "":
		path = "/index.html"
	
	# Security: prevent directory traversal
	if ".." in path:
		_send_text_response(client, 403, "Forbidden", "text/plain")
		return
	
	# Load file from controller directory
	var file_path = CONTROLLER_DIR_PATH + path
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		var fallback = _try_load_image_resource(file_path)
		if not fallback.is_empty():
			_send_binary_response(client, 200, fallback["bytes"], fallback["mime"])
			return

		var font_fallback = _try_load_font_resource(file_path, path)
		if not font_fallback.is_empty():
			_send_binary_response(client, 200, font_fallback["bytes"], font_fallback["mime"])
			return

		# Debug: log all font requests
		if path.ends_with(".otf") or path.ends_with(".ttf") or path.ends_with(".woff") or path.ends_with(".woff2"):
			push_warning("ControllerServer: FONT NOT FOUND - HTTP path '%s' (resolved: %s)" % [path, file_path])
		else:
			push_warning("ControllerServer: file not found for HTTP path '%s' (resolved: %s)" % [path, file_path])
		_send_text_response(client, 404, "Not Found", "text/plain")
		return
	
	var content = file.get_buffer(file.get_length())
	var mime_type = _get_mime_type(path)
	
	# Debug: log font files being served
	if path.ends_with(".otf") or path.ends_with(".ttf") or path.ends_with(".woff") or path.ends_with(".woff2"):
		print("✓ ControllerServer: serving font %s (%d bytes) with MIME type: %s" % [path, content.size(), mime_type])
	
	_send_binary_response(client, 200, content, mime_type)

func _send_text_response(client: StreamPeerTCP, status_code: int, body: String, content_type: String) -> void:
	_send_binary_response(client, status_code, body.to_utf8_buffer(), content_type)

func _send_binary_response(client: StreamPeerTCP, status_code: int, body: PackedByteArray, content_type: String) -> void:
	var status_text = {
		200: "OK",
		404: "Not Found",
		403: "Forbidden"
	}.get(status_code, "Error")
	
	var headers = "HTTP/1.1 %d %s\r\n" % [status_code, status_text]
	headers += "Content-Type: %s\r\n" % content_type
	headers += "Content-Length: %d\r\n" % body.size()
	headers += "Access-Control-Allow-Origin: *\r\n"
	headers += "Cache-Control: no-cache\r\n"
	headers += "Connection: close\r\n"
	headers += "\r\n"

	client.put_data(headers.to_utf8_buffer())
	if body.size() > 0:
		client.put_data(body)

func _get_mime_type(path: String) -> String:
	var types = {
		".html": "text/html; charset=utf-8",
		".css": "text/css",
		".js": "application/javascript",
		".json": "application/json",
		".png": "image/png",
		".jpg": "image/jpeg",
		".jpeg": "image/jpeg",
		".svg": "image/svg+xml",
		".otf": "application/x-font-opentype",
		".ttf": "application/x-font-truetype",
		".woff": "application/font-woff",
		".woff2": "font/woff2",
		".txt": "text/plain"
	}
	
	for ext in types.keys():
		if path.ends_with(ext):
			return types[ext]
	
	return "application/octet-stream"

func _try_load_image_resource(file_path: String) -> Dictionary:
	# In exported projects, imported textures may exist as resources even when
	# the original source file is not directly readable via FileAccess.
	var ext = file_path.get_extension().to_lower()
	if ext != "png" and ext != "jpg" and ext != "jpeg":
		return {}

	var texture = load(file_path)
	if texture == null or not (texture is Texture2D):
		return {}

	var image: Image = (texture as Texture2D).get_image()
	if image == null:
		return {}

	# Encode to PNG for browser compatibility and deterministic bytes.
	var bytes: PackedByteArray = image.save_png_to_buffer()
	if bytes.is_empty():
		return {}

	return {
		"bytes": bytes,
		"mime": "image/png"
	}

func _try_load_font_resource(file_path: String, request_path: String) -> Dictionary:
	# In exported projects, .ttf/.otf can be imported as FontFile resources.
	# If the raw file is missing, try loading the imported resource bytes.
	var ext = file_path.get_extension().to_lower()
	if ext != "ttf" and ext != "otf":
		return {}

	var font_resource = load(file_path)
	if font_resource == null:
		var file_name = file_path.get_file()
		if file_path.contains("/webfonts/"):
			font_resource = load(CONTROLLER_DIR_PATH + "/fonts/" + file_name)
		elif file_path.contains("/fonts/"):
			font_resource = load(CONTROLLER_DIR_PATH + "/webfonts/" + file_name)
	if font_resource == null:
		return {}

	if not font_resource.has_method("get_data"):
		return {}

	var bytes_candidate = font_resource.call("get_data")
	if not (bytes_candidate is PackedByteArray):
		return {}

	var bytes: PackedByteArray = bytes_candidate
	if bytes.is_empty():
		return {}

	var mime = _get_mime_type(request_path)
	print("✓ ControllerServer: serving imported font resource %s (%d bytes) as %s" % [request_path, bytes.size(), mime])
	return {
		"bytes": bytes,
		"mime": mime
	}

func _get_local_ip() -> String:
	var explicit_ip = _get_explicit_host_ip_override()
	if explicit_ip != "":
		return explicit_ip

	var addresses = IP.get_local_addresses()
	var ipv4_candidates: Array[String] = []

	# Keep only non-loopback IPv4 candidates.
	for addr in addresses:
		if _is_valid_ipv4_candidate(addr):
			ipv4_candidates.append(addr)

	if ipv4_candidates.is_empty():
		return ""

	# Prefer common Wi-Fi/home LAN ranges first, then fall back.
	for addr in ipv4_candidates:
		if addr.begins_with("192.168."):
			return addr
	for addr in ipv4_candidates:
		if addr.begins_with("10."):
			return addr
	for addr in ipv4_candidates:
		if addr.begins_with("172."):
			return addr

	return ipv4_candidates[0]

func _get_explicit_host_ip_override() -> String:
	# Priority 1: environment variable for quick local dev override.
	var env_ip = OS.get_environment(HOST_IP_ENV_KEY).strip_edges()
	if _is_valid_ipv4_candidate(env_ip):
		print("ControllerServer: using host IP from env %s: %s" % [HOST_IP_ENV_KEY, env_ip])
		return env_ip

	# Priority 2: optional project setting for stable team/dev-machine config.
	if ProjectSettings.has_setting(HOST_IP_SETTING_KEY):
		var setting_ip = str(ProjectSettings.get_setting(HOST_IP_SETTING_KEY, "")).strip_edges()
		if _is_valid_ipv4_candidate(setting_ip):
			print("ControllerServer: using host IP from project setting %s: %s" % [HOST_IP_SETTING_KEY, setting_ip])
			return setting_ip

	return ""

func _is_valid_ipv4_candidate(addr: String) -> bool:
	if addr == "":
		return false
	if ":" in addr:
		return false
	if addr.begins_with("127."):
		return false
	if addr == "0.0.0.0":
		return false
	return true
