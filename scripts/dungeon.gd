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
	
	var type: types
	var id: int
	var branch_id: int
	
	var bb: Rect2i #bounding box
	
	
	@warning_ignore("shadowed_variable")
	func _init(type: types) -> void:
		self.type = type
		
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


class Branch extends RefCounted:
	enum locations {
		LEFT,
		RIGHT,
		CENTER,
	}
	
	var rooms: Array[Room]
	var connections: Array[Branch]
	
	var id: int
	var is_main: bool
	var length: int
	var depth: int
	var location: locations
	
	var bb: Rect2i
	
	func is_deadend() -> bool:
		return is_main and connections.is_empty()
	
	
	func get_size() -> Vector2i:
		var tot := Vector2i.ZERO
		
		for room in rooms:
			tot += room.bb.size
		
		assert(tot.abs() == tot)
		return tot
	
	
	func get_connections_size() -> Vector2i:
		var connections_size := Vector2i.ZERO
		
		for branch in connections:
			var branch_size := branch.get_size()
			
			connections_size.x += branch_size.x
			
			connections_size.y = maxi(connections_size.y, branch_size.y)
		
		return connections_size
	
	
	@warning_ignore("shadowed_variable")
	func _init(starting_room: Room, length: int, depth: int = 0, is_main: bool = false) -> void:
		self.depth = depth
		
		assert(length > 0)
		self.length = length
		var err := rooms.resize(length) as Error
		assert(!err)
		
		for i in range(rooms.size()):
			rooms[i] = Room.new(Room.types.BLANK)
		rooms[0] = starting_room
		
		if depth == 0:
			rooms[0] = Room.new(Room.types.START)
		
		self.is_main = is_main
		if is_main and depth == 0:
			id = 0
		else:
			id = hash(self)
	
	
	func _to_string() -> String:
		var value := ""
		for room in rooms:
			value += str(room) + " → "
		
		value = value.substr(0, value.length()-3)
		
		if not is_deadend():
			match rooms[-1].type:
				Room.types.SPLIT_3:
					value += " ⇶ "
				Room.types.SPLIT_2:
					value += " ⇉ "
				_:
					value += " → "
			
			value += "↺"
		
		return value

#var decay_chance := 1-pow(BRANCH_DECAY, -float(depth_in_branch)/float(dungeon.branch_length))
#const BRANCH_DECAY := 3.0 #higher values mean more branches end early

const SPLIT_3_WAYS := 0.35

const MAX_BRANCH_DIFF := 3

var starting_branch: Branch

@warning_ignore("shadowed_global_identifier")
var seed: int
var rng := RandomNumberGenerator.new()
var max_depth: int
var max_branch_size: int


func _generate_blank_connecctions(branch: Branch) -> Branch:
	if branch.depth != max_depth and branch.is_main:
		var next_depth := branch.depth+1
		
		if rng.randf() < SPLIT_3_WAYS:
			var split := Room.new(Room.types.SPLIT_3)
			branch.rooms[-1] = split
			
			var next_main := rng.randf()
			
			var branch_1 := _generate_blank_connecctions(Branch.new(split, rng.randi_range(max_branch_size - MAX_BRANCH_DIFF, max_branch_size), next_depth, next_main < 0.3333333333 and branch.is_main))
			branch_1.rooms[0] = split
			branch.connections.append(branch_1)
			var branch_2 := _generate_blank_connecctions(Branch.new(split, rng.randi_range(max_branch_size - MAX_BRANCH_DIFF, max_branch_size), next_depth, next_main > 0.3333333333 and next_main < 0.666666666 and branch.is_main))
			branch_2.rooms[0] = split
			branch.connections.append(branch_2)
			var branch_3 := _generate_blank_connecctions(Branch.new(split, rng.randi_range(max_branch_size - MAX_BRANCH_DIFF, max_branch_size), next_depth, next_main > 0.6666666666 and branch.is_main))
			branch_3.rooms[0] = split
			branch.connections.append(branch_3)
		else:
			var split := Room.new(Room.types.SPLIT_2)
			branch.rooms[-1] = split
			
			var next_main := rng.randf()
			
			var branch_1 := _generate_blank_connecctions(Branch.new(split, rng.randi_range(max_branch_size - MAX_BRANCH_DIFF, max_branch_size), next_depth, next_main < 0.5 and branch.is_main))
			branch_1.rooms[0] = split
			branch.connections.append(branch_1)
			var branch_2 := _generate_blank_connecctions(Branch.new(split, rng.randi_range(max_branch_size - MAX_BRANCH_DIFF, max_branch_size), next_depth, next_main > 0.5 and branch.is_main))
			branch_2.rooms[0] = split
			branch.connections.append(branch_2)
		
		return branch
	else:
		if branch.is_main:
			branch.rooms[-1] = Room.new(Room.types.END)
		return branch


