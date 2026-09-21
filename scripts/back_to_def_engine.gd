extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	SceneManager.go_to_default_engine_room("PlayerSpawn")
