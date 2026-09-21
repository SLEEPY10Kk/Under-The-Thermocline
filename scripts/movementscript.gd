extends CharacterBody2D

@export var move_speed: float = 50.0
@export var gravity: float = 800.0
@export var footstep_sound: AudioStream

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _footstep_player: AudioStreamPlayer = $FootstepPlayer

func _physics_process(delta: float) -> void:
	if SubmarineState.qte_active:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(0.0)
		return

	velocity.y += gravity * delta

	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed

	move_and_slide()
	_update_animation(direction)
	_update_footsteps(direction)


func _update_footsteps(direction: float) -> void:
	if not _footstep_player or not footstep_sound:
		return

	if direction != 0.0:
		if not _footstep_player.playing:
			_footstep_player.stream = footstep_sound
			_footstep_player.play()
	else:
		if _footstep_player.playing:
			_footstep_player.stop()


func _update_animation(direction: float) -> void:
	if not _sprite:
		return

	if direction != 0.0:
		_sprite.play("walk")
		_sprite.flip_h = direction < 0.0
	else:
		_sprite.play("idle")


func enter_submarine() -> void:
	velocity = Vector2.ZERO
	PromptUi.show_temporary("A / D to walk")
	SubmarineState.set_player_inside(true)
