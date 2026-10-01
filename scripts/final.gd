extends Node2D

const COLOR_DARKEST: Color = Color("#002b59")
const COLOR_MID: Color = Color("#005f8c")
const COLOR_TEAL: Color = Color("#00b9be")
const COLOR_LIGHT: Color = Color("#9ff4e5")

@export var video_animation_name: String = "default"
@export var font_size: int = 14
@export var scroll_speed: float = 38.0
@export var cutscene_audio: AudioStream = preload("res://audio/final.wav")
@export var descent_stop_audio: AudioStream = preload("res://audio/subSTOP.wav")

@export_multiline var ending_text: String = """the deeper you go, the clearer it gets.

that was the lie it told them.

clarity was never the cure -- it was the invitation.

something down here has been waiting long enough that waiting stopped meaning anything. it does not think. it does not need to. it only needs you to.

the crew is gone. the door remains, or it doesn't, depending on whether anyone is left to look at it.

you made it further than they did.

that was never the achievement it sounds like."""

@onready var _video_sprite: AnimatedSprite2D = $VideoSprite

var _canvas_layer: CanvasLayer
var _scroll_viewport: Control
var _text_label: Label
var _the_end_panel: Control
var _menu_button: Button

var _audio_player: AudioStreamPlayer
var _stop_player: AudioStreamPlayer

var _scroll_tween: Tween

var _is_video_playing: bool = true
var _is_scrolling: bool = false
var _is_ended: bool = false
var _is_in_blackout: bool = false

var _music_pause_pos: float = 0.0
var _blackout_frames: Array[int] = [14, 19, 24]
var _font: FontFile


func _ready() -> void:
	_font = load("res://Early GameBoy.ttf") as FontFile

	# Audio player for background cutscene score (final.wav)
	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "CutsceneAudioPlayer"
	_audio_player.volume_db = 0.0
	add_child(_audio_player)
	if cutscene_audio:
		_audio_player.stream = cutscene_audio
		_audio_player.play()

	# Audio player for descent power shutdown sound (subSTOP.wav)
	_stop_player = AudioStreamPlayer.new()
	_stop_player.name = "DescentStopAudioPlayer"
	_stop_player.volume_db = 2.0
	add_child(_stop_player)

	_build_ui()

	_video_sprite.animation_finished.connect(_on_video_finished)
	_video_sprite.frame_changed.connect(_on_frame_changed)
	_video_sprite.frame = 0
	_video_sprite.play(video_animation_name)


func _on_frame_changed() -> void:
	if not _is_video_playing or _is_in_blackout:
		return

	var current_frame: int = _video_sprite.frame
	if current_frame in _blackout_frames:
		_handle_blackout(current_frame)


func _handle_blackout(frame_idx: int) -> void:
	_is_in_blackout = true

	# 1. Freeze video on the black frame
	_video_sprite.pause()

	# 2. Stop cutscene music and remember current position
	if _audio_player and _audio_player.playing:
		_music_pause_pos = _audio_player.get_playback_position()
		_audio_player.stop()

	# 3. Play descent stop power-down audio
	if _stop_player and descent_stop_audio:
		_stop_player.stream = descent_stop_audio
		_stop_player.play()

	# 4. Hold the blackout for suspense (2.2s for first blackout, 1.8s for subsequent)
	var hold_duration: float = 2.2 if frame_idx == 14 else 1.8
	await get_tree().create_timer(hold_duration).timeout

	if not _is_video_playing:
		return

	# 5. Stop the descent stop audio
	if _stop_player and _stop_player.playing:
		_stop_player.stop()

	# 6. Resume the cutscene music from where it left off
	if _audio_player and cutscene_audio:
		_audio_player.play(_music_pause_pos)

	# 7. Blackout ends: advance to next frame and resume animation
	_is_in_blackout = false
	if _video_sprite.frame < 28:
		_video_sprite.frame += 1
		_video_sprite.play(video_animation_name)


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		return

	if _is_video_playing:
		get_viewport().set_input_as_handled()
		if _stop_player and _stop_player.playing:
			_stop_player.stop()
		_on_video_finished()
	elif _is_scrolling:
		get_viewport().set_input_as_handled()
		_show_the_end()
	elif _is_ended:
		get_viewport().set_input_as_handled()
		_return_to_main_menu()


