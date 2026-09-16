extends CanvasLayer

var _rect: ColorRect
@export var fade_duration: float = 0.4


func _ready() -> void:
	layer = 128 

	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	_rect.visible = false
	add_child(_rect)


func fade_out() -> void:
	_rect.visible = true
	_rect.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished


func fade_in() -> void:
	_rect.visible = true
	_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, fade_duration)
	await tween.finished
	_rect.visible = false
