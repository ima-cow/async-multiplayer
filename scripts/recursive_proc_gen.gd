extends Node


func _ready() -> void:
	var dungeon := Dungeon.generate(Dungeon.new(0, 3, 2))
	#print(dungeon.connections[dungeon.starting_room.id])
	print(dungeon)
	#print(dungeon.starting_room.id)
