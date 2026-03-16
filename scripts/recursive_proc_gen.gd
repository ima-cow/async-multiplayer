extends Node2D


func _ready() -> void:
	#3489947376 - failing
	#1437557178
	#3078261895 - fails
	var dungeon := Dungeon.new(0, 10)
	dungeon.first_pass()
	
	#print(dungeon)
	
	var branches_placed := dungeon.place_rooms()
	
	assert(branches_placed)
	
	#print(dungeon.starting_branch.connections[0].bb)
	
	@warning_ignore("return_value_discarded")
	draw.connect(draw_rooms.bind(dungeon))

func draw_rooms(dungeon: Dungeon, room: Dungeon.Room = dungeon.starting_room) -> void:
	if room.depth == 0:
		draw_rect(dungeon.starting_room.bb, Color.PURPLE)
		draw_rect(dungeon.starting_room.bb, Color.BLACK, false)
		draw_circle(dungeon.starting_room.connection_point, 5, Color.BLACK)
		draw_string(ThemeDB.fallback_font, dungeon.starting_room.bb.position, "0")
	
	var main_room: Dungeon.Room
	
	for r in room.connections:
		#print(r.bb);
		if r.is_main:
			draw_rect(r.bb, Color.RED)
			main_room = r
		else:
			draw_rect(r.bb, Color.BLUE)
		draw_string(ThemeDB.fallback_font, r.bb.position, str(r.depth))
		draw_rect(r.bb, Color.BLACK, false)
		draw_circle(r.connection_point, 5, Color.BLACK)
	
	#print(main_branch.id)
	if room.depth == dungeon.max_depth - 1:
		return
	else:
		draw_rooms(dungeon, main_room)
