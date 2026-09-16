extends Area2D

@export var target_room: String = "main_room"
@export var spawn_marker: String

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SceneManager.go_to_room(target_room, spawn_marker)
