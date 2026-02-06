extends Node


func _ready() -> void:
	print(Rect2i(Vector2i.ZERO, Vector2(5, 5)).end)
	var dungeon := Dungeon.new(randi(), 10, 5)
	dungeon.first_pass()
	#print(dungeon.starting_branch.connections[0].id)
	#dungeon._to_string()
	#print(dungeon.starting_branch.connections[0].depth)
	
	#print(dungeon.starting_branch.connections[0]," ", dungeon.starting_branch.connections[0].depth)
	#print(dungeon.starting_branch.connections[1]," ", dungeon.starting_branch.connections[1].depth)
