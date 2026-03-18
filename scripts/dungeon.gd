class_name Dungeon extends RefCounted

class Room extends RefCounted:
	enum types {
		START,
		END,
		BLANK,
		NORMAL,
		SPLIT_2,
		SPLIT_3,
	}
	
	var connections: Array[Room]
	
	var type: types
	var id: int
	var is_main: bool
	var next_main_idx: int
	var depth: int
	
	var bb: Rect2i #bounding box
	var connection_point := Vector2i.MAX
	
	
	func get_connections_size(horizontal: bool) -> Vector2i:
		var connections_size := Vector2i.ZERO
		
		if horizontal:
			for room in connections:
				var room_size := room.bb.size
				
				connections_size.x += room_size.x
				
				connections_size.y = maxi(connections_size.y, room_size.y)
		else:
			for room in connections:
				var room_size := room.bb.size
				
				connections_size.x = maxi(connections_size.x, room_size.x)
				
				connections_size.y += room_size.y
		
		return connections_size
	
	
	func place_connections(connections_bb: Rect2i) -> Array[Room]:
		var result: Array[Room]
		
		if connections.size() == 1:
			connections[0].bb = connections_bb
			return [connections[0]]
		
		var is_horizontal := absi(connections_bb.position.x - connections_bb.end.x) > absi(connections_bb.position.y - connections_bb.end.y)
		var num_connections := connections.size()
		
		for i in range(num_connections):
			var cur_room := connections[i]
			
			var cur_room_size := cur_room.bb.size
			
			if is_horizontal:
				cur_room.bb = Rect2i(connections_bb.position, Vector2i(cur_room_size.x, connections_bb.size.y))
				
				for j in range(i):
					var prev_room_size := connections[j].bb.size
					cur_room.bb.position.x += prev_room_size.x
			else:
				cur_room.bb = Rect2i(connections_bb.position, Vector2i(connections_bb.size.x, cur_room_size.y))
				
				for j in range(i):
					var prev_room_size := connections[j].bb.size
					cur_room.bb.position.y += prev_room_size.y
			
			assert(i == 0 or (cur_room.bb.position.y == connections[i - 1].bb.position.y and is_horizontal) or(cur_room.bb.position.x == connections[i - 1].bb.position.x and not is_horizontal) )
			
			result.append(cur_room)
		
		return result
	
	
	@warning_ignore("shadowed_variable")
	func _init(type: types, depth: int, is_main: bool, next_main_idx: int = 0) -> void:
		self.type = type
		self.depth = depth
		self.is_main = is_main
		self.next_main_idx = next_main_idx
		
		match type:
			types.START:
				id = 0
			types.END:
				id = -1
			_:
				id = hash(self)
	
	func _to_string() -> String:
		match type:
			types.START:
				return "start:"+str(id)
			types.END:
				return "end:"+str(id)
			types.BLANK:
				return "blank:"+str(id)
			types.NORMAL:
				return "normal:"+str(id)
			types.SPLIT_2:
				return "split_2:"+str(id)
			types.SPLIT_3:
				return "split_3:"+str(id)
			_:
				assert(false, "not a valid room type")
				return ""


const SPLIT_3_WAYS := 0.35
const MAX_BRANCH_SIZE := 8.0
const MAX_BRANCH_DIFF := 3
const BRANCH_DECAY := 3.0 #higher values mean more branches end early

var starting_room: Room

@warning_ignore("shadowed_global_identifier")
var seed: int
var rng := RandomNumberGenerator.new()
var max_depth: int


func _gen_blank_connecctions(room: Room, depth_in_branch: int = 0, overall_depth: int = 0) -> Room:
	assert(room.is_main)
	
	if overall_depth == max_depth:
		room.type = Room.types.END
		return room
	
	var split_chance := 1 - pow(BRANCH_DECAY, -depth_in_branch / MAX_BRANCH_SIZE)
	var num_new_branches := 1
	
	if room.is_main and rng.randf() < split_chance:
		num_new_branches = 2
		depth_in_branch = 0
	else:
		depth_in_branch += 1
	
	overall_depth += 1
	
	var err := room.connections.resize(num_new_branches)
	assert(!err)
	
	if num_new_branches == 2:
		room.type = Room.types.SPLIT_2
	elif num_new_branches == 3:
		room.type = Room.types.SPLIT_3
	
	room.next_main_idx = rng.randi_range(0, num_new_branches - 1)
	
	for i in range(num_new_branches):
		var next_room: Room
		if room.next_main_idx == i:
			var next_next_room := Room.new(Room.types.BLANK, overall_depth, true)
			next_room = _gen_blank_connecctions(next_next_room, depth_in_branch, overall_depth)
		else:
			next_room = Room.new(Room.types.BLANK, overall_depth, false)
		
		room.connections[i] = next_room
	
	return room

