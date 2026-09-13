extends Area2D

@export var target_room: String = "engine_room"
@export var spawn_marker: Marker2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SceneManager.go_to_room(target_room, spawn_marker.global_position)
