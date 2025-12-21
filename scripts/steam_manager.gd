extends Node

const APP_ID := 480
var lobby_id := -1
var steam_id: int


func _ready() -> void:
	var steamInitStatus := Steam.steamInitEx(APP_ID)
	assert(steamInitStatus["status"] == OK, "Failed to initialize steam: "+steamInitStatus["verbal"])
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	steam_id = Steam.current_steam_id



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
	


@warning_ignore("shadowed_variable")
func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	#if the lobby joined sucsessfully connect to it with a peer
	assert(response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS, "Failed to join lobby")
	
	if Steam.getLobbyOwner(lobby_id) == steam_id:
		return
	
	self.lobby_id = lobby_id
	
	var peer := SteamMultiplayerPeer.new()
	peer.server_relay = true
	var err := peer.connect_to_lobby(lobby_id)
	assert(!err, "Failed to join lobby: "+error_string(err))
	
	multiplayer.multiplayer_peer = peer


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