func first_pass(room: Room = starting_room) -> void:
	match room.type:
		Room.types.BLANK:
			room.type = Room.types.NORMAL
			room.bb = Rect2i(Vector2i.MAX, Vector2i(rng.randi_range(100, 120), rng.randi_range(100, 120)))
		Room.types.START:
			room.bb = Rect2i(Vector2i.ZERO, Vector2i(rng.randi_range(100, 120), rng.randi_range(100, 120)))
		Room.types.END, Room.types.SPLIT_2, Room.types.SPLIT_3:
			room.bb = Rect2i(Vector2i.MAX, Vector2i(rng.randi_range(100, 120), rng.randi_range(100, 120)))
		_:
			assert(false, "invalid room type")
	
	@warning_ignore("narrowing_conversion")
	
	var num_connections := room.connections.size()
	
	for i in range(num_connections):
		var next_room := room.connections[i]
		first_pass(next_room)


class Edge extends RefCounted:
	var end_1: Vector2i
	var end_2: Vector2i
	
	var side: Side
	
	func dist_to_zero() -> int:
		@warning_ignore("narrowing_conversion")
		return ((end_1 + end_2) / 2.0).distance_squared_to(Vector2i.ZERO)
	
	func _to_string() -> String:
		var value := ""
		
		match side:
			SIDE_LEFT:
				value += "Left: "
			SIDE_TOP:
				value += "Top: "
			SIDE_RIGHT:
				value += "Right: "
			SIDE_BOTTOM:
				value += "Bottom: "
		
		value += str(end_1) + " " + str(end_2) + " " + str(dist_to_zero())
		
		return value
	
	@warning_ignore("shadowed_variable")
	func _init(end_1: Vector2i, end_2: Vector2i, side: Side) -> void:
		self.end_1 = end_1
		self.end_2 = end_2
		self.side = side


func _check_interections(target: Rect2i, rooms: Array[Room]) -> bool:
		for room in rooms:
			if target.intersects(room.bb):
				return false
			
		return true


