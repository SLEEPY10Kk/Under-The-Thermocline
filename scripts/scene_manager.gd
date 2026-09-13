extends Node

var depth_zones: Array[Dictionary] = [
	{ "max_depth": 1000.0, "scene": "res://scenes/L0.tscn" },
	{ "max_depth": 2000.0, "scene": "res://scenes/L1.tscn" },
	{ "max_depth": 3000.0,   "scene": "res://scenes/L2.tscn" },
	{ "max_depth": 4000.0,  "scene": "res://scenes/L3.tscn" },
	{ "max_depth": 5000.0, "scene": "res://scenes/L4.tscn" },
	{ "max_depth": 7000.0, "scene": "res://scenes/L5.tscn" },
	{ "max_depth": 9000.0,   "scene": "res://scenes/L6.tscn" },
	{ "max_depth": 1000.0,  "scene": "res://scenes/L7.tscn" }
]

var interior_rooms: Dictionary = {
	"main_room":   "res://scenes/submarine_mainroom.tscn",
	"engine_room": "res://scenes/submarine_engineroom.tscn",
}

var current_scene_path: String = ""
var _pending_spawn_position: Vector2 = Vector2.ZERO

func _change_scene(target_scene: String, spawn_position: Vector2, on_ready_callback: Callable) -> void:
	if target_scene == current_scene_path:
		_reposition_player(spawn_position)
		on_ready_callback.call()
		return

	current_scene_path = target_scene
	_pending_spawn_position = spawn_position

	get_tree().change_scene_to_file(target_scene)
	await get_tree().process_frame
	_reposition_player(spawn_position)
	on_ready_callback.call()


func _reposition_player(pos: Vector2) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = pos
	else:
		push_warning("SceneManager: no node in group 'player' found to reposition.")


func get_scene_for_depth(depth: float) -> String:
	for zone in depth_zones:
		if depth < zone["max_depth"]:
			return zone["scene"]
	return depth_zones[-1]["scene"]


func exit_submarine_to_water(submarine_depth: float, spawn_position: Vector2) -> void:
	var target_scene: String = get_scene_for_depth(submarine_depth)
	await _change_scene(target_scene, spawn_position, func():
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("exit_submarine"):
			player.exit_submarine()
	)


func go_to_room(room_name: String, spawn_position: Vector2) -> void:
	if not interior_rooms.has(room_name):
		push_error("SceneManager: unknown room '%s'" % room_name)
		return

	var target_scene: String = interior_rooms[room_name]
	await _change_scene(target_scene, spawn_position, func():
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("enter_submarine"):
			player.enter_submarine()
	)
