extends Node
## EOSG 2.3.1 native adapter. No Epic account UI or voice capture is required.
var initialized := false
var platform := false
var logged_in := false
var lobby_id := ""
var is_host :=  false
var listings: Dictionary = {}
var closing := false
var _refreshing := false
var _leaving := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	IEOS.connect_interface_auth_expiration.connect(func(_data): refresh_login())
	IEOS.lobby_interface_lobby_member_status_received_callback.connect(_member_status)

func _process(_delta: float) -> void:
	if platform: IEOS.tick()

func request(signal_name: String, action: Callable, seconds: float = 20.0) -> Dictionary:
	var answer: Array = []
	var callback := func(data: Dictionary): answer.append(data)
	IEOS.connect(signal_name, callback)
	action.call()
	action = Callable()
	var end := Time.get_ticks_msec() + int(seconds * 1000)
	while answer.is_empty() and Time.get_ticks_msec() < end and not closing:
		await get_tree().process_frame
	if IEOS.is_connected(signal_name, callback): IEOS.disconnect(signal_name, callback)
	return answer[0] if not answer.is_empty() else {"result_code": EOS.Result.TimedOut}

func fail(step: String, result: Dictionary = {}) -> bool:
	EOSGRuntime.set_status(step + (" (" + EOS.result_str(result) + ")" if not result.is_empty() else ""))
	return false

func connect_online() -> bool:
	while _leaving: await get_tree().process_frame
	if closing: return false
	if logged_in: return true
	EOSGRuntime.set_status("Connecting to the online harbor…")
	if not platform:
		var config := ConfigFile.new()
		var path := "res://.local/eos.cfg" if OS.has_feature("editor") else "res://online/eos.cfg"
		if config.load(path) != OK: return fail("Online configuration is missing from this build.")
		for key in ["product_id", "sandbox_id", "deployment_id", "client_id", "client_secret"]:
			if str(config.get_value("eos", key, "")).is_empty(): return fail("Online configuration is incomplete.")
		var init := EOS.Platform.InitializeOptions.new()
		init.product_name = "Holy Ship"
		init.product_version = NetworkSession.PROTOCOL
		var result := EOS.Platform.PlatformInterface.initialize(init)
		if result != EOS.Result.Success: return fail("Online SDK could not start.")
		initialized = true
		var opts := EOS.Platform.CreateOptions.new()
		for key in ["product_id", "sandbox_id", "deployment_id", "client_id", "client_secret"]:
			opts.set(key, str(config.get_value("eos", key, "")))
		opts.flags = EOS.Platform.PlatformFlags.DisableOverlay
		opts.cache_directory = ProjectSettings.globalize_path("user://eos-cache/" + NetworkSession.local_token.sha256_text().left(12))
		DirAccess.make_dir_recursive_absolute(opts.cache_directory)
		opts.tick_budget_in_milliseconds = 3
		opts.task_network_timeout_seconds = 15.0
		platform = EOS.Platform.PlatformInterface.create(opts)
		if not platform: return fail("Online platform could not start.")
		# Always relay: the test exercises the route used across restrictive home networks.
		EOS.P2P.P2PInterface.set_relay_control(EOS.P2P.RelayControl.ForceRelays)
	var device := EOS.Connect.CreateDeviceIdOptions.new()
	device.device_model = "HolyShipDesktop"
	var created := await request("connect_interface_create_device_id_callback", func(): EOS.Connect.ConnectInterface.create_device_id(device))
	if not EOS.is_success(created) and created.result_code != EOS.Result.DuplicateNotAllowed:
		return fail("Could not prepare your online sailor.", created)
	return await login()

