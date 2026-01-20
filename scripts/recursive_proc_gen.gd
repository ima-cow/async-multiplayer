extends Node


func _ready() -> void:
	print(Dungeon.generate(Dungeon.new(29, 3, 4))._to_string())
