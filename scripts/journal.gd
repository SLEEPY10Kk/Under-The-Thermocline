extends Node2D

@export var pages: Array[String] = []
@export var page_turn_sound: AudioStream = preload("res://audio/pageTURN.wav")

@export var font_size: int = 5
@export var text_box_size: Vector2 = Vector2(60, 120)
@export var text_box_offset: Vector2 = Vector2(-76, -66)

@onready var _text_label: RichTextLabel = $TextLabel
@onready var _next_button: Button = $NextButton
@onready var _prev_button: Button = $PrevButton
@onready var _back_button: Button = $BackButton

var _current_page: int = 0
var _audio_player: AudioStreamPlayer


func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	_setup_label()
	_next_button.pressed.connect(_go_next)
	_prev_button.pressed.connect(_go_prev)
	if _back_button and _back_button.get_script() == null:
		_back_button.pressed.connect(_go_back)
	_show_page()


func _setup_label() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#00b9be")
	bg.position = text_box_offset
	bg.size = text_box_size
	add_child(bg)
	move_child(bg, _text_label.get_index())

	_text_label.set_anchors_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
	_text_label.position = text_box_offset
	_text_label.size = text_box_size
	_text_label.fit_content = false
	_text_label.scroll_active = false
	_text_label.bbcode_enabled = true
	_text_label.clip_contents = true

	var padded_style := StyleBoxEmpty.new()
	padded_style.content_margin_left = 6
	padded_style.content_margin_top = 4
	padded_style.content_margin_right = 4
	padded_style.content_margin_bottom = 4
	_text_label.add_theme_stylebox_override("normal", padded_style)

	_text_label.add_theme_font_size_override("normal_font_size", font_size)
	_text_label.add_theme_color_override("default_color", Color("#002b59"))


func _show_page() -> void:
	if pages.is_empty():
		_text_label.text = ""
		_next_button.disabled = true
		_prev_button.disabled = true
		return

	_current_page = clamp(_current_page, 0, pages.size() - 1)
	_text_label.text = pages[_current_page]

	_prev_button.disabled = _current_page == 0
	_next_button.disabled = _current_page == pages.size() - 1


func _go_next() -> void:
	if _current_page < pages.size() - 1:
		_current_page += 1
		_play_page_turn()
		_show_page()


func _go_prev() -> void:
	if _current_page > 0:
		_current_page -= 1
		_play_page_turn()
		_show_page()


func _play_page_turn() -> void:
	if page_turn_sound and _audio_player:
		_audio_player.stream = page_turn_sound
		_audio_player.play()


func _go_back() -> void:
	if not PendingBook.book_id.is_empty():
		JournalState.mark_read(PendingBook.book_id)
		PendingBook.book_id = ""
	SceneManager.go_to_scene("res://scenes/story_board.tscn")