func login() -> bool:
	var opts := EOS.Connect.LoginOptions.new()
	opts.credentials = EOS.Connect.Credentials.new()
	opts.credentials.type = EOS.ExternalCredentialType.DeviceidAccessToken
	opts.user_login_info = EOS.Connect.UserLoginInfo.new()
	opts.user_login_info.display_name = NetworkSession.local_name
	var result := await request("connect_interface_login_callback", func(): EOS.Connect.ConnectInterface.login(opts))
	if result.result_code == EOS.Result.InvalidUser:
		var create := EOS.Connect.CreateUserOptions.new()
		create.continuance_token = result.continuance_token
		result = await request("connect_interface_create_user_callback", func(): EOS.Connect.ConnectInterface.create_user(create))
	if not EOS.is_success(result): return fail("Online sign-in failed. Try again shortly.", result)
	EOSGRuntime.local_product_user_id = result.local_user_id
	if "--settings-test" in OS.get_cmdline_user_args(): print("EOS_DIAG identity=", str(result.local_user_id).sha256_text().left(8))
	logged_in = true
	return true

func refresh_login() -> void:
	if _refreshing or closing: return
	_refreshing = true
	if not await login(): NetworkSession.leave("Online sign-in expired. Please reconnect.")
	_refreshing = false

func browse() -> void:
	if not await connect_online(): return
	EOSGRuntime.set_status("Looking for crews…")
	var opts := EOS.Lobby.CreateLobbySearchOptions.new()
	opts.max_results = 50
	var result := EOS.Lobby.LobbyInterface.create_lobby_search(opts)
	if not EOS.is_success(result):
		fail("Crew search is unavailable.", result)
		return
	var search: EOSGLobbySearch = result.lobby_search
	search.set_parameter(EOS.Lobby.SEARCH_BUCKET_ID, NetworkSession.PROTOCOL, EOS.ComparisonOp.Equal)
	result = await request("lobby_search_find_callback", Callable(search, "find").bind(EOSGRuntime.local_product_user_id))
	if not EOS.is_success(result):
		fail("Could not find crews. Try refreshing.", result)
		return
	listings.clear()
	EOSGRuntime.crews.clear()
	if "--settings-test" in OS.get_cmdline_user_args(): print("EOS_DIAG search_count=", search.get_search_result_count())
	for i in search.get_search_result_count():
		var copied: Dictionary = search.copy_search_result_by_index(i)
		if not EOS.is_success(copied): continue
		var details: EOSGLobbyDetails = copied.lobby_details
		var info: Dictionary = details.copy_info()
		if not EOS.is_success(info): continue
		var data: Dictionary = info.lobby_details
		var attrs := {}
		for index in details.get_attribute_count():
			var attr: Dictionary = details.copy_attribute_by_index(index)
			if EOS.is_success(attr): attrs[str(attr.attribute.data.key).to_lower()] = attr.attribute.data.value
		if "--settings-test" in OS.get_cmdline_user_args(): print("EOS_DIAG attribute_keys=", attrs.keys())
		if not attrs.has("crew_title") or not attrs.has("socket"): continue
		listings[data.lobby_id] = {"details": details, "owner": data.lobby_owner_user_id, "socket": attrs.socket}
		EOSGRuntime.crews[data.lobby_id] = {"id": data.lobby_id, "internet": true, "title": str(attrs.crew_title).left(32), "count": data.max_members - data.available_slots, "locked": attrs.get("locked", false)}
	EOSGRuntime.set_status("Choose a crew to join." if not listings.is_empty() else "No online crews yet. Launch yours and invite a friend to browse.")
	search = null

