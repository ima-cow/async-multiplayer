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

@warning_ignore("shadowed_global_identifier")
var seed: int
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


@warning_ignore("shadowed_global_identifier")
static func generate(dungeon: Dungeon) -> Dungeon:
	var err: Error
	if dungeon._depth_in_branch == dungeon.branch_length:
		if dungeon._branch_count == dungeon.tot_branches:
			if dungeon._main_branch:
				err = dungeon._add_connection(dungeon._prev_room, dungeon.ending_room)
				assert(!err)
				
				return dungeon
			else:
				err = dungeon._add_connection(dungeon._prev_room, Room.new(Room.types.NORMAL, "room"))
				assert(!err)
				
				return dungeon
		else:
			var split_room := Room.new(Room.types.SPLIT_2, "split")
			err = dungeon._extend(split_room)
			assert(!err)
			
			var branch := dungeon._branch(1)[0]

			return _merge_connections([generate(dungeon), generate(branch)])
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
func _init(seed: int, tot_branches: int, branch_length: int, prev_room: Room = starting_room, main_branch: bool = true, branch_count: int = 0, depth_in_branch: int = 0, prev_split: Room = starting_room) -> void:
	self.seed = seed
	self.tot_branches = tot_branches
	self.branch_length = branch_length
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
