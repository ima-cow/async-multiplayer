extends Node2D


func _ready() -> void:
	var dungeon := Dungeon.new(randi(), 10, 5)
	dungeon.first_pass()
	var branches := dungeon.alloc_branches()
	print(branches)
	@warning_ignore("return_value_discarded")
	draw.connect(draw_rects.bind(branches))
	
	#print(dungeon.starting_branch.connections[0].id)
	#dungeon._to_string()
	#print(dungeon.starting_branch.connections[0].depth)
	
	#print(dungeon.starting_branch.connections[0]," ", dungeon.starting_branch.connections[0].depth)
	#print(dungeon.starting_branch.connections[1]," ", dungeon.starting_branch.connections[1].depth)

func draw_rects(branches: Array[Rect2i]) -> void: 
	for rect in branches:
		draw_rect(rect, Color.RED)
		draw_rect(rect, Color.BLACK, false)
