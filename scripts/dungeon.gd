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
	
	
	@warning_ignore("shadowed_variable")
	func _init(type: types, name: String) -> void:
		self.type = type
		self.name = name

@warning_ignore("shadowed_global_identifier")
var seed: int
var num_branches: int
var branch_length: int
var _prev_room: Room = starting_room
var _main_branch: bool = true
var _branch_count: int = 0
var _depth_in_branch: int = 0
var _prev_split: Room = starting_room

var connections: Dictionary[Room , Array]
var starting_room := Room.new(Room.types.START, "start")
var ending_room := Room.new(Room.types.END, "end")

func _add_connection(from: Room, to: Room) -> Error:
	if from not in connections:
		connections[from] = []
	
	if to in connections[from]:
		return ERR_ALREADY_EXISTS
	connections[from].append(to)
	
	if to not in connections:
		connections[to] = []
	
	return OK

static func _merge_connections(dungeons: Array[Dungeon]) -> Dungeon:
	assert(dungeons.size() != 0)
	var final_dungeon := Dungeon.new(dungeons[0].seed, dungeons[0].num_branches, dungeons[0].branch_length)
	
	for dungeon in dungeons:
		assert(dungeon.seed == final_dungeon.seed)
		assert(dungeon.num_branches == final_dungeon.num_branches)
		assert(dungeon.branch_length == final_dungeon.branch_length)
		final_dungeon.connections.merge(dungeon.connections)
	
	return final_dungeon


func itterate(current_room: Room, branching: bool = false, become_main_branch: bool = false) -> void:
	var err := _add_connection(_prev_room, current_room)
	assert(!err)
	
	_prev_room = current_room
	
	if branching:
		_main_branch = become_main_branch
		_branch_count += 1
		_depth_in_branch = 0
		_prev_split = current_room
	else:
		_depth_in_branch += 1


#func duplicate() -> Dungeon:
	#return Dungeon.new()


@warning_ignore("shadowed_global_identifier")
static func generate(dungeon: Dungeon) -> Dungeon:
	print("test")
	var err: Error
	if dungeon._depth_in_branch == dungeon.branch_length:
		if dungeon._branch_count == dungeon.num_branches:
			if dungeon._main_branch:
				err = dungeon._add_connection(dungeon._prev_room, dungeon.ending_room)
				assert(!err)
				
				#print(dungeon._to_string())
				return dungeon
			else:
				err = dungeon._add_connection(dungeon._prev_room, Room.new(Room.types.NORMAL, "room"))
				assert(!err)
				
				#print(dungeon._to_string())
				return dungeon
		else:
			var split_room := Room.new(Room.types.SPLIT_2, "split")
			err = dungeon._add_connection(dungeon._prev_room, split_room)
			assert(!err)
			
			var is_main_branch := rand_from_seed(dungeon.seed)[0] % 2 == 0
			var branch:Dungeon = dungeon.duplicate(true) 
			branch.itterate(split_room, true, !is_main_branch)
			
			dungeon.itterate(split_room, true, is_main_branch)
			
			#print(dungeon._to_string())
			#print(branch._to_string())
			return Dungeon._merge_connections([generate(dungeon), generate(branch)])
	else:
		var room := Room.new(Room.types.NORMAL, "room")
		dungeon.itterate(room)
		
		#print(dungeon._to_string())
		return generate(dungeon)


#@warning_ignore("shadowed_variable", "shadowed_global_identifier")
#func _init(seed: int, num_branches: int, branch_length: int) -> void:
	#self.seed = seed
	#self.num_branches = num_branches
	#self.branch_length = branch_length


@warning_ignore("shadowed_variable", "shadowed_global_identifier")
func _init(seed: int, num_branches: int, branch_length: int, prev_room: Room, prev_split: Room, main_branch: bool = true, branch_count: int = 0, depth_in_branch: int = 0) -> void:
	self.seed = seed
	self.num_branches = num_branches
	self.branch_length = branch_length
	self._prev_room = prev_room
	self._main_branch = main_branch
	self._branch_count = branch_count
	self._depth_in_branch = depth_in_branch
	self._prev_split = prev_split

#var another_room := Room.new(Room.types.NORMAL, "room1")
#var another_room2 := Room.new(Room.types.NORMAL, "room2")
#var another_room3 := Room.new(Room.types.NORMAL, "room3")
#var another_room4 := Room.new(Room.types.NORMAL, "room4")
#
#var test_connections: Dictionary[Room, Array] = {
	#starting_room : [another_room],
	#another_room : [another_room2, ending_room],
	#another_room2 : [another_room3, another_room4],
	#another_room4 : [],
	#another_room3 : [],
	#ending_room : [],
#}




func _to_string(room: Room = starting_room, tabs: String = "\t") -> String:
	if connections[room].size() == 0:
		return room.name
	elif connections[room].size() == 1:
		@warning_ignore("unsafe_cast")
		return room.name + " -> " + _to_string(connections[room][0] as Room)
	else:
		var value := room.name
		for i in connections[room].size():
			@warning_ignore("unsafe_cast")
			value += "\n"+tabs+room.name+" -> "+_to_string(connections[room][i] as Room, tabs+"\t")
		return value