@warning_ignore("integer_division")
func place_rooms(room: Room = starting_room, prev_rooms: Array[Room] = [starting_room]) -> bool:
	assert(room.is_main)
	
	if room.depth == max_depth:
		return true
	
	
	if room.depth == 0:
		assert(room == starting_room)
		
		starting_room.bb.position = Vector2i.ZERO
	
	var top_left := room.bb.position
	var top_right := room.bb.position + Vector2i(room.bb.size.x, 0)
	var bot_left := room.bb.position + Vector2i(0, room.bb.size.y)
	var bot_right := room.bb.end
	
	var left_side := Edge.new(top_left, bot_left, SIDE_LEFT)
	var top_side := Edge.new(top_left, top_right, SIDE_TOP)
	var right_side := Edge.new(top_right, bot_right, SIDE_RIGHT)
	var bot_side := Edge.new(bot_left, bot_right, SIDE_BOTTOM)
	
	# in order to be acessed by @GlobalScope.Side
	var sides: Array[Edge] = [left_side, top_side, right_side, bot_side]
	
	var sorted_sides := sides.duplicate()
	# actually sorts in reverse order so we can pop_back
	sorted_sides.sort_custom(func(a: Edge, b: Edge) -> bool: return a.dist_to_zero() > b.dist_to_zero())
	
	var room_placed := false
	while not room_placed and sorted_sides.size() > 0:
		var closest_to_cent: Edge = sorted_sides.pop_back()
		
		var end_1_closer := closest_to_cent.end_1.distance_squared_to(Vector2i.ZERO) < closest_to_cent.end_2.distance_squared_to(Vector2i.ZERO)
		var closest_end := closest_to_cent.end_1 if end_1_closer else closest_to_cent.end_2
		var sec_closest_end := closest_to_cent.end_2 if end_1_closer else closest_to_cent.end_1
		
		const BUFFER_SPACE := 10
		const CENTER_INDEX := 1
		var closest_side := closest_to_cent.side
		match closest_side:
			SIDE_TOP, SIDE_BOTTOM:
				var connections_size := room.get_connections_size(true)
				var connections_bb := Rect2i(Vector2i.MAX, connections_size)
				
				var flow_dir := signi(sec_closest_end.x - closest_end.x)
				assert(flow_dir != 0)
				
				var x_offset := 0
				if room.connections.size() > 2 and room.next_main_idx != CENTER_INDEX:
					x_offset = room.connections[1].bb.size.x
					
					const RIGHT_INDEX := 2 
					if room.next_main_idx == RIGHT_INDEX:
						x_offset *= -1
				
				@warning_ignore("integer_division")
				var x_min := closest_end.x - (connections_size.x / 2) + x_offset
				@warning_ignore("integer_division")
				var x_max := sec_closest_end.x - (connections_size.x / 2) + x_offset
				
				var main_side := closest_side == SIDE_TOP
				var y_offset := connections_size.y if main_side else 0
				var y := closest_end.y - y_offset
				
				for x in range(x_min + (BUFFER_SPACE * flow_dir), x_max - (BUFFER_SPACE * flow_dir), flow_dir):
					connections_bb.position = Vector2i(x, y)
					
					if _check_interections(connections_bb, prev_rooms):
						#if room.depth == 17:
							#p
						var test := room.place_connections(connections_bb)
						prev_rooms.append_array(test)
						
						var main_room := room.connections[room.next_main_idx]
						room_placed = place_rooms(main_room, prev_rooms)
						if room_placed:
							@warning_ignore("integer_division")
							var unoffset_x := x + (connections_size.x / 2) - x_offset
							var unoffset_y := y + y_offset
							
							var connection_point := Vector2i(unoffset_x, unoffset_y)
							room.connection_point = connection_point
							
							break
					
					connections_bb.position = Vector2i.MAX
			SIDE_LEFT, SIDE_RIGHT:
				var connections_size := room.get_connections_size(false)
				var connections_bb := Rect2i(Vector2i.MAX, connections_size)
				
				var flow_dir := signi(sec_closest_end.y - closest_end.y)
				assert(flow_dir != 0)
				
				var y_offset := 0
				if room.connections.size() > 2 and room.next_main_idx != CENTER_INDEX:
					y_offset = room.connections[1].bb.size.y
					
					const LEFT_INDEX := 0
					if room.next_main_idx == LEFT_INDEX:
						y_offset *= -1
				
				@warning_ignore("integer_division")
				var y_min := closest_end.y - (connections_size.y / 2) - y_offset
				@warning_ignore("integer_division")
				var y_max := sec_closest_end.y - (connections_size.y / 2) - y_offset
				
				var main_side := closest_side == SIDE_LEFT
				var x_offset := connections_size.x if main_side else 0
				var x := closest_end.x - x_offset
				
				for y in range(y_min + (BUFFER_SPACE * flow_dir), y_max - (BUFFER_SPACE * flow_dir), flow_dir):
					connections_bb.position = Vector2i(x, y)
					
					if _check_interections(connections_bb, prev_rooms):
						var test := room.place_connections(connections_bb)
						prev_rooms.append_array(test)
						
						var main_room := room.connections[room.next_main_idx]
						room_placed = place_rooms(main_room, prev_rooms)
						if room_placed:
							var unoffset_x := x + x_offset
							@warning_ignore("integer_division")
							var unoffset_y := y + (connections_size.y / 2) + y_offset
							
							var connection_point := Vector2i(unoffset_x, unoffset_y)
							room.connection_point = connection_point
							
							break
					
					connections_bb.position = Vector2i.MAX
	
	return room_placed


@warning_ignore("shadowed_variable", "shadowed_global_identifier")
func _init(seed: int, max_depth: int) -> void:	
	print("seed: ",seed)
	self.seed = seed
	rng.seed = seed
	self.max_depth = max_depth
	
	var room := Room.new(Room.types.START, 0, true)
	
	starting_room = _gen_blank_connecctions(room)


func _to_string(room: Room = starting_room) -> String:
	var value := ""
	
	if room.depth == 0:
		assert(room == starting_room)
		value = str(room) + "\n"
	
	for r in room.connections:
		for i in range(room.depth+1):
			value += "\t"
		value += str(r)  +" "+str(r.depth) + "\n" + _to_string(r)
	
	return value
