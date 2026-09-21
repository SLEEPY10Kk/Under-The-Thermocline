extends Node2D

const COLOR_LIGHT: Color = Color("#9ff4e5")

@export var video_animation_name: String = "video"
@export var font_size: int = 12
@export var scroll_speed: float = 30.0

@export_multiline var ending_text: String = """the deeper you go, the clearer it gets.

that was the lie it told them.

clarity was never the cure — it was the invitation.

something down here has been waiting long enough that waiting stopped meaning anything. it does not think. it does not need to. it only needs you to.

the crew is gone. the door remains, or it doesn't, depending on whether anyone is left to look at it.

you made it further than they did.

that was never the achievement it sounds like."""

@onready var _video_sprite: AnimatedSprite2D = $VideoSprite

var _canvas_layer: CanvasLayer
var _scroll_viewport: Control
var _text_label: Label


func _ready() -> void:
	_build_scroll_ui()

	_video_sprite.animation_finished.connect(_on_video_finished)
	_video_sprite.play(video_animation_name)


func _build_scroll_ui() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	add_child(_canvas_layer)

	_scroll_viewport = Control.new()
	_scroll_viewport.position = Vector2.ZERO
	_scroll_viewport.size = screen_size
	_scroll_viewport.clip_contents = true
	_scroll_viewport.visible = false
	_canvas_layer.add_child(_scroll_viewport)

	_text_label = Label.new()
	_text_label.text = ending_text
	_text_label.position = Vector2.ZERO
	_text_label.custom_minimum_size = Vector2(screen_size.x, 0)
	_text_label.size = Vector2(screen_size.x, 0)
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text_label.add_theme_font_size_override("font_size", font_size)
	_text_label.add_theme_color_override("font_color", COLOR_LIGHT)
	_scroll_viewport.add_child(_text_label)

	await get_tree().process_frame  
	_text_label.size.x = screen_size.x

func _on_video_finished() -> void:
	await TransitionLayer.fade_out()

	_video_sprite.visible = false
	_start_scroll()

	await TransitionLayer.fade_in()


func _start_scroll() -> void:
	_scroll_viewport.visible = true

	var viewport_height: float = _scroll_viewport.size.y
	var text_height: float = _text_label.get_combined_minimum_size().y

	_text_label.position.y = viewport_height
	var end_y: float = -text_height

	var distance: float = _text_label.position.y - end_y
	var duration: float = distance / scroll_speed

	var tween := create_tween()
	tween.tween_property(_text_label, "position:y", end_y, duration)
