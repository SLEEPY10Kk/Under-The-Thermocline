extends Control

signal succeeded
signal failed

@export_group("Behavior")
@export var pointer_speed: float = 800.0
@export var target_arc_degrees: float = 40.0
@export var max_misses: int = 0

var _pointer_angle: float = 0.0
var _target_start_angle: float = 0.0
var _misses: int = 0
var _active: bool = true

@onready var _target_rect: TextureRect = $Target
@onready var _pointer_rect: TextureRect = $Pointer


func _ready() -> void:
	_target_start_angle = randf_range(0.0, 360.0)
	_target_rect.rotation_degrees = _target_start_angle
	_pointer_rect.rotation_degrees = _pointer_angle


func _process(delta: float) -> void:
	if not _active:
		return

	_pointer_angle = fmod(_pointer_angle + pointer_speed * delta, 360.0)
	_pointer_rect.rotation_degrees = _pointer_angle

	if Input.is_action_just_pressed("move_up"):
		_check_press()


func _check_press() -> void:
	if _is_pointer_overlapping_target():
		_active = false
		succeeded.emit()
	else:
		_misses += 1
		if _misses > max_misses:
			_active = false
			failed.emit()


func _is_pointer_overlapping_target() -> bool:
	return _pointer_rect.get_global_rect().intersects(_target_rect.get_global_rect())