func _build_ui() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	add_child(_canvas_layer)

	# Scroll viewport across entire screen
	_scroll_viewport = Control.new()
	_scroll_viewport.position = Vector2.ZERO
	_scroll_viewport.size = screen_size
	_scroll_viewport.clip_contents = true
	_scroll_viewport.visible = false
	_canvas_layer.add_child(_scroll_viewport)

	# Cleanly formatted text column centered horizontally with generous margins
	var content_width: float = min(660.0, screen_size.x - 80.0)
	var content_x: float = (screen_size.x - content_width) * 0.5

	_text_label = Label.new()
	_text_label.text = ending_text.replace("—", "--")
	_text_label.position = Vector2(content_x, screen_size.y)
	_text_label.custom_minimum_size = Vector2(content_width, 0)
	_text_label.size = Vector2(content_width, 0)
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	if _font:
		_text_label.add_theme_font_override("font", _font)
	_text_label.add_theme_font_size_override("font_size", font_size)
	_text_label.add_theme_color_override("font_color", COLOR_LIGHT)
	_text_label.add_theme_color_override("font_outline_color", COLOR_DARKEST)
	_text_label.add_theme_constant_override("outline_size", 2)
	_text_label.add_theme_constant_override("line_spacing", 10)

	_scroll_viewport.add_child(_text_label)

	# The End screen
	_the_end_panel = Control.new()
	_the_end_panel.position = Vector2.ZERO
	_the_end_panel.size = screen_size
	_the_end_panel.visible = false
	_the_end_panel.modulate.a = 0.0
	_canvas_layer.add_child(_the_end_panel)

	var center_vbox := VBoxContainer.new()
	center_vbox.anchor_left = 0.5
	center_vbox.anchor_top = 0.5
	center_vbox.anchor_right = 0.5
	center_vbox.anchor_bottom = 0.5
	center_vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_vbox.add_theme_constant_override("separation", 16)
	_the_end_panel.add_child(center_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "THE END"
	if _font:
		title_lbl.add_theme_font_override("font", _font)
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", COLOR_LIGHT)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "10,000m REACHED"
	if _font:
		sub_lbl.add_theme_font_override("font", _font)
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", COLOR_TEAL)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_vbox.add_child(sub_lbl)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = COLOR_MID
	btn_style.border_color = COLOR_TEAL
	btn_style.set_border_width_all(2)
	btn_style.corner_radius_top_left = 0
	btn_style.corner_radius_top_right = 0
	btn_style.corner_radius_bottom_left = 0
	btn_style.corner_radius_bottom_right = 0
	btn_style.set_content_margin_all(8)
	btn_style.content_margin_left = 16
	btn_style.content_margin_right = 16

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = COLOR_TEAL
	btn_hover.border_color = COLOR_LIGHT
	btn_hover.set_border_width_all(2)
	btn_hover.corner_radius_top_left = 0
	btn_hover.corner_radius_top_right = 0
	btn_hover.corner_radius_bottom_left = 0
	btn_hover.corner_radius_bottom_right = 0
	btn_hover.set_content_margin_all(8)
	btn_hover.content_margin_left = 16
	btn_hover.content_margin_right = 16

	_menu_button = Button.new()
	_menu_button.text = "Main Menu"
	if _font:
		_menu_button.add_theme_font_override("font", _font)
	_menu_button.add_theme_font_size_override("font_size", 12)
	_menu_button.add_theme_color_override("font_color", COLOR_LIGHT)
	_menu_button.add_theme_color_override("font_hover_color", COLOR_DARKEST)
	_menu_button.add_theme_stylebox_override("normal", btn_style)
	_menu_button.add_theme_stylebox_override("hover", btn_hover)
	_menu_button.add_theme_stylebox_override("pressed", btn_hover)
	_menu_button.add_theme_stylebox_override("focus", btn_hover)
	_menu_button.pressed.connect(_return_to_main_menu)
	center_vbox.add_child(_menu_button)


func _on_video_finished() -> void:
	if not _is_video_playing:
		return
	_is_video_playing = false

	if _stop_player and _stop_player.playing:
		_stop_player.stop()

	if _audio_player and not _audio_player.playing and cutscene_audio:
		_audio_player.play(_music_pause_pos)

	await TransitionLayer.fade_out(0.8)

	_video_sprite.visible = false
	_start_scroll()

	await TransitionLayer.fade_in(0.8)


func _start_scroll() -> void:
	_is_scrolling = true
	_scroll_viewport.visible = true

	# Wait a frame to ensure word wrap and line layout are calculated
	_text_label.reset_size()
	await get_tree().process_frame

	var viewport_height: float = _scroll_viewport.size.y
	var line_count: int = _text_label.get_line_count()
	var line_height: int = _text_label.get_line_height()
	var calculated_height: float = line_count * (line_height + 10) + 40.0
	var total_height: float = max(_text_label.size.y, calculated_height)

	_text_label.position.y = viewport_height
	var end_y: float = -(total_height + 60.0)

	var distance: float = _text_label.position.y - end_y
	var duration: float = distance / scroll_speed

	_scroll_tween = create_tween()
	_scroll_tween.tween_property(_text_label, "position:y", end_y, duration)
	_scroll_tween.tween_interval(1.5)
	_scroll_tween.tween_callback(func():
		_show_the_end()
	)


func _show_the_end() -> void:
	if _is_ended:
		return
	_is_scrolling = false
	_is_ended = true

	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()

	await TransitionLayer.fade_out(0.6)

	_scroll_viewport.visible = false
	_the_end_panel.visible = true
	_the_end_panel.modulate.a = 1.0

	await TransitionLayer.fade_in(0.8)


func _return_to_main_menu() -> void:
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
	if _stop_player and _stop_player.playing:
		_stop_player.stop()

	_the_end_panel.visible = false
	SubmarineState.reset_state()
	JournalState.reset_state()
	SceneManager.reset_state()
	SceneManager.go_to_scene("res://scenes/mainmenu.tscn")
