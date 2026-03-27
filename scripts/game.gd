extends Node

var dungeon: Dungeon
@onready var player: CharacterBody2D = $TestCharacter

func _ready() -> void:
	assert(dungeon != null)
	
	add_child(dungeon.starting_room.scene.instantiate())
	
	@warning_ignore("integer_division")
	player.position = dungeon.starting_room.bb.size / 2
