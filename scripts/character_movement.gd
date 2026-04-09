extends RigidBody2D

const MAX_SPEED := 200
const ACCELERATION := 25
const FRICTION := 40


func _physics_process(delta: float) -> void:
	var x_input := Input.get_action_strength(&"walk_right") - Input.get_action_strength(&"walk_left")
	var y_input := Input.get_action_strength(&"walk_down") - Input.get_action_strength(&"walk_up")
	var input := Vector2(x_input, y_input)
	
	var lerp_weight := delta * (ACCELERATION if input == Vector2.ZERO else FRICTION)
	linear_velocity = linear_velocity.lerp(input * MAX_SPEED, lerp_weight)
	
	@warning_ignore("return_value_discarded")
	move_and_collide(linear_velocity * delta)
