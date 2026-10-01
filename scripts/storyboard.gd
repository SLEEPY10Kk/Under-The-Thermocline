class_name StoryboardTrigger
extends Interactable

@export var storyboard_scene: String = "res://scenes/story_board.tscn"

func _ready() -> void:
	prompt_text = "View Storyboard"


func interact(_player: Node) -> void:
	SceneManager.go_to_scene(storyboard_scene)
