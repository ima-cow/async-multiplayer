extends Node2D


func _ready() -> void:
	#4049863471
	#1308544262
	var dungeon := Dungeon.new(randi(), 100)
	dungeon.first_pass()
	
	var branches_placed := dungeon.place_rooms()
	assert(branches_placed)
	
	#print(dungeon.starting_room.connections[0].connections[0].get_connections_size())
	#print(dungeon.starting_room.connections[0].connections[0])
	#print(dungeon.starting_room.connections[0].connections[0].connections[0].bb)
	#print(dungeon.starting_room.connections[0].connections[0].connections[1].bb)
	#print(dungeon.starting_room.bb.intersects(dungeon.starting_room.connections[0].connections[0].connections[0].bb))
	#print(dungeon.starting_room.bb.intersects(dungeon.starting_room.connections[0].connections[0].connections[1].bb))

	
	@warning_ignore("return_value_discarded")
	draw.connect(draw_rooms.bind(dungeon))
	#draw.connect(func() -> void: draw_rect(Rect2i(Vector2i(-157, -274), Vector2i(116, 208)), Color.GREEN))

func draw_rooms(dungeon: Dungeon, room: Dungeon.Room = dungeon.starting_room) -> void:
	if room.depth == 0:
		draw_rect(dungeon.starting_room.bb, Color.PURPLE)
		draw_rect(dungeon.starting_room.bb, Color.BLACK, false)
		draw_circle(dungeon.starting_room.connection_point, 5, Color.BLACK)
		draw_string(ThemeDB.fallback_font, dungeon.starting_room.bb.position + Vector2i(3, ThemeDB.fallback_font_size), "0")


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
		draw_string(ThemeDB.fallback_font, r.bb.position + Vector2i(1, ThemeDB.fallback_font_size), str(r.depth))
		draw_circle(r.connection_point, 5, Color.BLACK)

	if room.depth == dungeon.max_depth:
		return
	else:
		draw_rooms(dungeon, main_room)
