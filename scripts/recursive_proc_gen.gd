extends Node


func _ready() -> void:
	var dungeon := Dungeon.new(randi(), 1, 3)
	#dungeon._to_string()
	print(dungeon)
