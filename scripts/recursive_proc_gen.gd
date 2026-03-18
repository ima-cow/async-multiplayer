extends Node2D


func _ready() -> void:
	#3489947376 - failing
	#1437557178
	#3078261895 - fails
	var dungeon := Dungeon.new(randi(), 100)
	dungeon.first_pass()
	
	
	var branches_placed := dungeon.place_rooms()
	print(dungeon.starting_room.connection_point)
	
	assert(branches_placed)
	
	#print(dungeon.starting_branch.connections[0].bb)
	
	@warning_ignore("return_value_discarded")
	draw.connect(draw_rooms.bind(dungeon))

func draw_rooms(dungeon: Dungeon, room: Dungeon.Room = dungeon.starting_room) -> void:
	if room.depth == 0:
		draw_rect(dungeon.starting_room.bb, Color.PURPLE)
		draw_rect(dungeon.starting_room.bb, Color.BLACK, false)
		z_index = 1
		draw_circle(dungeon.starting_room.connection_point, 5, Color.BLACK)
		draw_string(ThemeDB.fallback_font, dungeon.starting_room.bb.position + Vector2i(3, ThemeDB.fallback_font_size), "0")
		z_index = 0
	
	#print(room.type)
	
	var main_room: Dungeon.Room
	
	for r in room.connections:
		if r.type == Dungeon.Room.types.END:
			draw_rect(r.bb, Color.PURPLE)
			main_room = r
		elif r.is_main:
			draw_rect(r.bb, Color.RED)
			main_room = r
		else:
			draw_rect(r.bb, Color.BLUE)
		draw_rect(r.bb, Color.BLACK, false)
		#z_index = 1
		draw_string(ThemeDB.fallback_font, r.bb.position + Vector2i(1, ThemeDB.fallback_font_size), str(r.depth))
		draw_circle(r.connection_point, 5, Color.BLACK)
		#z_index = 0
	
	#print(main_branch.id)
	if room.depth == dungeon.max_depth:
		return
	else:
		draw_rooms(dungeon, main_room)
