class_name Dungeon extends RefCounted

class Room extends RefCounted:
	enum types {
		START,
		END,
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
	var length: int
	
	var connections: Array[int]
	
	@warning_ignore("shadowed_variable")
	func _init(starting_room: Room, main_branch: bool = false) -> void:
		self.starting_room = starting_room
		rooms.append(starting_room)
		
		self.main_branch = main_branch
		if main_branch:
			id = 0
		else:
			id = hash(self)


const MAX_BRANCHES = 4
const MAX_BRANCH_LENGTH = 5

const BRANCH_DECAY := 3.0 #higher values mean more branches end early
const SPLIT_3_WAYS := 0.35

var starting_room := Room.new(Room.types.START)
var ending_room := Room.new(Room.types.END)
var staring_branch := Branch.new(starting_room, true)
var current_branch := staring_branch
var branch_ids: Dictionary[int, Branch] = {
	staring_branch.id : staring_branch,
}

@warning_ignore("shadowed_global_identifier")
var seed: int
var rng := RandomNumberGenerator.new()
var tot_branches: int
var branch_length: int
var prev_room: Room = current_branch.rooms[-1]


#func _add_connection(from: Room, to: Room) -> Error:
	#if from.id not in connections:
		#connections[from.id] = []
	#
	#for room:Room in connections[from.id]:
		#if to.id == room.id:
			#return ERR_ALREADY_EXISTS
	#@warning_ignore("return_value_discarded")
	#connections[from.id].append(to)
	#
	#if to.id not in connections:
		#connections[to.id] = []
	#
	#return OK

func _merge_branches(dungeons: Array[Dungeon]) -> Dungeon:
	assert(dungeons.size() != 0)
	var final_dungeon := Dungeon.new(dungeons[0].seed, dungeons[0].tot_branches, dungeons[0].branch_length)
	
	for dungeon in dungeons:
		assert(dungeon.seed == final_dungeon.seed)
		assert(dungeon.tot_branches == final_dungeon.tot_branches)
		assert(dungeon.branch_length == final_dungeon.branch_length)
		print(dungeon.current_branch.rooms)
		final_dungeon.current_branch.connections.append(dungeon.current_branch.id)
		final_dungeon.branch_ids.merge(dungeon.branch_ids)
	
	return final_dungeon


#func _extend(current_room: Room) -> Error:
	#var err := _add_connection(_prev_room, current_room)
	#print(connections)
	#if err:
		#return err
	#
	#_prev_room = current_room
	#_depth_in_branch += 1
	#
	#return OK
#
#
#func _branch(num_branches: int) -> Array[Dungeon]:
	#var result: Array[Dungeon]
	#_branch_count += 1
	#_depth_in_branch = 0
	#_prev_split = _prev_room
	#
	#for i in range(num_branches):
		#var branch := _duplicate()
		#
		#branch._main_branch = false
		#
		#result.append(branch)
	#
	#return result


func _duplicate() -> Dungeon:
	var result := Dungeon.new(seed, tot_branches, branch_length)
	
	result.seed = seed
	result.tot_branches = tot_branches
	result.branch_length = branch_length
	result.prev_room = prev_room
	result.starting_room = starting_room
	result.ending_room = ending_room
	result.staring_branch = staring_branch
	result.current_branch = current_branch
	result.branch_ids = branch_ids
	
	return result


func _end_branch() -> Dungeon:
	
	var num_branches := branch_ids.size()
	if num_branches == tot_branches:
		if current_branch.main_branch:
			current_branch.rooms.append(ending_room)
			current_branch.ending_room = ending_room
			
			return self
		else:
			current_branch.rooms.append(Room.new(Room.types.NORMAL))
			
			return self
	else:
		if rng.randf() < SPLIT_3_WAYS:
			var split_room := Room.new(Room.types.SPLIT_3)
			
			current_branch.rooms.append(split_room)
			#print(current_branch.rooms)
			
			var branch_1 := _duplicate()
			branch_1.current_branch = Branch.new(prev_room)
			branch_ids[branch_1.current_branch.id] = branch_1.current_branch
			var branch_2 := _duplicate()
			branch_1.current_branch = Branch.new(prev_room)
			branch_ids[branch_2.current_branch.id] = branch_2.current_branch
			
			return _merge_branches([generate(self), generate(branch_1), generate(branch_2)])
		else:
			var split_room := Room.new(Room.types.SPLIT_2)
			
			current_branch.rooms.append(split_room)
			#print(current_branch.rooms)
			
			var branch_1 := _duplicate()
			branch_1.current_branch = Branch.new(prev_room)
			
			return _merge_branches([generate(self), generate(branch_1)])


@warning_ignore("shadowed_global_identifier")
static func generate(dungeon: Dungeon) -> Dungeon:
	var depth_in_branch: int = dungeon.current_branch.rooms.size()
	
	if depth_in_branch == dungeon.branch_length:
		return dungeon._end_branch()
	elif depth_in_branch >= 2:
		var decay_chance := 1-pow(BRANCH_DECAY, -float(depth_in_branch)/float(dungeon.branch_length))
		if dungeon.rng.randf() < decay_chance:
			return dungeon._end_branch()
		else:
			dungeon.current_branch.rooms.append(Room.new(Room.types.NORMAL))
			#print(dungeon.current_branch.rooms)
			
			return generate(dungeon)
	else:
		dungeon.current_branch.rooms.append(Room.new(Room.types.NORMAL))
		#print(dungeon.current_branch.rooms)
		
		return generate(dungeon)


#func _get_branches(room_id: int, prev_room_ids: Array[int] = [], branches: Array[Array] =  [[]]) -> Array[Array]:
	#if room_id in prev_room_ids:
		#branches.append(prev_room_ids)
		#return branches
	#else:
		#prev_room_ids.append(room_id)
		#for room in connections[room_id]:


@warning_ignore("shadowed_variable", "shadowed_global_identifier")
func _init(seed: int, tot_branches: int, branch_length: int) -> void:
	self.seed = seed
	rng.seed = seed
	self.tot_branches = tot_branches
	self.branch_length = branch_length


#func _to_string(room_id: int = starting_room.id, tabs: String = "\t") -> String:
	##print(starting_room)
	##print(connections[starting_room])
	#if connections[room_id].size() == 0:
		#return str(room_id)
	#elif connections[room_id].size() == 1:
		#@warning_ignore("unsafe_call_argument")
		#return str(room_id) + " -> " + _to_string(connections[room_id][0].id, tabs)
	#else:
		#var value := str(room_id)
		#for i in connections[room_id].size():
			#@warning_ignore("unsafe_call_argument")
			#value += "\n"+tabs+str(room_id)+" -> "+_to_string(connections[room_id][i].id, tabs+"\t")
		#return value
