extends CharacterBody2D

@export var move_speed: float = 200.0
@export var swim_speed: float = 150.0
@export var gravity: float = 800.0
@export var jump_force: float = -300.0

var in_submarine: bool = true

func _physics_process(delta: float) -> void:
	if in_submarine:
		_handle_submarine_movement(delta)
	else:
		_handle_swim_movement(delta)

	move_and_slide()


func _handle_submarine_movement(delta: float) -> void:
	velocity.y += gravity * delta

	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed


func _handle_swim_movement(delta: float) -> void:
	var direction: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if direction.length() > 0:
		direction = direction.normalized()

	velocity = direction * swim_speed


func enter_submarine() -> void:
	in_submarine = true
	velocity = Vector2.ZERO


func exit_submarine() -> void:
	in_submarine = false
	velocity = Vector2.ZERO
