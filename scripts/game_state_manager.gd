extends Node

var save_name: String
var save_id: int

#game state in the form [object, value] where is object is the thing to be saved, eg status of dungeon or invantory
var state: Dictionary[StringName, Variant] = {
	&"dungeon_1":false,
	&"dungeon_2":false,
	&"dungeon_3":false,
}

#diffs for each player in the form [steam id, diffed game state]
var diffs:Dictionary[int, Dictionary] = {
}


func set_state_or_diffs(key:String, value:Variant) -> void:
	#for every regesiterd steam id check if that player is in game, if they are call set state on them, otherwise set diffs for the value at that players id
	_set_state(key, value)
	for steam_id:int in diffs:
		#print(SteamManager.peer_steam_ids)
		if steam_id in SteamManager.peer_steam_ids.values():
			#print(diffs)
			var peer_id: int = SteamManager.peer_steam_ids.find_key(steam_id)
			_set_state.rpc_id(peer_id, key, value)
		else:
			diffs[steam_id][key] = value 


@rpc("any_peer", "call_local")
func _set_state(key:String, value:Variant) -> void:
	print("state of: ",key," was set to: ",value," by id: ", multiplayer.get_remote_sender_id())
	state[key] = value


@warning_ignore("shadowed_variable")
func sync(state: Dictionary) -> void:
	for object:String in state:
		print("state of: ",object," was set to: ",state[object]," by id: ", multiplayer.get_remote_sender_id())
		self.state[object] = state[object]


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
	assert(save_id == contents[1] or contents[1] == null, "Mismatched save ids")
	save_id = contents[1]
	state = contents[2]
	diffs = contents[3]
	print("state: ",state)
	print("diffs: ",diffs)
	
	return OK
