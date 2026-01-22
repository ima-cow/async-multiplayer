extends Node


func _ready() -> void:
	var dungeon := Dungeon.generate(Dungeon.new(randi(), 10, 2))
	print(dungeon)
