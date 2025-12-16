extends Control

var settings:Dictionary[String, Variant] = {
	"save_names":[],
}

func _ready() -> void:
	var settings_file: FileAccess
	var err: Error #this fucntion can error, not returned game panics
	
	#if settings dont exist set the defaults
	#if they do read the file into settings
	if !FileAccess.file_exists("user://settings.dat"):
		settings_file = FileAccess.open("user://settings.dat", FileAccess.WRITE)
		err = FileAccess.get_open_error()
		if err:
			printerr("Failed to load settings: ",err)
			get_tree().paused = true
			
		if !settings_file.store_var(settings):
			printerr("Failed to set default settings: ",err)
			get_tree().paused = true
	else:
		settings_file = FileAccess.open("user://settings.dat", FileAccess.READ)
		err = FileAccess.get_open_error()
		if err:
			printerr("Failed to load settings: ",err)
			get_tree().paused = true
		
		var data:Variant = settings_file.get_var()
		if data is Dictionary[String, Variant]:
			settings = data
		else:
			printerr("Settings data is corrupted or missing: ", Error.ERR_FILE_CORRUPT)
			get_tree().paused = true


func _on_host_game_pressed() -> void: #this function can error, not returned so game panics
	#show the host game menu
	$CenterContainer/Main/VSeparator.visible = true
	$CenterContainer/Main/HostGame.visible = true
	
	#display a button for every valid save
	if settings["save_names"] is Array:
		if settings["save_names"].size() != 0:
			for save_name in settings["save_names"]:
				if save_name is String:
					_create_save_button(save_name)
				else:
					printerr("Save name data is corrupted: ", Error.ERR_INVALID_DATA)
					get_tree().paused = true
	else:
		printerr("Save name data is corrupted: ", Error.ERR_INVALID_DATA)
		get_tree().paused = true
		


func _on_create_game_pressed() -> void:
	#create field for new save if there is one
	if %SaveList.get_child_count() == 1 or %SaveList.get_child(1) is not LineEdit:
		var name_field := LineEdit.new()
		name_field.placeholder_text = "Save name..."
		name_field.max_length = 30
		
		%SaveList.add_child(name_field)
		%SaveList.move_child(name_field, 1)
		
		await name_field.text_submitted
		
		#afer waiting for name to be submited add it to dict and create a button 
		settings["save_names"].push_front(name_field.text)
		
		_create_save_button(name_field.text)
		name_field.queue_free()


func _create_save_button(save_name: String) -> void:
	#create a button for a save and delete and connect signals
	var save_container := HBoxContainer.new()
	
	var save_button := Button.new()
	save_button.text = save_name
	save_button.name = save_name
	save_button.custom_minimum_size.x = 307
	
	var delete_save_button := Button.new()
	delete_save_button.text = "X"
	
	%SaveList.add_child(save_container)
	%SaveList.move_child(save_container, 1)
	save_container.add_child(save_button)
	save_container.add_child(delete_save_button)


func _on_join_game_pressed() -> void:
	pass


func _on_settings_pressed() -> void:
	pass


func _on_quit_pressed() -> void:
	var err := _save_settings()
	if err:
		printerr("Failed to save settings: ", err)
		get_tree().paused = true
	
	get_tree().quit()


func _save_settings() -> Error:
	var settings_file: FileAccess
	var err: Error #this function can error
	
	settings_file = FileAccess.open("user://settings.dat", FileAccess.WRITE)
	err = FileAccess.get_open_error()
	if err:
		return err
	
	if !settings_file.store_var(settings):
		return Error.ERR_FILE_CANT_WRITE
	
	return Error.OK


func _on_save_button_pressed() -> Error:
	var err: Error
	
	return Error.OK
