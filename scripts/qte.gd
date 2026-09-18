extends Control

signal succeeded
signal failed

@export_group("Textures")
@export var ring_texture: Texture2D          
@export var pointer_texture: Texture2D      
@export var target_texture: Texture2D       

@export_group("Behavior")
@export var radius: float = 80.0
@export var pointer_speed: float = 180.0
@export var target_arc_degrees: float = 40.0
@export var max_misses: int = 1

var _pointer_angle: float = 0.0
var _target_start_angle: float = 0.0
var _misses: int = 0
var _active: bool = true

@onready var _ring_rect: TextureRect = $Ring
@onready var _target_rect: TextureRect = $Target
@onready var _pointer_rect: TextureRect = $Pointer


func _ready() -> void:
	_target_start_angle = randf_range(0.0, 360.0)

	if ring_texture:
		_ring_rect.texture = ring_texture
	if target_texture:
		_target_rect.texture = target_texture
	if pointer_texture:
		_pointer_rect.texture = pointer_texture

	_target_rect.pivot_offset = _target_rect.size / 2.0
	_pointer_rect.pivot_offset = _pointer_rect.size / 2.0

	_target_rect.rotation_degrees = _target_start_angle
	_update_pointer_transform()


func _process(delta: float) -> void:
	if not _active:
		return

	_pointer_angle = fmod(_pointer_angle + pointer_speed * delta, 360.0)
	_update_pointer_transform()

	if Input.is_action_just_pressed("interact"):
		_check_press()


func _update_pointer_transform() -> void:
	var center: Vector2 = size / 2.0
	var rad: float = deg_to_rad(_pointer_angle)
	var pos: Vector2 = center + Vector2(cos(rad), sin(rad)) * radius
	_pointer_rect.position = pos - _pointer_rect.size / 2.0
	_pointer_rect.rotation_degrees = _pointer_angle + 90.0  


func _check_press() -> void:
	if _is_pointer_in_target():
		_active = false
		succeeded.emit()
	else:
		_misses += 1
		if _misses > max_misses:
			_active = false
			failed.emit()


func _is_pointer_in_target() -> bool:
	var diff: float = fmod(_pointer_angle - _target_start_angle + 360.0, 360.0)
	return diff <= target_arc_degrees
