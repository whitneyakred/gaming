extends Node
## LAN discovery only. Game traffic still uses the authoritative ENet session.
signal changed
const DISCOVERY_PORT := 24566
const QUERY := "holy-ship-discover-1"
var crews: Dictionary = {}
var browsing: bool = false
var listener := PacketPeerUDP.new()
var client := PacketPeerUDP.new()
var clock: float = 0.0
var notice: String = ""

func browse() -> void:
	if OS.has_feature("web"):
		notice = "Nearby crews require the desktop game."
		return
	browsing = true
	if not client.is_bound():
		if client.bind(0) != OK:
			notice = "Nearby search is unavailable. Try Direct connect."
			return
		client.set_broadcast_enabled(true)
	query()

func query() -> void:
	if not client.is_bound(): return
	for address in ["255.255.255.255", "127.0.0.1"]:
		client.set_dest_address(address, DISCOVERY_PORT)
		client.put_packet(QUERY.to_utf8_buffer())

func _process(delta: float) -> void:
	if OS.has_feature("web"): return
	var hosting: bool = NetworkSession.online and not NetworkSession.internet and NetworkSession.local_id == 1 and NetworkSession.world_ready
	if hosting and not listener.is_bound():
		if listener.bind(DISCOVERY_PORT) != OK:
			return # Only one advertised host per device; direct connections still work.
	elif not hosting and listener.is_bound():
		listener.close()
	for i in mini(listener.get_available_packet_count(), 32):
		var bytes := listener.get_packet()
		var address := listener.get_packet_ip()
		var reply_port := listener.get_packet_port()
		if bytes.size() > 64 or bytes.get_string_from_utf8() != QUERY: continue
		listener.set_dest_address(address, reply_port)
		listener.put_packet(JSON.stringify({"protocol": NetworkSession.PROTOCOL,
			"title": NetworkSession.crew_title.left(32), "port": NetworkSession.port,
			"count": NetworkSession.identities.size(), "locked": not NetworkSession.password.is_empty(),
			"id": NetworkSession.local_token.sha256_text().left(16)}).to_utf8_buffer())
	for i in mini(client.get_available_packet_count(), 32):
		var bytes := client.get_packet()
		var address := client.get_packet_ip()
		if bytes.size() > 1024: continue
		var data: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		if not data is Dictionary or data.get("protocol") != NetworkSession.PROTOCOL: continue
		if not data.get("port") is float or not data.get("count") is float: continue
		if not data.get("title") is String or not data.get("id") is String: continue
		if int(data.port) < 1024 or int(data.port) > 65535 or data.count < 0 or data.count > 4: continue
		data.address = address
		data.seen = Time.get_ticks_msec()
		var key := str(data.id).left(32)
		if crews.size() >= 128 and not crews.has(key): continue
		var previous: Dictionary = crews.get(key, {})
		var updated: bool = previous.get("title") != data.title or previous.get("count") != data.count or previous.get("locked") != data.get("locked") or previous.get("port") != data.port
		crews[key] = data
		if updated: changed.emit()
	clock += delta
	if clock < 2.0: return
	clock = 0
	for key in crews.keys():
		if Time.get_ticks_msec() - int(crews[key].seen) > 6500:
			crews.erase(key)
			changed.emit()
	if browsing and not NetworkSession.online: query()
