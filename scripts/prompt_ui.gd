extends Node

var _canvas_layer: CanvasLayer
var _interact_label: Label
var _movement_label: Label
var _movement_tween: Tween
var _current_player: Node2D


func attach_to_player(player: Node2D) -> void:
	_current_player = player

	if _canvas_layer:
		_canvas_layer.queue_free()

	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 95
	get_tree().current_scene.add_child(_canvas_layer)

	_interact_label = Label.new()
	_interact_label.visible = false
	_interact_label.add_theme_font_size_override("font_size", 24)
	_canvas_layer.add_child(_interact_label)

	_movement_label = Label.new()
	_movement_label.visible = false
	_movement_label.modulate.a = 0.0
	_movement_label.add_theme_font_size_override("font_size", 24)
	_canvas_layer.add_child(_movement_label)


func _process(_delta: float) -> void:
	if not _current_player or not _interact_label or not _movement_label:
		return
	var screen_pos: Vector2 = _current_player.get_global_transform_with_canvas().origin
	_interact_label.position = screen_pos + Vector2(-80, -240)
	_movement_label.position = screen_pos + Vector2(-80, -200)


func show_interact_prompt(text: String) -> void:
	if not _interact_label:
		return
	_interact_label.text = text
	_interact_label.visible = true


func hide_interact_prompt() -> void:
	if _interact_label:
		_interact_label.visible = false


func show_temporary(text: String, hold_duration: float = 2.0, fade_duration: float = 0.6) -> void:
	if not _movement_label:
		return
	if _movement_tween:
		_movement_tween.kill()

	_movement_label.text = text
	_movement_label.visible = true
	_movement_label.modulate.a = 0.0

	_movement_tween = create_tween()
	_movement_tween.tween_property(_movement_label, "modulate:a", 1.0, 0.2)
	_movement_tween.tween_interval(hold_duration)
	_movement_tween.tween_property(_movement_label, "modulate:a", 0.0, fade_duration)
	_movement_tween.tween_callback(func(): _movement_label.visible = false)


func detach() -> void:
	if _movement_tween:
		_movement_tween.kill()
	_movement_tween = null
	_interact_label = null
	_movement_label = null
	_current_player = null
