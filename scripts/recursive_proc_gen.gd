extends Node


func _ready() -> void:
	var dungeon := Dungeon.new(randi(), 2, 5)
	dungeon._first_pass()
	#dungeon._to_string()
	print(dungeon)
	#print(dungeon.starting_branch.connections[0].depth)
	
	#print(dungeon.starting_branch.connections[0]," ", dungeon.starting_branch.connections[0].depth)
	#print(dungeon.starting_branch.connections[1]," ", dungeon.starting_branch.connections[1].depth)
