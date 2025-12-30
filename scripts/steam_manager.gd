extends Node

const APP_ID := 480
var lobby_id := -1
var steam_id: int
const SERVER := 1

#peer unique ids with thier corisponding steam ids [peer id, steam id]
var peer_steam_ids: Dictionary[int, int]

var handshake_count := 0
var server_handshake := false
signal all_handshakes


func _ready() -> void:
	var steamInitStatus := Steam.steamInitEx(APP_ID)
	assert(steamInitStatus["status"] == OK, "Failed to initialize steam: "+steamInitStatus["verbal"])
	Steam.initRelayNetworkAccess()
	
	@warning_ignore("return_value_discarded")
	Steam.lobby_created.connect(_on_lobby_created)
	@warning_ignore("return_value_discarded")
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	steam_id = Steam.getSteamID()
	


func _process(_delta: float) -> void:
	Steam.run_callbacks()


@warning_ignore("shadowed_variable", "shadowed_variable_base_class")
func _on_lobby_created(connect: int, lobby_id: int) -> void:
	#if the lobby was properly created create a peer and host on it 
	assert(connect == Steam.Result.RESULT_OK, "Failed to create or connect to created lobby: "+str(connect))
	
	self.lobby_id = lobby_id
	
	var peer := SteamMultiplayerPeer.new()
	peer.server_relay = true
	var err := peer.host_with_lobby(lobby_id)
	assert(!err, "Failed to host lobby: "+error_string(err))
	
	multiplayer.multiplayer_peer = peer
	peer_steam_ids[multiplayer.get_unique_id()] = steam_id
	
	print("created lobby")


@warning_ignore("shadowed_variable")
func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	assert(response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS, "Failed to join lobby")
	
	#if we are not connecting to our own lobby to ourselves create a new peer 
	if Steam.getLobbyOwner(lobby_id) != steam_id:
		self.lobby_id = lobby_id
		
		var peer := SteamMultiplayerPeer.new()
		peer.server_relay = true
		var err := peer.connect_to_lobby(lobby_id)
		assert(!err, "Failed to join lobby: "+error_string(err))
		
		multiplayer.multiplayer_peer = peer
	
	@warning_ignore_start("return_value_discarded")
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected.bind(steam_id))
	multiplayer.peer_disconnected.connect(_on_peer_disconnected.bind(steam_id))
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	@warning_ignore_restore("return_value_discarded")
	
	print("joined lobby")


func _on_connected_to_server() -> void:
	await all_handshakes
	
	if FileAccess.file_exists("user://saves/"+GameStateManager.save_name+".dat"):
		var err := GameStateManager.load_state()
		assert(!err, "Failed to load game state")
		
		_sync_handshake.rpc(steam_id, GameStateManager.diffs[steam_id])
	else:
		_sync_handshake.rpc(steam_id)


func _on_connection_failed() -> void:
	assert(false, "Failed to connect to server")


@warning_ignore("shadowed_variable")
func _on_peer_connected(peer_id: int, steam_id: int) -> void:
	if steam_id in GameStateManager.diffs:
		if multiplayer.is_server():
			_sync_handshake.rpc_id(peer_id, steam_id, GameStateManager.diffs[steam_id], GameStateManager.save_name, GameStateManager.save_id)
		else:
			_sync_handshake.rpc_id(peer_id, steam_id, GameStateManager.diffs[steam_id])
	else:
		GameStateManager.diffs[steam_id] = {}
		if multiplayer.is_server():
			_sync_handshake.rpc_id(peer_id, steam_id, {}, GameStateManager.save_name, GameStateManager.save_id)
		else:
			_sync_handshake.rpc_id(peer_id, steam_id)


func _on_peer_disconnected(peer_id: int, _steam_id: int) -> void:
	@warning_ignore("return_value_discarded")
	peer_steam_ids.erase(peer_id)


func _on_server_disconnected() -> void:
	assert(false, "Server disconnected")


func get_friend_lobbies() -> Dictionary[int, Array]:
	# in the form lobby id : array of friend steam ids
	var result: Dictionary[int, Array]
	
	#get all normal steam friends
	var num_friends := Steam.getFriendCount(Steam.FRIEND_FLAG_IMMEDIATE)
	assert(num_friends != -1, "Failed to get number of friends, offline")
	
	#if friend is in a lobby in this game add them to an array for that lobbie id
	for i in range(0, num_friends):
		var friend_steam_id := Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var friend_game_info := Steam.getFriendGamePlayed(friend_steam_id)
		
		if friend_game_info.is_empty():
			continue
		
		var friend_app_id: int = friend_game_info["id"]
		var friend_lobby_id: int = friend_game_info["lobby"]
		
		if friend_app_id != APP_ID or friend_lobby_id == 0:
			continue
		
		if result.has(friend_lobby_id):
			result[friend_lobby_id].append(friend_steam_id)
		else:
			result[friend_lobby_id] = [friend_steam_id]
	
	return result


@rpc("any_peer") @warning_ignore("shadowed_variable")
func _sync_handshake(steam_id: int, state: Dictionary = {}, save_name: String = "", save_id: int = -1) -> void:
	if !state.is_empty():
		GameStateManager.sync(state)
	
	peer_steam_ids[multiplayer.get_remote_sender_id()] = steam_id
	
	if multiplayer.get_remote_sender_id() == SERVER:
		GameStateManager.save_name = save_name
		GameStateManager.save_id = save_id
		server_handshake = true
	
	handshake_count += 1
	if handshake_count == len(multiplayer.get_peers())+1:
		all_handshakes.connect(_on_all_handshakes)
		all_handshakes.emit()

func _on_all_handshakes() -> void:
	print("hands")
