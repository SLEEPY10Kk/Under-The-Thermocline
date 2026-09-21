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

	_dim_bg = ColorRect.new()
	_dim_bg.color = COLOR_DARKEST
	_dim_bg.anchor_right = 1.0
	_dim_bg.anchor_bottom = 1.0
	_dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_bg.visible = false
	add_child(_dim_bg)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(340, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_MID
	style.border_color = COLOR_TEAL
	style.set_border_width_all(3)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.add_theme_color_override("font_color", COLOR_TEAL)
	vbox.add_child(_title_label)

	_text_label = Label.new()
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
	_close_button.text = "Close"
	_close_button.custom_minimum_size = Vector2(0, 28)
	_close_button.add_theme_stylebox_override("normal", button_style)
	_close_button.add_theme_stylebox_override("hover", button_style)
	_close_button.add_theme_stylebox_override("pressed", button_style)
	_close_button.add_theme_stylebox_override("focus", button_style)
	_close_button.add_theme_color_override("font_color", COLOR_DARKEST)
	_close_button.add_theme_color_override("font_hover_color", COLOR_DARKEST)
	_close_button.add_theme_color_override("font_pressed_color", COLOR_DARKEST)
	_close_button.pressed.connect(hide_note)
	vbox.add_child(_close_button)

	await get_tree().process_frame
	_panel.set_anchors_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)


func show_note(title: String, text: String) -> void:
	_title_label.text = title
	_text_label.text = text

	_dim_bg.visible = true
	_panel.visible = true
	_dim_bg.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = true
	SubmarineState.set_reading_note(true)


func hide_note() -> void:
	_dim_bg.visible = false
	_panel.visible = false
	get_tree().paused = false
	SubmarineState.set_reading_note(false)
