extends Node

var dungeon: Dungeon
var current_room: Dungeon.Room
var current_room_scene: Node

@onready var player: RigidBody2D = $TestCharacter

var door_scene := preload("res://scenes/door.tscn")


func _ready() -> void:
	assert(dungeon != null)
	
	var starting_room := dungeon.starting_room.scene.instantiate()
	@warning_ignore("unsafe_property_access")
	starting_room.room = dungeon.starting_room
	current_room = dungeon.starting_room
	current_room_scene = starting_room
	
	_init_new_room(current_room_scene)
	add_child(current_room_scene)
	
	@warning_ignore("integer_division")
	player.position = dungeon.starting_room.bb.size / 2


func _init_new_room(room: Node) -> void:
	print(room.room.connections)
	@warning_ignore("unsafe_property_access")
	for next_room: Dungeon.Room in room.room.connections:
		var door: Node2D = door_scene.instantiate()
		
		print(next_room.connection_point)
		print(next_room.bb)
		
		door.position = next_room.connection_point - next_room.bb.position
		
		if not next_room.horizontal:
			door.rotation_degrees += 180.0
		
		@warning_ignore("unsafe_property_access")
		door.first_room = current_room
		@warning_ignore("unsafe_property_access")
		door.second_room = next_room
		
		var door_rb: RigidBody2D = door.get_child(0)
		var err := door_rb.body_entered.connect(_on_door_body_entered.bind(door))
		assert(!err)
		
		room.add_child(door)
	print(room.get_children())


func _on_door_body_entered(body: Node, door: Node2D) -> void:
	if body != player:
		return
	print("contact")
	
	
	@warning_ignore("unsafe_property_access")
	var new_room: Dungeon.Room = door.second_room if not door.passed else door.first_room
	var new_room_scene := new_room.scene.instantiate()
	
	current_room_scene.queue_free()
	@warning_ignore("unsafe_property_access")
	new_room_scene.room = new_room
	current_room_scene = new_room_scene
	_init_new_room(new_room_scene)
	
	#add_child(new_room_scene)
	call_deferred("add_child", new_room_scene)
	#print("swapped")
