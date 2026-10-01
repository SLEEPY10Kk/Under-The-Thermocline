extends Control

signal succeeded
signal failed

@export_group("Behavior")
@export var pointer_speed: float = 460.0
@export var target_arc_degrees: float = 45.0
@export var max_misses: int = 1

var _pointer_angle: float = 0.0
var _target_start_angle: float = 0.0
var _misses: int = 0
var _active: bool = true

@onready var _target_rect: TextureRect = $Target
@onready var _pointer_rect: TextureRect = $Pointer
@onready var _ring_rect: TextureRect = $Ring


func _ready() -> void:
	_target_start_angle = randf_range(0.0, 360.0)
	_target_rect.rotation_degrees = _target_start_angle
	_pointer_angle = fposmod(_target_start_angle + 180.0, 360.0) # start opposite from target
	_pointer_rect.rotation_degrees = _pointer_angle


func _process(delta: float) -> void:
	if not _active:
		return

	_pointer_angle = fmod(_pointer_angle + pointer_speed * delta, 360.0)
	_pointer_rect.rotation_degrees = _pointer_angle

	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		_check_press()


func _check_press() -> void:
	if _is_pointer_overlapping_target():
		_active = false
		_flash_success()
	else:
		_misses += 1
		_flash_miss()
		if _misses > max_misses:
			_active = false
			failed.emit()


func _is_pointer_overlapping_target() -> bool:
	var diff: float = abs(fposmod(_pointer_angle - _target_start_angle + 180.0, 360.0) - 180.0)
	return diff <= (target_arc_degrees * 0.5)


func _flash_success() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color("#9ff4e5"), 0.1)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	tween.tween_callback(func(): succeeded.emit())


func _flash_miss() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.08)
	tween.tween_property(self, "modulate", Color.WHITE, 0.08)
