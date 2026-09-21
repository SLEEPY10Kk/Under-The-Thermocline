extends Control

const COLOR_DARKEST: Color = Color("#002b59")
const COLOR_MID: Color = Color("#005f8c")
const COLOR_TEAL: Color = Color("#00b9be")
const COLOR_LIGHT: Color = Color("#9ff4e5")

@export var title_text: String = "FATHOM"
@export var start_scene: String = "res://scenes/submarine_mainroom.tscn"
@export var font_size_title: int = 24
@export var font_size_button: int = 12

@onready var _start_button: Button = $VBoxContainer/StartButton
@onready var _quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	SubmarineState.set_player_inside(true)
	SceneManager.go_to_scene(start_scene, "PlayerSpawn")


func _on_quit_pressed() -> void:
	get_tree().quit()
