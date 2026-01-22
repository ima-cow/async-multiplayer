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
	var name: String
	var id: int
	
	@warning_ignore("shadowed_variable")
	func _init(type: types, name: String) -> void:
		self.type = type
		self.name = name
		
		if type == types.START:
			id = 0
		elif type == types.END:
			id = -1
		else:
			id = hash(self)


const _MAX_BRANCHES = 4
const _MAX_BRANCH_LENGTH = 5

const BRANCH_DECAY := 3.0 #higher values mean more branches end early
const SPLIT_3_WAYS := 0.35

@warning_ignore("shadowed_global_identifier")
var seed: int
var _rng := RandomNumberGenerator.new()
var tot_branches: int
var branch_length: int
var _prev_room: Room = starting_room
var _main_branch: bool = true
var _branch_count: int = 0
var _depth_in_branch: int = 0
var _prev_split: Room = null

var starting_room := Room.new(Room.types.START, "start")
var ending_room := Room.new(Room.types.END, "end")
var connections: Dictionary[int, Array] = {
}

func _add_connection(from: Room, to: Room) -> Error:
	if from.id not in connections:
		connections[from.id] = []
	
	for room:Room in connections[from.id]:
		if to.id == room.id:
			return ERR_ALREADY_EXISTS
	@warning_ignore("return_value_discarded")
	connections[from.id].append(to)
	
	if to.id not in connections:
		connections[to.id] = []
	
	return OK

static func _merge_connections(dungeons: Array[Dungeon]) -> Dungeon:
	assert(dungeons.size() != 0)
	var final_dungeon := Dungeon.new(dungeons[0].seed, dungeons[0].tot_branches, dungeons[0].branch_length)
	
	for dungeon in dungeons:
		assert(dungeon.seed == final_dungeon.seed)
		assert(dungeon.tot_branches == final_dungeon.tot_branches)
		assert(dungeon.branch_length == final_dungeon.branch_length)
		final_dungeon.connections.merge(dungeon.connections)
	
	return final_dungeon


func _extend(current_room: Room) -> Error:
	var err := _add_connection(_prev_room, current_room)
	#print(connections)
	if err:
		return err
	
	_prev_room = current_room
	_depth_in_branch += 1
	
	return OK


func _branch(num_branches: int) -> Array[Dungeon]:
	var result: Array[Dungeon]
	#print(_depth_in_branch)
	_branch_count += 1
	_depth_in_branch = 0
	_prev_split = _prev_room
	
	for i in range(num_branches):
		var branch := _duplicate()
		
		branch._main_branch = false
		
		result.append(branch)
	
	return result


func _duplicate() -> Dungeon:
	var result := Dungeon.new(seed, tot_branches, branch_length, _prev_room, _main_branch, _branch_count, _depth_in_branch, _prev_split)
	
	result.connections = connections
	result.starting_room = starting_room
	result.ending_room = ending_room
	
	return result


func _end_branch() -> Dungeon:
	var err: Error
	
	if _branch_count == tot_branches:
		if _main_branch:
			err = _add_connection(_prev_room, ending_room)
			assert(!err)
			
			return self
		else:
			err = _add_connection(_prev_room, Room.new(Room.types.NORMAL, "room"))
			assert(!err)
			
			return self
	else:
		if _rng.randf() < SPLIT_3_WAYS:
			var split_room := Room.new(Room.types.SPLIT_2, "split")
			err = _extend(split_room)
			assert(!err)
			
			var branches := _branch(2)
			var branch_1 := branches[0]
			var branch_2 := branches[1]
			
			return _merge_connections([generate(self), generate(branch_1), generate(branch_2)])
		else:
			var split_room := Room.new(Room.types.SPLIT_2, "split")
			err = _extend(split_room)
			assert(!err)
			
			var branch := _branch(1)[0]
			
			return _merge_connections([generate(self), generate(branch)])


@warning_ignore("shadowed_global_identifier")
static func generate(dungeon: Dungeon) -> Dungeon:
	var err: Error
	if dungeon._depth_in_branch == dungeon.branch_length:
		return dungeon._end_branch()
	elif dungeon._depth_in_branch >= 2:
		var decay_chance := 1-pow(BRANCH_DECAY, -float(dungeon._depth_in_branch)/float(dungeon.branch_length))
		if dungeon._rng.randf() < decay_chance:
			return dungeon._end_branch()
		else:
			err = dungeon._extend(Room.new(Room.types.NORMAL, "room"))
			assert(!err)
			
			return generate(dungeon)
	else:
		var room := Room.new(Room.types.NORMAL, "room")
		err = dungeon._extend(room)
		assert(!err)
		
		return generate(dungeon)


#func _get_branches(room_id: int, prev_room_ids: Array[int] = [], branches: Array[Array] =  [[]]) -> Array[Array]:
	#if room_id in prev_room_ids:
		#branches.append(prev_room_ids)
		#return branches
	#else:
		#prev_room_ids.append(room_id)
		#for room in connections[room_id]:


@warning_ignore("shadowed_variable", "shadowed_global_identifier")
func _init(seed: int, tot_branches: int = -1, branch_length: int = -1, prev_room: Room = starting_room, main_branch: bool = true, branch_count: int = 0, depth_in_branch: int = 0, prev_split: Room = starting_room) -> void:
	self.seed = seed
	_rng.seed = seed
	
	if tot_branches == -1:
		self.tot_branches = _rng.randi_range(2, _MAX_BRANCHES)
	else:
		self.tot_branches = tot_branches
	
	if branch_length == -1:
		self.branch_length = _rng.randi_range(3, _MAX_BRANCH_LENGTH)
	else:
		self.branch_length = branch_length
		assert(branch_length >= 2, "branch is too short, must be 2 or greater")
	
	self._prev_room = prev_room
	self._main_branch = main_branch
	self._branch_count = branch_count
	self._depth_in_branch = depth_in_branch
	self._prev_split = prev_split


func _to_string(room_id: int = starting_room.id, tabs: String = "\t") -> String:
	#print(starting_room)
	#print(connections[starting_room])
	if connections[room_id].size() == 0:
		return str(room_id)
	elif connections[room_id].size() == 1:
		@warning_ignore("unsafe_call_argument")
		return str(room_id) + " -> " + _to_string(connections[room_id][0].id, tabs)
	else:
		var value := str(room_id)
		for i in connections[room_id].size():
			@warning_ignore("unsafe_call_argument")
			value += "\n"+tabs+str(room_id)+" -> "+_to_string(connections[room_id][i].id, tabs+"\t")
		return value
