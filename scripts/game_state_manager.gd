extends Node

var max_player_count := 4

enum panic_destination {
	ERROR_CONSOLE,
	ERROR_USER,
	MAIN_MENU,
	CRASH
}


var data: Dictionary[String, Variant] = {
	"dungeon_1":false,
	"dungeon_2":false,
	"dungeon_3":false,
}

var diffs:Dictionary[int, Dictionary]



#func set_value(key:String, value:Variant):
	#for player_id:int in diffs:
		#if multiplayer.get_peers().has

#static func panic(condition: bool, destination: panic_destination, message: String, pause_editor: bool = false) -> void:
	#if condition:
		#return
	#
	#push_error(message)
	#
	#match destination:
		#panic_destination.ERROR_CONSOLE when pause_editor:
			
