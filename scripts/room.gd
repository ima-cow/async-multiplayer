extends Node

var door_scene := preload("res://scenes/door.tscn")

var room: Dungeon.Room

@export var rect: Rect2i

@onready var left_side: RigidBody2D = $Sides/LeftSide
@onready var top_side: RigidBody2D = $Sides/TopSide
@onready var right_side: RigidBody2D = $Sides/RightSide
@onready var bottom_side: RigidBody2D = $Sides/BottomSide


func _ready() -> void:
	assert(left_side.position == Vector2.ZERO)
	assert(left_side.position == top_side.position)
	assert(right_side.position == bottom_side.position)
	assert(Vector2i(left_side.position) == rect.position)
	assert(Vector2i(right_side.position) == rect.end)
	assert(room != null)
	assert(room.bb.size == rect.size)
	
	for next_room in room.connections:
		var door: Node2D = door_scene.instantiate()
		
		door.position = next_room.connection_point
		
		if not next_room.horizontal:
			door.rotation_degrees += 180.0
		
		@warning_ignore("unsafe_property_access")
		door.first_room = room
		@warning_ignore("unsafe_property_access")
		door.second_room = next_room
		
		var door_rb: RigidBody2D = door.get_child(0)
		@warning_ignore("return_value_discarded")
		door_rb.body_entered.connect(_on_door_body_entered.bind(door))
		
		add_child(door)


func _on_door_body_entered(body: Node, door: Node2D) -> void:
	@warning_ignore("unsafe_property_access")
	if body != get_parent().player:
		return
	
	@warning_ignore("unsafe_property_access")
	var new_room: Dungeon.Room = door.first_room if not door.passed else door.second_room
	var new_room_scene := new_room.scene.instantiate()
	
	
