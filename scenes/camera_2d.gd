extends Camera2D

func _input(event: InputEvent) -> void:
	if event.is_action(&"scroll_up"):
		zoom += Vector2.ONE / 20
	elif event.is_action(&"scroll_down"):
		zoom -= Vector2.ONE / 20
	elif event.is_action(&"ui_left"):
		global_position += Vector2(0.1, 0)
	elif event.is_action(&"ui_right"):
		global_position += Vector2(-0.1, 0)
	elif event.is_action(&"ui_down"):
		global_position += Vector2(0, -0.1)
	elif event.is_action(&"ui_up"):
		global_position += Vector2(0, 0.1)
