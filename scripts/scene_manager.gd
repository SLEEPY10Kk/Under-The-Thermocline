extends Node

signal salvage_boundary_reached(zone_index: int, depth: float)

const NUM_ZONES: int = 5
const FIXED_FINAL_DEPTH: float = 10000.0
const MIN_GAP: float = 500.0
const MAX_GAP: float = 3000.0
const FINAL_SCENE: String = "res://scenes/final.tscn"

var depth_zones: Array[Dictionary] = []
var _zones_generated: bool = false
var _last_zone_triggered: int = -1

@export var engine_room_variant_min_depth: float = 5000.0


var engine_room_variants: Array[String] = [
	"res://scenes/submarine_engineroom.tscn",
	"res://scenes/submarine_engineroom_varC.tscn",
	"res://scenes/submarine_engineroom_varB.tscn",
	"res://scenes/submarine_engineroom_varA.tscn",
]

var interior_rooms: Dictionary = {
	"main_room":   "res://scenes/submarine_mainroom.tscn",
	"engine_room": "res://scenes/submarine_engineroom.tscn",
}

var _next_variant_index: int = 1
var _pending_variants: Array[String] = []
var _experienced_variants: Dictionary = {}

var variant_start_sound: AudioStream = preload("res://audio/variant start.wav")
var variant_ambient_sound: AudioStream = preload("res://audio/variant.wav")
var _sfx_player: AudioStreamPlayer
var _variant_ambient_player: AudioStreamPlayer

var current_scene_path: String = ""
var _transitioning: bool = false

