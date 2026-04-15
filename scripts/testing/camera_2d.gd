extends Camera2D

func _input(event: InputEvent) -> void:
	if event.is_action(&"scroll_up"):
		zoom += Vector2.ONE / 100
	elif event.is_action(&"scroll_down"):
		zoom -= Vector2.ONE / 100
	elif event.is_action(&"ui_left"):
		global_position += Vector2(-50, 0)
	elif event.is_action(&"ui_right"):
		global_position += Vector2(50, 0)
	elif event.is_action(&"ui_down"):
		global_position += Vector2(0, 50)
	elif event.is_action(&"ui_up"):
		global_position += Vector2(0, -50)
