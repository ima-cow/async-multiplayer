extends Node

var save_name: String
var save_id := -1

#game state in the form [object, value] where is object is the thing to be saved, eg status of dungeon or invantory
var state: Dictionary[StringName, Variant] = {
	&"dungeon_1":false,
	&"dungeon_2":false,
	&"dungeon_3":false,
}

#diffs for each player in the form [steam id, diffed game state]
var diffs:Dictionary[int, Dictionary] = {
}


func set_state_or_diffs(key:StringName, value:Variant) -> void:
	#for every regesiterd steam id check if that player is in game, if they are call set state on them, otherwise set diffs for the value at that players id
	_set_state(key, value)
	for steam_id:int in diffs:
		if steam_id in SteamManager.peer_steam_ids.values():
			var peer_id: int = SteamManager.peer_steam_ids.find_key(steam_id)
			_set_state.rpc_id(peer_id, key, value)
			print("set state of: ",key," to: ",value," on peer id: ", peer_id)
		else:
			diffs[steam_id][key] = value 
			print("set diffed state of: ",key," to: ",value," on steam id: ", steam_id)


@rpc("any_peer", "call_local")
func _set_state(key:StringName, value:Variant) -> void:
	print("state of: ",key," was set to: ",value," by id: ", multiplayer.get_remote_sender_id())
	state[key] = value


@warning_ignore("shadowed_variable")
func sync(state: Dictionary) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	for object:String in state:
		print("synced state of: ",object," to: ",state[object]," by id: ", sender_id)
		self.state[object] = state[object]
	_resolve_sync.rpc_id(sender_id)


@rpc("any_peer")
func _resolve_sync() -> void:
	var steam_id := SteamManager.peer_steam_ids[multiplayer.get_remote_sender_id()]
	diffs[steam_id] = {}


func save_state() -> Error:
	var save_file := FileAccess.open("user://saves/"+save_name+".dat", FileAccess.WRITE)
	var err := FileAccess.get_open_error() 
	if err:
		return err
	
	if !save_file.store_var([save_name, save_id, state, diffs]):
		return ERR_FILE_CANT_WRITE
	
	return OK


func load_state() -> Error:
	var save_file := FileAccess.open("user://saves/"+save_name+".dat", FileAccess.READ)
	var err := FileAccess.get_open_error() 
	if err:
		return err
	
	var contents: Array = save_file.get_var()
	
	assert(save_name == contents[0], "Mismatched save names")
	if !multiplayer.is_server():
		assert(save_id == contents[1], "Mismatched save ids")
	save_id = contents[1]
	state = contents[2]
	diffs = contents[3]
	print("save id: ",save_id)
	print("state: ",state)
	print("diffs: ",diffs)
	
	return OK
