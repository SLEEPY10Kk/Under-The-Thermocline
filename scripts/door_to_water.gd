class_name DoorwayToWater
extends Interactable

@export var exit_spawn_position: String 

func _ready() -> void:
	prompt_text = "Exit to Water"


func interact(player: Node) -> void:
	SceneManager.exit_submarine_to_water(SubmarineState.depth, exit_spawn_position)
