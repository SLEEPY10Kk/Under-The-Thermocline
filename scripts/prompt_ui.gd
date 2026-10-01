extends Node

var _canvas_layer: CanvasLayer
var _interact_container: PanelContainer
var _interact_label: Label

var _movement_container: PanelContainer
var _movement_label: Label
var _movement_tween: Tween

var _current_player: Node2D

const COLOR_DARKEST: Color = Color("#002b59")
const COLOR_MID: Color = Color("#005f8c")
const COLOR_TEAL: Color = Color("#00b9be")
const COLOR_LIGHT: Color = Color("#9ff4e5")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()


func _create_ui() -> void:
	if _canvas_layer:
		return

	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 105
	add_child(_canvas_layer)

	var font: FontFile = load("res://Early GameBoy.ttf") as FontFile

	# Style for interact prompt container
	var interact_style := StyleBoxFlat.new()
	interact_style.bg_color = Color(COLOR_DARKEST.r, COLOR_DARKEST.g, COLOR_DARKEST.b, 0.85)
	interact_style.border_color = COLOR_TEAL
	interact_style.set_border_width_all(2)
	interact_style.set_content_margin_all(6)
	interact_style.content_margin_left = 10
	interact_style.content_margin_right = 10

	_interact_container = PanelContainer.new()
	_interact_container.add_theme_stylebox_override("panel", interact_style)
	_interact_container.visible = false
	_interact_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_interact_container)

	_interact_label = Label.new()
	if font:
		_interact_label.add_theme_font_override("font", font)
	_interact_label.add_theme_font_size_override("font_size", 14)
	_interact_label.add_theme_color_override("font_color", COLOR_LIGHT)
	_interact_label.add_theme_color_override("font_outline_color", COLOR_DARKEST)
	_interact_label.add_theme_constant_override("outline_size", 3)
	_interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interact_container.add_child(_interact_label)

	# Style for temporary/movement notification container
	var movement_style := StyleBoxFlat.new()
	movement_style.bg_color = Color(COLOR_MID.r, COLOR_MID.g, COLOR_MID.b, 0.9)
	movement_style.border_color = COLOR_LIGHT
	movement_style.set_border_width_all(2)
	movement_style.set_content_margin_all(6)
	movement_style.content_margin_left = 12
	movement_style.content_margin_right = 12

	_movement_container = PanelContainer.new()
	_movement_container.add_theme_stylebox_override("panel", movement_style)
	_movement_container.visible = false
	_movement_container.modulate.a = 0.0
	_movement_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_movement_container)

	_movement_label = Label.new()
	if font:
		_movement_label.add_theme_font_override("font", font)
	_movement_label.add_theme_font_size_override("font_size", 14)
	_movement_label.add_theme_color_override("font_color", COLOR_LIGHT)
	_movement_label.add_theme_color_override("font_outline_color", COLOR_DARKEST)
	_movement_label.add_theme_constant_override("outline_size", 3)
	_movement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_movement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_movement_container.add_child(_movement_label)


func attach_to_player(player: Node2D) -> void:
	_current_player = player
	_create_ui()


func detach() -> void:
	if _movement_tween and _movement_tween.is_valid():
		_movement_tween.kill()
	_movement_tween = null
	if _interact_container:
		_interact_container.visible = false
	if _movement_container:
		_movement_container.visible = false
	_current_player = null


func _process(_delta: float) -> void:
	if not _canvas_layer or not is_instance_valid(_canvas_layer):
		_create_ui()
		return

	var vp_size: Vector2 = _canvas_layer.get_viewport().get_visible_rect().size
	var base_x: float = vp_size.x * 0.5
	var base_y: float = 60.0

	var has_valid_player: bool = is_instance_valid(_current_player) and _current_player.is_inside_tree()
	if has_valid_player:
		var canvas_xform: Transform2D = _current_player.get_global_transform_with_canvas()
		base_x = canvas_xform.origin.x
		base_y = canvas_xform.origin.y - 110.0

	# Position interact container
	if _interact_container and _interact_container.visible:
		var w: float = _interact_container.size.x
		var h: float = _interact_container.size.y
		var pos_x: float = clamp(base_x - w * 0.5, 12.0, max(12.0, vp_size.x - w - 12.0))
		var pos_y: float = clamp(base_y - h, 16.0, max(16.0, vp_size.y - h - 16.0))
		_interact_container.position = Vector2(pos_x, pos_y)

	# Position temporary notification container (stacked above interact prompt if both shown)
	if _movement_container and _movement_container.visible:
		var w: float = _movement_container.size.x
		var h: float = _movement_container.size.y
		var pos_x: float = clamp(base_x - w * 0.5, 12.0, max(12.0, vp_size.x - w - 12.0))
		var offset_above: float = (_interact_container.size.y + 8.0) if (_interact_container and _interact_container.visible) else 0.0
		var pos_y: float = clamp(base_y - h - offset_above, 16.0, max(16.0, vp_size.y - h - 16.0))
		_movement_container.position = Vector2(pos_x, pos_y)


func show_interact_prompt(text: String) -> void:
	_create_ui()
	if not _interact_label or not _interact_container:
		return
	_interact_label.text = text
	_interact_container.reset_size()
	_interact_container.visible = true


func hide_interact_prompt() -> void:
	if _interact_container:
		_interact_container.visible = false


func show_temporary(text: String, hold_duration: float = 2.0, fade_duration: float = 0.6) -> void:
	_create_ui()
	if not _movement_label or not _movement_container:
		return

	if _movement_tween and _movement_tween.is_valid():
		_movement_tween.kill()

	_movement_label.text = text
	_movement_container.reset_size()
	_movement_container.visible = true
	_movement_container.modulate.a = 0.0

	_movement_tween = create_tween()
	_movement_tween.tween_property(_movement_container, "modulate:a", 1.0, 0.2)
	_movement_tween.tween_interval(hold_duration)
	_movement_tween.tween_property(_movement_container, "modulate:a", 0.0, fade_duration)
	_movement_tween.tween_callback(func():
		if _movement_container:
			_movement_container.visible = false
	)
