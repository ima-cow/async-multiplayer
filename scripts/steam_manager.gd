extends Node

const APP_ID := 480
var lobby_id := -1
var steam_id: int
const SERVER := 1

#peer unique ids with thier corisponding steam ids [peer id : steam id]
var peer_steam_ids: Dictionary[int, int]

var handshake_count := 0
signal name_and_id_set


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
	
	@warning_ignore("return_value_discarded")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
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
	multiplayer.connected_to_server.connect(func() -> void: _sync_handshake_1.rpc(steam_id))
	multiplayer.connection_failed.connect(func() -> void: assert(false, "Failed to connect to server"))
	multiplayer.peer_connected.connect(func(_peer_id: int) -> void: pass)
	multiplayer.peer_disconnected.connect(func(peer_id: int) -> void: peer_steam_ids.erase(peer_id))
	multiplayer.server_disconnected.connect(func() -> void: assert(false, "Server disconnected"))
	@warning_ignore_restore("return_value_discarded")
	
	#map our own peer and steam id
	peer_steam_ids[multiplayer.get_unique_id()] = steam_id
	print("my peer id: ", multiplayer.get_unique_id())
	print("my steam id: ", steam_id)
	print("joined lobby")


#called on all peers execpt the one just joining by the one just joining
@rpc("any_peer")
func _sync_handshake_1(sender_steam_id: int) -> void:
	#map the senders steam id to peer steam ids then call the next handshake
	var sender_id := multiplayer.get_remote_sender_id()
	peer_steam_ids[sender_id] = sender_steam_id
	
	if multiplayer.is_server():
		if sender_steam_id in GameStateManager.diffs:
			_sync_handshake_2.rpc_id(sender_id, steam_id, GameStateManager.save_name, GameStateManager.save_id)
	else:
		_sync_handshake_2.rpc_id(sender_id, steam_id)


#called on the peer just joining by the all other peers
@rpc("any_peer")
func _sync_handshake_2(sender_steam_id: int, save_name: String = "", save_id: int = -1, state: Dictionary = {}) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	peer_steam_ids[sender_id] = sender_steam_id
	
	if sender_id == SERVER:
		GameStateManager.save_name = save_name
		GameStateManager.save_id = save_id
		
		if !state.is_empty():
			GameStateManager.sync(state, sender_steam_id)
			_sync_handshake_3.rpc_id(sender_id, steam_id)
			return
	
	handshake_count += 1
	if handshake_count == len(multiplayer.get_peers()):
		if FileAccess.file_exists("user://saves/"+GameStateManager.save_name+".dat"):
			var err := GameStateManager.load_state()
			assert(!err, "Failed to load game state")
	for peer_id in multiplayer.get_peers():
		var target_steam_id := peer_steam_ids[peer_id]
		_sync_handshake_3.rpc_id(peer_id, steam_id, GameStateManager.diffs[target_steam_id])


#called on all peers execpt the one just joining by the one just joining
@rpc("any_peer")
func _sync_handshake_3(sender_steam_id: int, state: Dictionary = {}) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if !state.is_empty():
		GameStateManager.sync(state, sender_id)
	
	var err := GameStateManager.save_state()
	assert(!err)
	
	if sender_steam_id in GameStateManager.diffs:
		_sync_handshake_4.rpc_id(sender_id, GameStateManager.diffs[sender_steam_id])
	else:
		GameStateManager.diffs[sender_steam_id] = {}
		_sync_handshake_4.rpc_id(sender_id)
		
	
	print("peer steam id: ", peer_steam_ids)
	print("name: ",GameStateManager.save_name)
	print("id: ",GameStateManager.save_id)
	print("state: ",GameStateManager.state)
	print("diffs: ",GameStateManager.diffs)


#called on the peer just joining by the all other peers
@rpc("any_peer")
func _sync_handshake_4(state: Dictionary = {}) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	var sender_steam_id := peer_steam_ids[sender_id]
	if !state.is_empty():
		GameStateManager.sync(state, sender_steam_id)
	
	var err := GameStateManager.save_state()
	assert(!err)
	
	@warning_ignore("return_value_discarded")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
	
	print("peer steam id: ", peer_steam_ids)
	print("name: ",GameStateManager.save_name)
	print("id: ",GameStateManager.save_id)
	print("state: ",GameStateManager.state)
	print("diffs: ",GameStateManager.diffs)


func get_friend_lobbies() -> Dictionary[int, Array]:
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