func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SceneManagerSfx"
	add_child(_sfx_player)

	_variant_ambient_player = AudioStreamPlayer.new()
	_variant_ambient_player.name = "VariantAmbientPlayer"
	_variant_ambient_player.volume_db = -8.0
	if variant_ambient_sound is AudioStreamWAV:
		(variant_ambient_sound as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_variant_ambient_player.stream = variant_ambient_sound
	_variant_ambient_player.finished.connect(_on_variant_ambient_finished)
	add_child(_variant_ambient_player)

	_generate_depth_zones()
	SubmarineState.depth_changed.connect(_on_depth_changed)
	JournalState.book_read.connect(_on_book_read)
	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path
		_update_variant_ambience(current_scene_path)


func _on_book_read(_book_id: String) -> void:
	if _next_variant_index < engine_room_variants.size():
		var variant: String = engine_room_variants[_next_variant_index]
		if not _experienced_variants.has(variant) and not _pending_variants.has(variant):
			_pending_variants.append(variant)
			interior_rooms["engine_room"] = variant
		_next_variant_index += 1


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
		depth_zones.append({ "max_depth": boundaries[i] })

	_zones_generated = true


func _on_depth_changed(new_depth: float) -> void:
	for i in range(depth_zones.size()):
		var boundary: float = depth_zones[i]["max_depth"]
		if new_depth >= boundary and i > _last_zone_triggered:
			_last_zone_triggered = i
			SubmarineState.depth = boundary
			salvage_boundary_reached.emit(i, boundary)
			SubmarineState.halt_at_boundary(i)


func go_to_scene(target_scene: String, spawn_point_name: String = "") -> void:
	await _change_scene(target_scene, spawn_point_name, func():
		SubmarineState.set_in_main_room(false)
	)


func go_to_room(room_name: String, spawn_point_name: String = "PlayerSpawn") -> void:
	if not interior_rooms.has(room_name):
		push_error("SceneManager: unknown room '%s'" % room_name)
		return

	var target_scene: String = interior_rooms[room_name]
	if room_name == "engine_room":
		if not _pending_variants.is_empty():
			target_scene = _pending_variants.pop_front()
			_experienced_variants[target_scene] = true
			if variant_start_sound and _sfx_player:
				_sfx_player.stream = variant_start_sound
				_sfx_player.play()
		else:
			target_scene = engine_room_variants[0]
		interior_rooms["engine_room"] = _pending_variants[0] if not _pending_variants.is_empty() else engine_room_variants[0]

		if current_scene_path == target_scene:
			return

	await _change_scene(target_scene, spawn_point_name, func():
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("enter_submarine"):
			player.enter_submarine()
		SubmarineState.set_in_main_room(room_name == "main_room")
	)


func go_to_default_engine_room(spawn_point_name: String = "PlayerSpawn") -> void:
	var default_scene: String = engine_room_variants[0]
	interior_rooms["engine_room"] = _pending_variants[0] if not _pending_variants.is_empty() else default_scene
	await _change_scene(default_scene, spawn_point_name, func():
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("enter_submarine"):
			player.enter_submarine()
		SubmarineState.set_in_main_room(false)
	)


func go_to_final_scene() -> void:
	if _transitioning:
		return
	_transitioning = true

	# Longer dramatic fade out
	await TransitionLayer.fade_out(1.2)

	# Interstitial message before cutscene
	await TransitionLayer.show_message("10000m reached", 2.2, 0.6)
	await get_tree().create_timer(0.4).timeout

	var new_scene_resource: PackedScene = load(FINAL_SCENE)
	if new_scene_resource == null:
		push_error("SceneManager: failed to load scene at %s" % FINAL_SCENE)
		_transitioning = false
		await TransitionLayer.fade_in(1.2)
		return

	var old_scene: Node = get_tree().current_scene
	var new_scene: Node = new_scene_resource.instantiate()

	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

	if old_scene:
		old_scene.queue_free()

	current_scene_path = FINAL_SCENE
	PromptUi.detach()
	_update_variant_ambience(current_scene_path)

	await get_tree().process_frame

	# Longer fade in to the cutscene
	await TransitionLayer.fade_in(1.2)
	_transitioning = false


func _change_scene(target_scene: String, spawn_point_name: String, on_ready_callback: Callable) -> void:
	await _do_change_scene(target_scene, spawn_point_name, on_ready_callback)


func _do_change_scene(target_scene: String, spawn_point_name: String, on_ready_callback: Callable) -> void:
	if _transitioning:
		return
	_transitioning = true

	await TransitionLayer.fade_out()

	var new_scene_resource: PackedScene = load(target_scene)
	if new_scene_resource == null:
		push_error("SceneManager: failed to load scene at %s" % target_scene)
		_transitioning = false
		await TransitionLayer.fade_in()
		return

	var old_scene: Node = get_tree().current_scene
	var new_scene: Node = new_scene_resource.instantiate()

	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

	if old_scene:
		old_scene.queue_free()

	current_scene_path = target_scene
	PromptUi.detach()
	_update_variant_ambience(current_scene_path)

	await get_tree().process_frame

	if not spawn_point_name.is_empty():
		var spawn_point: Node = new_scene.find_child(spawn_point_name, true, false)
		if spawn_point == null:
			if spawn_point_name == "PlayerSpawn":
				spawn_point = new_scene.find_child("spawn_marker", true, false)
			elif spawn_point_name == "spawn_marker":
				spawn_point = new_scene.find_child("PlayerSpawn", true, false)

		if spawn_point == null:
			var player := get_tree().get_first_node_in_group("player")
			if player != null:
				push_warning("SceneManager: spawn point '%s' not found in %s" % [spawn_point_name, new_scene.name])
		else:
			var player := get_tree().get_first_node_in_group("player")
			if player == null:
				push_warning("SceneManager: no node in group 'player' found to reposition.")
			else:
				player.global_position = spawn_point.global_position
				PromptUi.attach_to_player(player)

	on_ready_callback.call()

	await TransitionLayer.fade_in()
	_transitioning = false


func _update_variant_ambience(scene_path: String) -> void:
	if not _variant_ambient_player:
		return
	var is_variant: bool = (
		scene_path.contains("submarine_engineroom_var") or
		scene_path.contains("story_boardvar")
	)
	if is_variant:
		if not _variant_ambient_player.playing:
			_variant_ambient_player.play()
	else:
		if _variant_ambient_player.playing:
			_variant_ambient_player.stop()


func _on_variant_ambient_finished() -> void:
	if not _variant_ambient_player:
		return
	var is_variant: bool = (
		current_scene_path.contains("submarine_engineroom_var") or
		current_scene_path.contains("story_boardvar")
	)
	if is_variant:
		_variant_ambient_player.play()


func reset_state() -> void:
	_last_zone_triggered = -1
	_next_variant_index = 1
	_pending_variants.clear()
	_experienced_variants.clear()
	interior_rooms["engine_room"] = engine_room_variants[0]
	_zones_generated = false
	_generate_depth_zones()
	if _variant_ambient_player and _variant_ambient_player.playing:
		_variant_ambient_player.stop()
	_transitioning = false
