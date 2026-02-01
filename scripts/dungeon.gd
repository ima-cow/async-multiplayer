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
	
	var rect: Rect2i
	
	
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


class Branch extends RefCounted:
	var starting_room: Room
	var ending_room: Room = null
	var rooms: Array[Room]
	
	var id: int
	var main_branch: bool
	var size: int
	var depth: int
	
	var connections: Array[Branch]
	
	
	func is_dead_end() -> bool:
		return ending_room == null
	
	
	@warning_ignore("shadowed_variable")
	func _init(size: int, depth: int = 0, main_branch: bool = false) -> void:
		self.depth = depth
		
		self.size = size
		var err := rooms.resize(size) as Error
		assert(!err)
		
		rooms.fill(Room.new(Room.types.BLANK))
		if depth == 0:
			rooms[0] = Room.new(Room.types.START)
			starting_room = rooms[0]
		
		self.main_branch = main_branch
		if main_branch:
			id = 0
		else:
			id = hash(self)

#var decay_chance := 1-pow(BRANCH_DECAY, -float(depth_in_branch)/float(dungeon.branch_length))

const BRANCH_DECAY := 3.0 #higher values mean more branches end early
const SPLIT_3_WAYS := 0.35

var starting_branch: Branch
var starting_room: Room
var ending_room := Room.new(Room.types.END)
#var branch_ids: Dictionary[int, Branch] = {
	#staring_branch.id : staring_branch,
#}

@warning_ignore("shadowed_global_identifier")
var seed: int
var rng := RandomNumberGenerator.new()
var tot_branches: int
var max_branch_size: int


func _generate_blank_connecctions(branch: Branch) -> Branch:
	if branch.depth != tot_branches:
		var next_depth := branch.depth+1
		
		#var become_main := rng.randf() < 0.5
		
		if rng.randf() < SPLIT_3_WAYS:
			var branch_1 := _generate_blank_connecctions(Branch.new(rng.randi_range(max_branch_size - 3, max_branch_size), next_depth))
			branch.connections.append(branch_1)
			var branch_2 := _generate_blank_connecctions(Branch.new(rng.randi_range(max_branch_size - 3, max_branch_size), next_depth))
			branch.connections.append(branch_2)
			var branch_3 := _generate_blank_connecctions(Branch.new(rng.randi_range(max_branch_size - 3, max_branch_size), next_depth))
			branch.connections.append(branch_3)
		else:
			var branch_1 := _generate_blank_connecctions(Branch.new(rng.randi_range(max_branch_size - 3, max_branch_size), next_depth))
			branch.connections.append(branch_1)
			var branch_2 := _generate_blank_connecctions(Branch.new(rng.randi_range(max_branch_size - 3, max_branch_size), next_depth))
			branch.connections.append(branch_2)
	
	return branch



@warning_ignore("shadowed_variable", "shadowed_global_identifier")
func _init(seed: int, tot_branches: int, max_branch_size: int) -> void:
	assert(max_branch_size > 3)
	
	self.seed = seed
	rng.seed = seed
	self.tot_branches = tot_branches
	self.max_branch_size = max_branch_size
	
	var branch := Branch.new(rng.randi_range(max_branch_size - 3, max_branch_size), true)
	branch.rooms[0] = Room.new(Room.types.START)
	
	starting_branch = _generate_blank_connecctions(branch)
	starting_room = starting_branch.starting_room


func _to_string(branch: Branch = starting_branch, value: String = "") -> String:
	print(branch.depth)
	for i in range(branch.depth):
		value += "\t"
	
	value += str(branch.rooms)+"\n"
	if branch.depth == tot_branches:
		return value
	else:
		for b in branch.connections:
			value += _to_string(b, value)
		return value
