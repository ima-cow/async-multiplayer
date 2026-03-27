extends Node

var dungeon: Dungeon
@onready var player: CharacterBody2D = $TestCharacter


func _ready() -> void:
	assert(dungeon != null)
	
	var starting_room := dungeon.starting_room.scene.instantiate()
	@warning_ignore("unsafe_property_access")
	starting_room.room = dungeon.starting_room
	add_child(starting_room)
	
	@warning_ignore("integer_division")
	player.position = dungeon.starting_room.bb.size / 2
