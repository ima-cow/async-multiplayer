extends Control

var settings:Dictionary[String, Variant] = {
	"username":""
}

var save_names:Array[String]


func _ready() -> void:
	var err:Error
	
	#if save directory doesnt exist make it
	if !DirAccess.dir_exists_absolute("user://saves"):
		err = DirAccess.make_dir_absolute("user://saves")
		assert(!err, "Failed to create save directory: "+error_string(err))
	
	#load names of saves into save_names
	var save_dir := DirAccess.open("user://saves")
	err = DirAccess.get_open_error()
	assert(!err, "Failed to access save folder: "+error_string(err))
	
	save_dir.list_dir_begin()
	var file_name := save_dir.get_next()
	while file_name != "":
		if !save_dir.current_is_dir():
			if file_name.substr(file_name.length()-4) == ".dat":
				print("Found save: " + file_name)
				var file_name_value := file_name.substr(0, file_name.length()-4)
				save_names.append(file_name_value)
			else:
				print("Unknown file type found in save directory: "+file_name)
		else:
			print("Unknown directory found in save directory: "+file_name)
		file_name = save_dir.get_next()
	
	#if settings dont exist set the defaults, if they do read the file into settings
	var settings_file: FileAccess
	
	if !FileAccess.file_exists("user://settings.dat"):
		settings_file = FileAccess.open("user://settings.dat", FileAccess.WRITE)
		err = FileAccess.get_open_error()
		assert(!err, "Failed to load settings: "+error_string(err))
		assert(settings_file.store_var(settings), "Failed to set default settings")
	else:
		settings_file = FileAccess.open("user://settings.dat", FileAccess.READ)
		err = FileAccess.get_open_error()
		assert(!err, "Failed to load settings: "+error_string(err))
		
		var data:Variant = settings_file.get_var()
		assert(data is Dictionary[String, Variant], "Settings data is corrupted or missing")
		settings = data


func _on_host_game_pressed() -> void: 
	#show the host game menu
	_close_menus()
	$CenterContainer/Main/VSeparator.visible = true
	$CenterContainer/Main/HostGame.visible = true

	#display a button for every valid save
	for save_name in save_names:
		_create_open_save_button(save_name)


func _on_create_game_pressed() -> void:
	#create field for new save if there isnt already one
	if %SaveList.get_child_count() == 1 or %SaveList.get_child(1) is not LineEdit:
		var name_field := LineEdit.new()
		name_field.placeholder_text = "Save name..."
		name_field.max_length = 30

		%SaveList.add_child(name_field)
		%SaveList.move_child(name_field, 1)

		await name_field.text_submitted

		#afer waiting for name to be submited add it to dict and create a button
		save_names.push_front(name_field.text)

		_create_open_save_button(name_field.text)
		name_field.queue_free()


func _create_open_save_button(save_name: String) -> void:
	#create a button for a save and connect signals
	var save_container := HBoxContainer.new()
	save_container.name = save_name

	var open_save_button := Button.new()
	open_save_button.text = save_name
	open_save_button.custom_minimum_size.x = 307

	var delete_open_save_button := Button.new()
	delete_open_save_button.text = "X"

	%SaveList.add_child(save_container)
	%SaveList.move_child(save_container, 1)
	save_container.add_child(open_save_button)
	save_container.add_child(delete_open_save_button)

	open_save_button.pressed.connect(_on_open_save_button_pressed.bind(save_name))
	delete_open_save_button.pressed.connect(_on_save_delete_button_pressed.bind(save_name))


func _on_open_save_button_pressed(save_name:String) -> void:
	var err:Error
	
	var game:Node = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child(game)
	
	#if save file is found loads the data, otherwise writes a file with defaults
	#var save_file := FileAccess.open("user://saves/"+save_name+".dat", FileAccess.WRITE_READ)
	err = FileAccess.get_open_error() 
	assert(!err, "Failed to access save file: "+error_string(err))
	
	var save_file_size := FileAccess.get_size("user://saves/"+save_name+".dat")
	assert(save_file_size != -1, "Failed to access save file")
	#if save_file_size == 0:
		#assert(save_file.store_var(game.data), "Failed to write defaults to save file")
	#else:
		#var data:Variant = save_file.get_var()
		#assert(data is Dictionary[String, Variant], "Save data is corrupted or missing")
		#game.data = data
		#
		#var diffs:Variant = save_file.get_var()
		#assert(diffs is Dictionary[String, Dictionary], "Save diffs are corrupted or missing")
		#game.diffs = diffs
	
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY)


func _on_save_delete_button_pressed(save_name:String) -> void:
	#erase save from dict and delete the corrisponding button
	save_names.erase(save_name)
	get_node("%SaveList/"+save_name).queue_free()


func _on_join_game_pressed() -> void:
	#make joining menu visible
	_close_menus()
	$CenterContainer/Main/VSeparator.visible = true
	$CenterContainer/Main/JoinGame.visible = true
	
	#for each lobby with friends in them create a button and set the text all of friends names in the lobby
	var lobbies := SteamManager.get_friend_lobbies()
	
	for lobby_id in lobbies:
		var lobby_button := Button.new()
		for player_id: int in lobbies[lobby_id]:
			lobby_button.text += " "+Steam.getFriendPersonaName(player_id)
		lobby_button.pressed.connect(_on_lobby_button_pressed.bind(lobby_id))
		%LobbieList.add_child(lobby_button)


func _on_lobby_button_pressed(lobby_id: int) -> void:
	Steam.joinLobby(lobby_id)


func _on_settings_pressed() -> void:
	pass


func _on_quit_pressed() -> void:
	assert(!_save_settings(), "Failed to save settings")
	get_tree().quit()


func _save_settings() -> Error:
	var settings_file := FileAccess.open("user://settings.dat", FileAccess.WRITE)
	var err := FileAccess.get_open_error() #this function can error
	if err:
		return err

	if !settings_file.store_var(settings):
		return ERR_FILE_CANT_WRITE

	return OK


func _close_menus() -> void:
	#hide all menus except for the main one
	for i in range(1, $CenterContainer/Main.get_child_count()):
		$CenterContainer/Main.get_child(i).visible = false
