extends CanvasLayer

const COLOR_DARKEST: Color = Color("#002b59")
const COLOR_MID: Color = Color("#005f8c")
const COLOR_TEAL: Color = Color("#00b9be")
const COLOR_LIGHT: Color = Color("#9ff4e5")

var _dim_bg: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _text_label: Label
var _close_button: Button


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS

	var font: FontFile = load("res://Early GameBoy.ttf") as FontFile

	_dim_bg = ColorRect.new()
	_dim_bg.color = Color(COLOR_DARKEST.r, COLOR_DARKEST.g, COLOR_DARKEST.b, 0.85)
	_dim_bg.anchor_right = 1.0
	_dim_bg.anchor_bottom = 1.0
	_dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_bg.visible = false
	add_child(_dim_bg)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(360, 0)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_MID
	style.border_color = COLOR_TEAL
	style.set_border_width_all(3)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	_title_label = Label.new()
	if font:
		_title_label.add_theme_font_override("font", font)
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", COLOR_TEAL)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	_text_label = Label.new()
	if font:
		_text_label.add_theme_font_override("font", font)
	_text_label.add_theme_font_size_override("font_size", 12)
	_text_label.add_theme_color_override("font_color", COLOR_LIGHT)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_text_label)

	var button_style := StyleBoxFlat.new()
	button_style.bg_color = COLOR_TEAL
	button_style.corner_radius_top_left = 0
	button_style.corner_radius_top_right = 0
	button_style.corner_radius_bottom_left = 0
	button_style.corner_radius_bottom_right = 0

	_close_button = Button.new()
	_close_button.text = "Close (E)"
	if font:
		_close_button.add_theme_font_override("font", font)
	_close_button.add_theme_font_size_override("font_size", 12)
	_close_button.custom_minimum_size = Vector2(0, 30)
	_close_button.add_theme_stylebox_override("normal", button_style)
	_close_button.add_theme_stylebox_override("hover", button_style)
	_close_button.add_theme_stylebox_override("pressed", button_style)
	_close_button.add_theme_stylebox_override("focus", button_style)
	_close_button.add_theme_color_override("font_color", COLOR_DARKEST)
	_close_button.add_theme_color_override("font_hover_color", COLOR_DARKEST)
	_close_button.add_theme_color_override("font_pressed_color", COLOR_DARKEST)
	_close_button.pressed.connect(hide_note)
	vbox.add_child(_close_button)


func _unhandled_input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		hide_note()


func show_note(title: String, text: String) -> void:
	_title_label.text = title
	_text_label.text = text

	_dim_bg.visible = true
	_panel.visible = true

	get_tree().paused = true
	SubmarineState.set_reading_note(true)


func hide_note() -> void:
	_dim_bg.visible = false
	_panel.visible = false
	get_tree().paused = false
	SubmarineState.set_reading_note(false)
