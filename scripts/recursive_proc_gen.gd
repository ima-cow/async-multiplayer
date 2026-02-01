extends Node


func _ready() -> void:
	var dungeon := Dungeon.new(randi(), 5, 5)
	
	print(dungeon)
