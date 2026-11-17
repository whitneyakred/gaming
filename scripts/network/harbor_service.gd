extends Node
## Shared browser/desktop harbor. Only the public service URL is shipped.
signal changed
var crews: Dictionary = {}
var busy := false
var operation := ""
var request: HTTPRequest
var peer: HarborPeer
var closing_peers: Array[Dictionary] = []
var endpoint := ""
var generation := 0
var current_room: String = ""
var _next_browse_at := 0
var _browse_failures := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	endpoint = str(ProjectSettings.get_setting("network/harbor_url", "")).trim_suffix("/")
	if OS.has_feature("web"):
		endpoint = str(JavaScriptBridge.eval("window.location.origin"))
		# pagehide covers Back, reload and closing a tab, without treating tab switches as exits.
		JavaScriptBridge.eval("""
		window.holyShipLeave = () => {
		  const departure = window.holyShipDeparture;
		  if (!departure) return;
		  window.holyShipDeparture = null;
		  const body = JSON.stringify({ticket: departure.ticket});
		  const queued = navigator.sendBeacon(departure.url, new Blob([body], {type: 'application/json'}));
		  if (!queued) fetch(departure.url, {method:'POST', body, headers:{'Content-Type':'application/json'}, keepalive:true}).catch(() => {});
		};
		window.addEventListener('pagehide', window.holyShipLeave);
		""")
	# Local test override is deliberately unavailable in normal browser builds.
	elif "--settings-test" in OS.get_cmdline_user_args():
		endpoint = ""
		var args := OS.get_cmdline_user_args()
		var i := args.find("--harbor-url")
		if i >= 0 and i + 1 < args.size(): endpoint = args[i + 1].trim_suffix("/")
		if "--online-check" in args: _run_check.call_deferred()

func _run_check() -> void:
	get_tree().root.add_child(load("res://scripts/network/online_check.gd").new())

func _process(_delta: float) -> void:
	for item in closing_peers.duplicate():
		var old: HarborPeer = item.peer
		old.socket.poll()
		if old.socket.get_ready_state() == WebSocketPeer.STATE_CLOSED or Time.get_ticks_msec() > int(item.until): closing_peers.erase(item)

func status(text: String) -> void:
	NetworkSession.set_status(text)
	changed.emit()

func available() -> bool:
	if endpoint.is_empty():
		status("The online harbor is not configured in this build yet.")
		return false
	return true

func call_api(path: String, data: Dictionary = {}) -> Dictionary:
	var http := HTTPRequest.new()
	# Browsers already decode HTTP content encoding; do not decompress twice.
	http.accept_gzip = not OS.has_feature("web")
	http.timeout = 15
	http.body_size_limit = 131072
	add_child(http)
	request = http
	var headers := PackedStringArray(["Content-Type: application/json"])
	var result := http.request(endpoint + path, headers, HTTPClient.METHOD_GET if data.is_empty() else HTTPClient.METHOD_POST, "" if data.is_empty() else JSON.stringify(data))
	if result != OK:
		http.queue_free()
		return {"error": "Could not reach the harbor. Check your internet connection."}
	var response: Array = await http.request_completed
	if request == http: request = null
	http.queue_free()
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS: return {"error": "The harbor did not respond. Please try again."}
	var decoded: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	if not decoded is Dictionary: return {"error": "The harbor is temporarily unavailable. Please try again."}
	return decoded

func browse() -> void:
	if busy or NetworkSession.online or not available(): return
	if Time.get_ticks_msec() < _next_browse_at: return
	_next_browse_at = Time.get_ticks_msec() + 5000
	busy = true
	operation = "browse"
	generation += 1
	var current := generation
	status("Looking for crews…")
	var result := await call_api("/api/crews")
	if current != generation: return
	busy = false
	operation = ""
	if result.has("error"):
		_browse_failures = mini(_browse_failures + 1, 4)
		_next_browse_at = Time.get_ticks_msec() + mini(60000, 5000 * (1 << _browse_failures))
		status(str(result.error))
		return
	_browse_failures = 0
	crews.clear()
	for crew: Dictionary in result.get("crews", []):
		if int(crew.get("count", 0)) > 0: crews[str(crew.id)] = crew
	status("Choose a voyage to join." if not crews.is_empty() else "No ships at sea yet. Be the first to host a voyage.")

func cancel_browse() -> void:
	# Do not free a pending coroutine's HTTPRequest. Let it finish quietly.
	if operation == "browse":
		generation += 1
		busy = false
		operation = ""

func host(title: String, password: String) -> void:
	if busy or NetworkSession.online or not available(): return
	busy = true
	operation = "host"
	status("Launching your voyage…")
	var result := await call_api("/api/crews", {"title": title, "password": password, "token": NetworkSession.local_token, "protocol": NetworkSession.PROTOCOL})
	await connect_result(result, true, title, password)

func join_crew(id: String, password: String) -> void:
	if busy or NetworkSession.online or not available(): return
	busy = true
	operation = "join"
	status("Joining the voyage…")
	var result := await call_api("/api/crews/" + id.uri_encode() + "/join", {"password": password, "token": NetworkSession.local_token, "protocol": NetworkSession.PROTOCOL})
	if result.has("error") and "ended" in str(result.error):
		crews.erase(id)
		changed.emit()
	await connect_result(result, false, "", password)

func connect_result(result: Dictionary, hosting: bool, title: String, password: String) -> void:
	if result.has("error"):
		busy = false
		operation = ""
		status(str(result.error))
		return
	current_room = str(result.id)
	peer = HarborPeer.new()
	if OS.has_feature("web"):
		var departure := {"url": endpoint + "/api/crews/" + str(result.id) + "/leave", "ticket": result.ticket}
		JavaScriptBridge.eval("window.holyShipDeparture = " + JSON.stringify(departure) + ";")
	var url := endpoint.replace("https://", "wss://").replace("http://", "ws://") + "/api/socket/" + str(result.id) + "?ticket=" + str(result.ticket).uri_encode()
	var code := peer.connect_url(url)
	if code == OK:
		while peer.state == MultiplayerPeer.CONNECTION_CONNECTING:
			peer.advance()
			await get_tree().process_frame
	busy = false
	operation = ""
	if code != OK or peer.state != MultiplayerPeer.CONNECTION_CONNECTED:
		status("Could not connect to this voyage. Refresh the list and try again.")
		leave()
		return
	if hosting:
		NetworkSession.crew_title = title
		NetworkSession.start_host_peer(peer, password, true, true)
	else:
		NetworkSession.start_client_peer(peer, password, true)
	changed.emit()

func leave() -> void:
	crews.erase(current_room)
	current_room = ""
	changed.emit()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.holyShipLeave) window.holyShipLeave();")
	if peer != null:
		peer.close()
		closing_peers.append({"peer": peer, "until": Time.get_ticks_msec() + 3000})
		peer = null
