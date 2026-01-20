class_name Dungeon extends RefCounted

class Room extends RefCounted:
	enum types {
		START,
		END,
		NORMAL,
		HUB,
	}
	
	var type: types
	var name: String
	
	
	@warning_ignore("shadowed_variable")
	func _init(type: types, name: String) -> void:
		self.type = type
		self.name = name


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

func _merge_connections(dungeons: Array[Dungeon]) -> Dungeon:
	var final_dungeon := Dungeon.new()
	
	for dungeon in dungeons:
		final_dungeon.connections.merge(dungeon.connections)
	
	return final_dungeon



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

@warning_ignore("shadowed_global_identifier")
static func generate(seed:int, size: int, dungeon: Dungeon = Dungeon.new(), prev_room: Room = dungeon.starting_room, depth: int = 0, main_branch: bool = true) -> Dungeon:
	if depth == size:
		@warning_ignore("confusable_local_declaration")
		var err := dungeon._add_connection(prev_room, dungeon.ending_room)
		assert(!err)
		return dungeon
	
	var room := Room.new(Room.types.NORMAL, "room")
	var err := dungeon._add_connection(prev_room, room)
	assert(!err)
	
	return generate(seed, size, dungeon, room, depth+1)





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
