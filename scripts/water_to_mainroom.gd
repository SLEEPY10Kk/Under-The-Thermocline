class_name DoorwayToSubmarine
extends Interactable

@export var spawn_point_name: String = "PlayerSpawn" 

func _ready() -> void:
	prompt_text = "Enter Submarine"


func interact(player: Node) -> void:
	SubmarineState.set_player_inside(true)
	SceneManager.go_to_room("main_room", spawn_point_name)
