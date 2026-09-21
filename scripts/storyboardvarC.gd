extends Interactable

@export var storyboard_scene: String = "res://scenes/story_boardvarC.tscn"

func _ready() -> void:
	prompt_text = "View Storyboard"


func interact(player: Node) -> void:
	SceneManager.go_to_scene(storyboard_scene)
