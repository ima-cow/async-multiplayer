extends Node

var max_player_count := 4

var data:Dictionary[String, Variant] = {
	"dungeon_1":false,
	"dungeon_2":false,
	"dungeon_3":false,
}

var diffs:Dictionary[int, Dictionary]


#func set_value(key:String, value:Variant):
	#for player_id:int in diffs:
		#if multiplayer.get_peers().has