func host(title: String, secret: String, resume_world: bool) -> void:
	if not await connect_online(): return
	EOSGRuntime.set_status("Launching your crew…")
	var opts := EOS.Lobby.CreateLobbyOptions.new()
	opts.bucket_id = NetworkSession.PROTOCOL
	opts.max_lobby_members = NetworkSession.MAX_CREW
	opts.presence_enabled = false
	opts.enable_join_by_id = false
	opts.disable_host_migration = true
	var result := await request("lobby_interface_create_lobby_callback", func(): EOS.Lobby.LobbyInterface.create_lobby(opts))
	if not EOS.is_success(result):
		fail("Could not launch the crew.", result)
		return
	lobby_id = result.lobby_id
	is_host = true
	var socket := "hs" + Crypto.new().generate_random_bytes(12).hex_encode()
	var modopts := EOS.Lobby.UpdateLobbyModificationOptions.new()
	modopts.lobby_id = lobby_id
	result = EOS.Lobby.LobbyInterface.update_lobby_modification(modopts)
	if not EOS.is_success(result):
		await leave_lobby()
		fail("Could not publish crew details.", result)
		return
	var modification: EOSGLobbyModification = result.lobby_modification
	modification.add_attribute("crew_title", title.left(32), EOS.Lobby.LobbyAttributeVisibility.Public)
	modification.add_attribute("socket", socket, EOS.Lobby.LobbyAttributeVisibility.Public)
	modification.add_attribute("locked", not secret.is_empty(), EOS.Lobby.LobbyAttributeVisibility.Public)
	var update := EOS.Lobby.UpdateLobbyOptions.new()
	update.lobby_modification = modification
	result = await request("lobby_interface_update_lobby_callback", func(): EOS.Lobby.LobbyInterface.update_lobby(update))
	if not EOS.is_success(result):
		await leave_lobby()
		fail("Could not publish crew details.", result)
		return
	var peer := EOSGMultiplayerPeer.new()
	if peer.create_server(socket) != OK:
		await leave_lobby()
		fail("Could not start the crew connection.")
		return
	NetworkSession.crew_title = title
	NetworkSession.start_host_peer(peer, secret, resume_world, true)
	EOSGRuntime.set_status("Your crew is online. Friends can find it in Browse crews.")

func join_crew(id: String, secret: String) -> void:
	if not await connect_online(): return
	if not listings.has(id):
		fail("That crew listing expired. Refresh and try again.")
		return
	var entry: Dictionary = listings[id]
	if entry.owner == EOSGRuntime.local_product_user_id:
		fail("This crew belongs to your online sailor. Use a different device or OS account to join it.")
		return
	EOSGRuntime.set_status("Joining the crew…")
	var opts := EOS.Lobby.JoinLobbyOptions.new()
	opts.lobby_details = entry.details
	opts.presence_enabled = false
	var result := await request("lobby_interface_join_lobby_callback", func(): EOS.Lobby.LobbyInterface.join_lobby(opts))
	if not EOS.is_success(result):
		fail("That crew is full or no longer available. Refresh the list.", result)
		return
	lobby_id = result.lobby_id
	is_host = false
	var peer := EOSGMultiplayerPeer.new()
	if peer.create_client(entry.socket, entry.owner) != OK:
		await leave_lobby()
		fail("Could not connect to the captain.")
		return
	NetworkSession.start_client_peer(peer, secret, true)

func leave_lobby() -> void:
	while _leaving: await get_tree().process_frame
	if lobby_id.is_empty() or not platform: return
	_leaving = true
	var id := lobby_id
	lobby_id = ""
	if is_host:
		var opts := EOS.Lobby.DestroyLobbyOptions.new()
		opts.lobby_id = id
		await request("lobby_interface_destroy_lobby_callback", func(): EOS.Lobby.LobbyInterface.destroy_lobby(opts), 5)
	else:
		var opts := EOS.Lobby.LeaveLobbyOptions.new()
		opts.lobby_id = id
		await request("lobby_interface_leave_lobby_callback", func(): EOS.Lobby.LobbyInterface.leave_lobby(opts), 5)
	is_host = false
	_leaving = false

func _member_status(data: Dictionary) -> void:
	if data.get("lobby_id", "") != lobby_id or lobby_id.is_empty(): return
	if data.get("current_status") == EOS.Lobby.LobbyMemberStatus.Closed:
		NetworkSession.leave("The captain ended this voyage.")

func shutdown() -> void:
	if closing: return
	closing = true
	listings.clear()
	EOSGRuntime.crews.clear()
	if platform:
		platform = false
		# EOSG 2.3.1 leaves its native mediator subscribed after peer.close().
		# Remove that frame callback before releasing its SDK handles.
		var mediator := Engine.get_singleton("EOSGPacketPeerMediator")
		for connection in get_tree().process_frame.get_connections():
			var callback: Callable = connection.callable
			if callback.get_object() == mediator: get_tree().process_frame.disconnect(callback)
		EOS.Platform.PlatformInterface.release()
	if initialized:
		initialized = false
		EOS.Platform.PlatformInterface.shutdown()
