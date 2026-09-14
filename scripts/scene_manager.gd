extends Node

const NUM_ZONES: int = 5
const FIXED_FINAL_DEPTH: float = 10000.0
const MIN_GAP: float = 500.0
const MAX_GAP: float = 3000.0

const ZONE_SCENES: Array[String] = [
	"res://scenes/L0.tscn",
	"res://scenes/L1.tscn",
	"res://scenes/L2.tscn",
	"res://scenes/L3.tscn",
	"res://scenes/L4.tscn",
]

var depth_zones: Array[Dictionary] = []
var _zones_generated: bool = false

var engine_room_variants: Array[String] = [
	"res://scenes/submarine_engineroom.tscn",
	"res://scenes/submarine_engineroom_variant_b.tscn",
	"res://scenes/submarine_engineroom_variant_c.tscn",
]

var interior_rooms: Dictionary = {
	"main_room":   "res://scenes/submarine_mainroom.tscn",
	"engine_room": "res://scenes/submarine_engineroom.tscn",
}

var current_scene_path: String = ""
var _pending_spawn_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_generate_depth_zones()


func _generate_depth_zones() -> void:
	if _zones_generated:
		return

	var boundaries: Array[float] = []
	var attempts: int = 0

	var min_gap_steps: int = int(MIN_GAP / 5.0)
	var max_gap_steps: int = int(MAX_GAP / 5.0)  
	var final_depth_steps: int = int(FIXED_FINAL_DEPTH / 5.0)

	while attempts < 10000:
		attempts += 1
		boundaries.clear()
		var prev_steps: int = 0
		var valid: bool = true

		for i in range(NUM_ZONES - 1):
			var gap_steps: int = randi_range(min_gap_steps, max_gap_steps)
			var next_steps: int = prev_steps + gap_steps
			if next_steps >= final_depth_steps - min_gap_steps:
				valid = false
				break
			boundaries.append(float(next_steps * 5))
			prev_steps = next_steps

		if not valid:
			continue

		var final_gap_steps: int = final_depth_steps - prev_steps
		if final_gap_steps < min_gap_steps or final_gap_steps > max_gap_steps:
			continue

		boundaries.append(FIXED_FINAL_DEPTH)
		break

	if boundaries.size() != NUM_ZONES:
		push_error("SceneManager: failed to generate valid depth zones, using fallback even spacing.")
		boundaries.clear()
		var step: float = FIXED_FINAL_DEPTH / NUM_ZONES
		for i in range(NUM_ZONES):
			boundaries.append(round((step * (i + 1)) / 5.0) * 5.0)

	depth_zones.clear()
	for i in range(NUM_ZONES):
		depth_zones.append({
			"max_depth": boundaries[i],
			"scene": ZONE_SCENES[i],
		})

	_zones_generated = true


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


func _change_scene(target_scene: String, spawn_point_name: String, on_ready_callback: Callable) -> void:
	call_deferred("_do_change_scene", target_scene, spawn_point_name, on_ready_callback)


func _do_change_scene(target_scene: String, spawn_point_name: String, on_ready_callback: Callable) -> void:
	var new_scene_resource: PackedScene = load(target_scene)
	if new_scene_resource == null:
		push_error("SceneManager: failed to load scene at %s" % target_scene)
		return

	var old_scene: Node = get_tree().current_scene
	var new_scene: Node = new_scene_resource.instantiate()

	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

	if old_scene:
		old_scene.queue_free()

	current_scene_path = target_scene

	await get_tree().process_frame

	if spawn_point_name.is_empty():
		push_warning("SceneManager: spawn_point_name was empty — check the caller passed a valid marker name.")
	else:
		var spawn_point: Node = new_scene.find_child(spawn_point_name, true, false)
		if spawn_point == null:
			push_warning("SceneManager: spawn point '%s' not found in %s" % [spawn_point_name, new_scene.name])
		else:
			var player := get_tree().get_first_node_in_group("player")
			if player == null:
				push_warning("SceneManager: no node in group 'player' found to reposition.")
			else:
				player.global_position = spawn_point.global_position

	on_ready_callback.call()


func exit_submarine_to_water(submarine_depth: float, spawn_point_name: String = "PlayerSpawn") -> void:
	var target_scene: String = get_scene_for_depth(submarine_depth)
	await _change_scene(target_scene, spawn_point_name, func():
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("exit_submarine"):
			player.exit_submarine()
	)


func go_to_room(room_name: String, spawn_point_name: String = "PlayerSpawn", allow_variant_swap: bool = false) -> void:
	if not interior_rooms.has(room_name):
		push_error("SceneManager: unknown room '%s'" % room_name)
		return

	var target_scene: String = interior_rooms[room_name]

	if room_name == "engine_room" and allow_variant_swap and engine_room_variants.size() > 1:
		var choices: Array[String] = engine_room_variants.filter(func(s): return s != target_scene)
		if choices.is_empty():
			choices = engine_room_variants
		target_scene = choices[randi() % choices.size()]
		interior_rooms["engine_room"] = target_scene  

	await _change_scene(target_scene, spawn_point_name, func():
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("enter_submarine"):
			player.enter_submarine()
	)