func first_pass(branch: Branch = starting_branch, room_index: int = 0) -> void:
	var current_type := branch.rooms[room_index].type
	
	match current_type:
		Room.types.BLANK:
			branch.rooms[room_index].type = Room.types.NORMAL
	
	@warning_ignore("narrowing_conversion")
	branch.rooms[room_index].bb = Rect2i(Vector2i.MAX, Vector2i(rng.randi_range(10, 12), rng.randi_range(10, 12)))
	
	if room_index == branch.length - 1:
		for b in branch.connections:
			first_pass(b, 0)
	else:
		first_pass(branch, room_index + 1)


@warning_ignore("integer_division")
func place_branches(branch: Branch = starting_branch, prev_branches: Array[Branch] = [], last_split_point: Vector2i = Vector2i.MAX) -> Array[Branch]:
	assert(branch.is_main)
	
	var alloc_branches := func(bb: Rect2i, main_side: bool) -> void:
		var horizontal := absi(bb.position.x - bb.end.x) > absi(bb.position.y - bb.end.y)
		
		var num_connections := branch.connections.size()
		
		var main_branch: Branch
		
		for i in range(num_connections):
			var cur_branch := branch.connections[i]
			var cur_branch_size := cur_branch.get_size()
			
			if horizontal:
				cur_branch.bb = Rect2i(bb.position, Vector2i(cur_branch_size.x, branch.get_connections_size().y))
				
				for j in range(i):
					var prev_branch_size := branch.connections[j].get_size()
					cur_branch.bb.position.x += prev_branch_size.x
			else:
				cur_branch.bb = Rect2i(bb.position, Vector2i(branch.get_connections_size().y, cur_branch_size.y))
				
				for j in range(i):
					var prev_branch_size := branch.connections[j].get_size()
					cur_branch.bb.position.y += prev_branch_size.y
			
			var buffer_amount := absi(bb.size.y - cur_branch_size.y) if horizontal else absi(bb.size.x - cur_branch_size.x)
			print(branch.depth," ; ", buffer_amount)
			
			if cur_branch.is_main:
				main_branch = cur_branch
			
			assert(i == 0 or (cur_branch.bb.position.y == branch.connections[i - 1].bb.position.y and horizontal) or(cur_branch.bb.position.x == branch.connections[i - 1].bb.position.x and not horizontal) )
			
			prev_branches.append(cur_branch)
		
		
		if branch.depth < max_depth and branch.depth < 10:
			@warning_ignore("integer_division")
			var center := Vector2i(bb.position.x / 2, bb.position.y) if horizontal else Vector2i(bb.position.x, bb.position.y / 2)
			if not main_side and horizontal:
				center += Vector2i(bb.size.x, 0)
			elif not main_side and not horizontal:
				center += Vector2i(0, bb.size.y)
			
			prev_branches.append_array(place_branches(main_branch, prev_branches, center))
	
	if branch.depth == 0:
		assert(branch == starting_branch)
		var width := 0
		var height := 0
		
		for room in starting_branch.rooms:
			var size := room.bb.size
			
			width = maxi(size.x, width)
			height += size.y
		
		var start_bb := Rect2i(0, 0, width, height)
		start_bb = start_bb.grow_side(SIDE_BOTTOM, 10)
		
		starting_branch.bb = start_bb
		prev_branches.append(starting_branch)
		
		var last_room_type := branch.rooms[-1].type
		
		match last_room_type:
			Room.types.SPLIT_2:
				var branch_1_size := branch.connections[0].get_size()
				@warning_ignore("integer_division")
				alloc_branches.call(Rect2i(Vector2i((start_bb.size.x / 2) - branch_1_size.x, start_bb.end.y), branch.get_connections_size()), true)
			Room.types.SPLIT_3:
				var branch_1_size := branch.connections[0].get_size()
				var branch_2_size := branch.connections[1].get_size()
				@warning_ignore("integer_division")
				alloc_branches.call(Rect2i(Vector2i((start_bb.size.x / 2) - branch_1_size.x - (branch_2_size.x / 2), start_bb.end.y), branch.get_connections_size()), true)
			_:
				assert(false, "last room is not a split")
		
		return prev_branches
	
	var connections_size := branch.get_connections_size()
	var connections_bb := Rect2i(Vector2i.MAX, connections_size)
	var check_interections := func(rect: Rect2i) -> bool:
		for b in prev_branches:
			if rect.intersects(b.bb):
				return false
			
		return true
	
	var top_left := branch.bb.position
	var top_right := branch.bb.position + Vector2i(branch.bb.size.x, 0)
	var bot_left := branch.bb.position + Vector2i(0, branch.bb.size.y)
	var bot_right := branch.bb.end
	
	# in order to able to be accesesed by @GlobalScope.Corner
	var corners: Array[Vector2i] = [top_left, top_right, bot_right, bot_left]
	
	var dists_to_cent := corners.map(func(corner: Vector2i) -> int: return corner.distance_squared_to(Vector2i.ZERO))
	
	var sorted_dists_to_cent := dists_to_cent
	sorted_dists_to_cent.sort()
		
	for i in range(4):
		if connections_bb.position != Vector2i.MAX:
			break
		
		var min_dist_to_cent: int = sorted_dists_to_cent[i]
		var closest_to_cent_idx := dists_to_cent.find(min_dist_to_cent)
		var closest_to_cent := corners[closest_to_cent_idx]
		var sec_min_dist_to_cent: int = sorted_dists_to_cent[wrapi(i+1, 0, 4)]
		var sec_closest_to_cent_idx := dists_to_cent.find(sec_min_dist_to_cent)
		var sec_closest_to_cent := corners[sec_closest_to_cent_idx]
		
		var closest_to_last := closest_to_cent if closest_to_cent.distance_squared_to(last_split_point) < sec_closest_to_cent.distance_squared_to(last_split_point) else sec_closest_to_cent
		var closest_to_last_idx := closest_to_cent_idx if closest_to_last == closest_to_cent else sec_closest_to_cent_idx
		var sec_closest_to_last := sec_closest_to_cent if closest_to_cent == closest_to_last else closest_to_cent
		var sec_closest_to_last_idx := sec_closest_to_cent_idx if sec_closest_to_last == sec_closest_to_cent else closest_to_cent_idx
		
		if closest_to_cent.x == sec_closest_to_cent.x:
			
			@warning_ignore("confusable_local_declaration")
			var temp := connections_bb.size.x
			connections_bb.size.x = connections_bb.size.y
			connections_bb.size.y = temp
			connections_size = connections_bb.size
			
			var flow_dir := signi(sec_closest_to_last.y - closest_to_last.y)
			assert(flow_dir != 0)
			
			@warning_ignore("integer_division")
			var y_min := closest_to_last.y - (connections_size.y/2) 
			@warning_ignore("integer_division")
			var y_max := sec_closest_to_last.y - (connections_size.y/2)
			var main_side := closest_to_last_idx == CORNER_TOP_LEFT or closest_to_last_idx == CORNER_BOTTOM_LEFT
			var x_offset := connections_size.x if main_side else 0
			var x := closest_to_last.x + x_offset
			
			@warning_ignore("integer_division")
			for y in range(y_min, y_max, flow_dir):
				connections_bb.position = Vector2i(x, y)
				if check_interections.call(connections_bb):
					#var test_branch := Branch.new(Room.new(Room.types.BLANK), 1, 0, true)
					#test_branch.bb = connections_bb
					#prev_branches.append(test_branch)
					#
					#if branch.depth == 2:
						#continue
					alloc_branches.call(connections_bb, not main_side)
					print("placed: "+str(branch.id))
					break
				else:
					connections_bb.position = Vector2i.MAX
			temp = connections_bb.size.x
			connections_bb.size.x = connections_bb.size.y
			connections_bb.size.y = temp
			connections_size = connections_bb.size
		elif closest_to_cent.y == sec_closest_to_cent.y:
			var flow_dir := signi(sec_closest_to_last.x - closest_to_last.x)
			assert(flow_dir != 0)
			
			@warning_ignore("integer_division")
			var x_min := closest_to_last.x - (connections_size.x/2) 
			@warning_ignore("integer_division")
			var x_max := sec_closest_to_last.x - (connections_size.x/2)
			var main_side := (closest_to_last_idx == CORNER_TOP_LEFT and sec_closest_to_last_idx == CORNER_TOP_RIGHT) or (closest_to_last_idx == CORNER_TOP_RIGHT and sec_closest_to_last_idx == CORNER_TOP_LEFT)
			var y_offset := connections_size.y if main_side else 0
			var y := closest_to_last.y - y_offset
			
			@warning_ignore("integer_division")
			for x in range(x_min, x_max, flow_dir):
				@warning_ignore("integer_division")
				connections_bb.position = Vector2i(x, y)
				if check_interections.call(connections_bb):
					#var test_branch := Branch.new(Room.new(Room.types.BLANK), 1, 0, true)
					#test_branch.bb = connections_bb
					#prev_branches.append(test_branch)
					print("placed: "+str(branch.id))
					#if branch.depth == 2:
						#continue
					alloc_branches.call(connections_bb, not main_side)
					
					break
				else:
					connections_bb.position = Vector2i.MAX
		else:
			assert(false, "missalinged side endpoints")
	#assert(connections_bb.position != Vector2i.MAX)
	
	return prev_branches


@warning_ignore("shadowed_variable", "shadowed_global_identifier")
func _init(seed: int, max_depth: int, max_branch_size: int) -> void:
	assert(max_branch_size - MAX_BRANCH_DIFF > 1, "your branches are too small")
	
	print("seed: ",seed)
	self.seed = seed
	rng.seed = seed
	self.max_depth = max_depth
	self.max_branch_size = max_branch_size
	
	var starting_room := Room.new(Room.types.START)
	var branch := Branch.new(starting_room, rng.randi_range(max_branch_size - MAX_BRANCH_DIFF, max_branch_size), 0, true)
	
	starting_branch = _generate_blank_connecctions(branch)


func _to_string(branch: Branch = starting_branch) -> String:
	var value := ""
	
	if branch.depth == 0:
		assert(branch == starting_branch)
		value = str(branch) + "\n"
	
	for b in branch.connections:
		for i in range(branch.depth+1):
			value += "\t"
		value += str(b)+"\n" + _to_string(b)
	
	return value
