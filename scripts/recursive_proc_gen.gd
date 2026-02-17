extends Node2D


func _ready() -> void:
	#580016261
	#2220045139
	#312134275
	#777890827
	#727014943
	#463874050
	#3600790370
	#4284279709
	var dungeon := Dungeon.new(randi(), 5, 8)
	dungeon.first_pass()
	var branches := dungeon.place_branches()
	#print(dungeon)
	print(branches)
	@warning_ignore("return_value_discarded")
	draw.connect(draw_rects.bind(branches))
	
	#print(dungeon.starting_branch.connections[0].id)
	#dungeon._to_string()
	#print(dungeon.starting_branch.connections[0].depth)
	
	#print(dungeon.starting_branch.connections[0]," ", dungeon.starting_branch.connections[0].depth)
	#print(dungeon.starting_branch.connections[1]," ", dungeon.starting_branch.connections[1].depth)

#func _draw() -> void:
	#draw_line()

func draw_rects(branches: Array[Dungeon.Branch]) -> void: 
	#print(branches[7])
	for branch in branches:
		if branch.is_main:
			draw_rect(branch.bb, Color.RED)
		else:
			draw_rect(branch.bb, Color.BLUE)
		draw_rect(branch.bb, Color.BLACK, false)
