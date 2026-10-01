extends CanvasLayer

var _rect: ColorRect
var _label: Label
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

	_label = Label.new()
	_label.anchor_left = 0.0
	_label.anchor_top = 0.0
	_label.anchor_right = 1.0
	_label.anchor_bottom = 1.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.modulate.a = 0.0
	_label.visible = false

	var font: FontFile = load("res://Early GameBoy.ttf") as FontFile
	if font:
		_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color("#9ff4e5"))
	add_child(_label)


func fade_out(custom_duration: float = -1.0) -> void:
	var d: float = fade_duration if custom_duration < 0.0 else custom_duration
	_rect.visible = true
	_rect.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 1.0, d)
	await tween.finished


func fade_in(custom_duration: float = -1.0) -> void:
	var d: float = fade_duration if custom_duration < 0.0 else custom_duration
	_rect.visible = true
	_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, d)
	await tween.finished
	_rect.visible = false


func show_message(text: String, hold_duration: float = 2.0, fade_time: float = 0.6) -> void:
	_label.text = text
	_label.visible = true
	_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_label, "modulate:a", 1.0, fade_time)
	tween.tween_interval(hold_duration)
	tween.tween_property(_label, "modulate:a", 0.0, fade_time)
	await tween.finished
	_label.visible = false
