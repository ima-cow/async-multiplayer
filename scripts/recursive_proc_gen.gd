extends Node


func _ready() -> void:
	print(Dungeon.generate(1, 4)._to_string())
