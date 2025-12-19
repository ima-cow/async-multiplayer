extends Node

const APP_ID := 480
#const STEAM_ID := Steam.getSteamID()


func _ready() -> void:
	var steamInitStatus := Steam.steamInitEx(APP_ID)
	assert(steamInitStatus["status"] == OK, "Failed to initialize steam: "+steamInitStatus["verbal"])
	Steam.initRelayNetworkAccess()
	#STEAM_ID = Steam.getSteamID()


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func get_friend_hosted_lobbies() -> Dictionary:
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
		var friend_lobby: int = friend_game_info["lobby"]
		
		if friend_app_id != APP_ID or friend_lobby == 0:
			continue
		
		result[friend_app_id].append(friend_steam_id)
	
	return result
