extends Node


func _ready() -> void:
	
	print(Dungeon.generate(Dungeon.new(0, 1, 1)).starting_room)
