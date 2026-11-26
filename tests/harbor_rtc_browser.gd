extends Node
## Copied to an isolated tiny Web test project by run-webrtc-browser.mjs.
var peer := HarborPeer.new()
var count := 0
var snapshots := 0
var reliable := 0
var elapsed := 0.0
var clock := 0.0
var stopped := false
func _ready() -> void:
	peer.rtc.enabled = not bool(JavaScriptBridge.eval("window.rtcDisabled || false"))
	peer.connect_url(str(JavaScriptBridge.eval("window.rtcURL")))
func _process(delta: float) -> void:
	elapsed += delta
	peer.advance()
	clock += delta
	if not stopped and bool(JavaScriptBridge.eval("window.rtcStop || false")):
		stopped = true
		for id: int in peer.rtc.links.keys(): peer.rtc.stop(id, "test interruption")
	if clock >= 0.08 and peer.state == MultiplayerPeer.CONNECTION_CONNECTED:
		clock = 0
		count += 1
		if peer.own_id == 1: peer.send_world_snapshot(var_to_bytes(count))
		peer._send_packet(var_to_bytes(count), 0 if peer.own_id == 1 else 1, 0, MultiplayerPeer.TRANSFER_MODE_RELIABLE)
	if not peer.take_world_snapshot().is_empty(): snapshots += 1
	while peer._get_available_packet_count() > 0:
		peer._get_packet_script()
		reliable += 1
	var data := {"id": peer.own_id, "state": peer.state, "snapshots": snapshots, "reliable": reliable, "seconds": elapsed, "rtc": peer.rtc.diagnostics()}
	JavaScriptBridge.eval("window.rtcResult = " + JSON.stringify(data))
