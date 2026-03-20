extends Node

@export var rect := Rect2i(0, 0, 1000, 1000)

@onready var left_side: RigidBody2D = $Sides/LeftSide
@onready var top_side: RigidBody2D = $Sides/TopSide
@onready var right_side: RigidBody2D = $Sides/RightSide
@onready var bottom_side: RigidBody2D = $Sides/BottomSide


func _ready() -> void:
	assert(left_side.position == top_side.position)
	assert(right_side.position == bottom_side.position)
	assert(Vector2i(left_side.position) == rect.position)
	assert(Vector2i(right_side.position) == rect.end)
