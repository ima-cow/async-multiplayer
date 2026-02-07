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
	var rooms: Array[Room]
	
	var id: int
	var is_main: bool
	var length: int
	var depth: int
	
	var connections: Array[Branch]
	
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

const MAX_BRANCH_DIFFERENCE := 3

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
			
			var branch_1 := _generate_blank_connecctions(Branch.new(split, rng.randi_range(max_branch_size - MAX_BRANCH_DIFFERENCE, max_branch_size), next_depth, next_main < 0.3333333333 and branch.is_main))
			branch_1.rooms[0] = split
			branch.connections.append(branch_1)
			var branch_2 := _generate_blank_connecctions(Branch.new(split, rng.randi_range(max_branch_size - MAX_BRANCH_DIFFERENCE, max_branch_size), next_depth, next_main > 0.3333333333 and next_main < 0.666666666 and branch.is_main))
			branch_2.rooms[0] = split
			branch.connections.append(branch_2)
			var branch_3 := _generate_blank_connecctions(Branch.new(split, rng.randi_range(max_branch_size - MAX_BRANCH_DIFFERENCE, max_branch_size), next_depth, next_main > 0.6666666666 and branch.is_main))
			branch_3.rooms[0] = split
			branch.connections.append(branch_3)
		else:
			var split := Room.new(Room.types.SPLIT_2)
			branch.rooms[-1] = split
			
			var next_main := rng.randf()
			
			var branch_1 := _generate_blank_connecctions(Branch.new(split, rng.randi_range(max_branch_size - MAX_BRANCH_DIFFERENCE, max_branch_size), next_depth, next_main < 0.5 and branch.is_main))
			branch_1.rooms[0] = split
			branch.connections.append(branch_1)
			var branch_2 := _generate_blank_connecctions(Branch.new(split, rng.randi_range(max_branch_size - MAX_BRANCH_DIFFERENCE, max_branch_size), next_depth, next_main > 0.5 and branch.is_main))
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
	branch.rooms[room_index].bb = Rect2i(INF, INF, rng.randi_range(10, 12), rng.randi_range(10, 12))
	
	if room_index == branch.length - 1:
		for b in branch.connections:
			first_pass(b, 0)
	else:
		first_pass(branch, room_index + 1)


func alloc_branches(branch: Branch = starting_branch) -> Array[Rect2i]:
	var result: Array[Rect2i]
	
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
		result.append(start_bb)
		
		var last_room_type := starting_branch.rooms[-1].type
		match last_room_type:
			Room.types.SPLIT_2:
				assert(branch.connections.size() == 2)
				var branch_1 := starting_branch.connections[0]
				@warning_ignore("integer_division")
				var branch_1_bb := Rect2i(Vector2i(start_bb.size.x/2, start_bb.end.y), branch_1.get_size())
				if branch_1.is_main:
					branch_1_bb = branch_1_bb.grow_side(SIDE_BOTTOM, 10)
					result.append_array(alloc_branches(branch_1))
				branch_1.bb = branch_1_bb
				result.append(branch_1_bb)
				
				var branch_2 := starting_branch.connections[1]
				var branch_2_size := branch_2.get_size()
				@warning_ignore("integer_division")
				var branch_2_bb := Rect2i(Vector2i((start_bb.size.x/2) - (branch_2_size.x), start_bb.end.y), branch_2_size)
				if branch_2.is_main:
					branch_1_bb = branch_1_bb.grow_side(SIDE_BOTTOM, 10)
					result.append_array(alloc_branches(branch_2))
				branch_2.bb = branch_2_bb
				result.append(branch_2_bb)
			Room.types.SPLIT_3:
				assert(branch.connections.size() == 3)
				var branch_1 := starting_branch.connections[0]
				var branch_1_size := branch_1.get_size()
				@warning_ignore("integer_division")
				var branch_1_bb := Rect2i(Vector2i((start_bb.size.x/2) - (branch_1_size.x/2), start_bb.end.y), branch_1_size)
				if branch_1.is_main:
					branch_1_bb = branch_1_bb.grow_side(SIDE_BOTTOM, 10)
					result.append_array(alloc_branches(branch_1))
				branch_1.bb = branch_1_bb
				result.append(branch_1_bb)
				
				var branch_2 := starting_branch.connections[1]
				var branch_2_size := branch_2.get_size()
				@warning_ignore("integer_division")
				var branch_2_bb := Rect2i(Vector2i((start_bb.size.x/2) - (branch_1_size.x/2) - branch_2_size.x, start_bb.end.y), branch_2_size)
				if branch_2.is_main:
					branch_1_bb = branch_1_bb.grow_side(SIDE_BOTTOM, 10)
					result.append_array(alloc_branches(branch_2))
				branch_2.bb = branch_2_bb
				result.append(branch_2_bb)
				
				var branch_3 := starting_branch.connections[2]
				var branch_3_size := branch_3.get_size()
				@warning_ignore("integer_division")
				var branch_3_bb := Rect2i(Vector2i((start_bb.size.x/2) + (branch_1_size.x/2), start_bb.end.y), branch_3_size)
				if branch_3.is_main:
					branch_3_bb = branch_3_bb.grow_side(SIDE_BOTTOM, 10)
					result.append_array(alloc_branches(branch_3))
				branch_3.bb = branch_3_bb
				result.append(branch_3_bb)
			_:
				assert(false, "last room on starting branch is not a split")
		
		return result
	
	
	
	return result


@warning_ignore("shadowed_variable", "shadowed_global_identifier")
func _init(seed: int, max_depth: int, max_branch_size: int) -> void:
	assert(max_branch_size - MAX_BRANCH_DIFFERENCE > 1, "your branches are too small")
	
	self.seed = seed
	rng.seed = seed
	self.max_depth = max_depth
	self.max_branch_size = max_branch_size
	
	var starting_room := Room.new(Room.types.START)
	var branch := Branch.new(starting_room, rng.randi_range(max_branch_size - MAX_BRANCH_DIFFERENCE, max_branch_size), 0, true)
	
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
