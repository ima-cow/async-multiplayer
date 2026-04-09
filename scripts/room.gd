extends Node

var room: Dungeon.Room

@export var rect: Rect2i

@onready var left_side: StaticBody2D = $Sides/LeftSide
@onready var top_side: StaticBody2D = $Sides/TopSide
@onready var right_side: StaticBody2D = $Sides/RightSide
@onready var bottom_side: StaticBody2D = $Sides/BottomSide


func _ready() -> void:
	assert(left_side.position == Vector2.ZERO)
	assert(left_side.position == top_side.position)
	assert(right_side.position == bottom_side.position)
	assert(Vector2i(left_side.position) == rect.position)
	assert(Vector2i(right_side.position) == rect.end)
	assert(room != null)
	assert(room.bb.size == rect.size)
