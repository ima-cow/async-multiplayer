extends Node

func _ready() -> void:
	pass


func _on_save_pressed() -> void:
	var err := GameStateManager.save_state()
	assert(!err, "failed to save")


func _on_dungeon_1_pressed() -> void:
	GameStateManager.set_state_or_diffs("dungeon_1", true)


func _on_dungeon_2_pressed() -> void:
	GameStateManager.set_state_or_diffs("dungeon_2", true)


func _on_dungeon_3_pressed() -> void:
	GameStateManager.set_state_or_diffs("dungeon_3", true)
