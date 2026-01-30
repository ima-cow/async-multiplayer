extends Node


func _ready() -> void:
	var dungeon := Dungeon.generate(Dungeon.new(randi(), 5, 5))
	
	for branch in dungeon.branch_ids:
		#print(branch.)
		print(dungeon.branch_ids[branch].rooms)
