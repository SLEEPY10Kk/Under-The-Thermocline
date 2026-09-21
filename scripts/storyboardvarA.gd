extends Interactable

@export var storyboard_scene: String = "res://scenes/story_boardvarA.tscn"

func _ready() -> void:
	prompt_text = "View Storyboard"


func interact(player: Node) -> void:
	SceneManager.go_to_scene(storyboard_scene)
