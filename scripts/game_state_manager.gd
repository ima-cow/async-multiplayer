extends Node

var save_name: String

#game state in the form [object, value] where is object is the thing to be saved, eg status of dungeon or invantory
var state: Dictionary[String, Variant] = {
	"dungeon_1":false,
	"dungeon_2":false,
	"dungeon_3":false,
}

#diffs for each player in the form [steam id, diffed game state]
var diffs:Dictionary[int, Dictionary] = {
	-1:state
}


func set_state_or_diffs(key:String, value:Variant) -> void:
	#for every regesiterd steam id check if that player is in game, if they are call set state on them, otherwise set diffs for the value at that players id
	for steam_id:int in diffs:
		if SteamManager.peer_steam_ids.values().has(steam_id):
			var peer_id: int = SteamManager.peer_steam_ids.find_key(steam_id)
			_set_state.rpc_id(peer_id, key, value)
		else:
			diffs[steam_id][key] = value 


@rpc("any_peer", "call_local")
func _set_state(key:String, value:Variant) -> void:
	print("state of: ",key," was set to: ",value," by id: ", multiplayer.get_remote_sender_id())
	state[key] = value


@rpc("any_peer") @warning_ignore("shadowed_variable")
func sync(state: Dictionary[String, Variant]) -> void:
	#set all objects in state to the new state
	for object:String in state:
		self.state[object] = state[object]


func save() -> Error:
	var save_file := FileAccess.open("user://saves/"+save_name+".dat", FileAccess.WRITE)
	var err := FileAccess.get_open_error() 
	if err:
		return err
	
	if !save_file.store_var(state) or !save_file.store_var(diffs):
		return ERR_FILE_CANT_WRITE
	
	return OK


#func get_diff_for_peer_id(peer_id: int) -> Dictionary[String, Variant]:
	#var steam_id = SteamManager.peer_steam_ids[peer_id]
	#return 
