extends Node

signal part_broken(part_id: String)
signal depth_changed(new_depth: float)
signal salvage_available_changed(available: bool)

@export var part_broken_sound: AudioStream
@export var descent_stopped_sound: AudioStream
@export var descent_resumed_sound: AudioStream
@export var depth: float = 0.0
@export var descent_rate: float = 100.0
@export var milestone_interval: float = 1000.0
@export var break_chance: float = 0.35

var _sfx_player: AudioStreamPlayer
var _descent_audio_player: AudioStreamPlayer

var qte_active: bool = false
var salvage_available: bool = false
var halted_at_boundary: bool = false
var pending_salvage_zone_index: int = -1
var in_main_room: bool = false
var reading_note: bool = false

var all_part_ids: Array[String] = [
	"coolant_pump",
	"air_compressor",
	"emergency_blow_valve",
	"wiring",
]
var part_display_names: Dictionary = {
	"coolant_pump": "Coolant Pump",
	"air_compressor": "Air Compressor",
	"emergency_blow_valve": "Emergency Blow Valve",
	"wiring": "Wiring",
}
var broken_part_ids: Array[String] = []
var player_inside: bool = false
var _last_milestone_checked: float = 0.0

const MAX_DEPTH: float = 10000.0

var reached_bottom: bool = false

func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SfxPlayer"
	add_child(_sfx_player)

	_descent_audio_player = AudioStreamPlayer.new()
	_descent_audio_player.name = "DescentAudioPlayer"
	_descent_audio_player.volume_db = -6.0
	add_child(_descent_audio_player)
	_descent_audio_player.finished.connect(_on_descent_audio_finished)

	if not descent_resumed_sound:
		descent_resumed_sound = preload("res://audio/sub.wav")
	if not descent_stopped_sound:
		descent_stopped_sound = preload("res://audio/subSTOP.wav")
	if not part_broken_sound:
		part_broken_sound = preload("res://audio/final_cut.wav")

	part_broken.connect(_on_part_broken)


func reset_state() -> void:
	depth = 0.0
	reached_bottom = false
	halted_at_boundary = false
	pending_salvage_zone_index = -1
	broken_part_ids.clear()
	_last_milestone_checked = 0.0
	salvage_available = false
	reading_note = false
	qte_active = false
	_update_descent_audio(false)
	depth_changed.emit(0.0)
	salvage_available_changed.emit(false)


func _on_part_broken(part_id: String) -> void:
	var display_name: String = part_display_names.get(part_id, part_id)
	PromptUi.show_temporary(display_name + " broke!")
	_play_sfx(part_broken_sound)


func _process(delta: float) -> void:
	var descending: bool = can_descend()
	_update_descent_audio(descending)
	if descending:
		set_depth(depth + descent_rate * delta)


func _update_descent_audio(is_descending: bool) -> void:
	if not _descent_audio_player:
		return

	if is_descending:
		var stream: AudioStream = descent_resumed_sound
		if stream and not _descent_audio_player.playing:
			if stream is AudioStreamWAV:
				(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
			_descent_audio_player.stream = stream
			_descent_audio_player.play()
	else:
		if _descent_audio_player.playing:
			_descent_audio_player.stop()


func _on_descent_audio_finished() -> void:
	if can_descend() and _descent_audio_player:
		_descent_audio_player.play()


func can_descend() -> bool:
	return in_main_room and not is_submarine_broken() and not reached_bottom and not halted_at_boundary and not reading_note


func is_submarine_broken() -> bool:
	return not broken_part_ids.is_empty()


func set_player_inside(value: bool) -> void:
	player_inside = value


func set_in_main_room(value: bool) -> void:
	in_main_room = value


func set_reading_note(value: bool) -> void:
	reading_note = value


func set_depth(value: float) -> void:
	depth = clamp(value, 0.0, MAX_DEPTH)
	depth_changed.emit(depth)
	_check_milestones()

	if depth >= MAX_DEPTH and not reached_bottom:
		reached_bottom = true
		_on_reached_bottom()


func _on_reached_bottom() -> void:
	print("Reached maximum depth — entering final scene.")
	_update_descent_audio(false)
	PromptUi.show_temporary("10000m reached", 2.0)
	await get_tree().create_timer(1.2).timeout
	SceneManager.go_to_final_scene()


func _check_milestones() -> void:
	var current_milestone: float = floor(depth / milestone_interval) * milestone_interval
	if current_milestone > _last_milestone_checked:
		_last_milestone_checked = current_milestone
		print("Milestone reached: ", current_milestone)
		if randf() < break_chance:
			_trigger_random_part_break()


func _trigger_random_part_break() -> void:
	var working: Array[String] = all_part_ids.filter(func(id): return not broken_part_ids.has(id))
	if working.is_empty():
		return

	var chosen: String = working[randi() % working.size()]
	mark_broken(chosen)


func mark_broken(part_id: String) -> void:
	if broken_part_ids.has(part_id):
		return
	broken_part_ids.append(part_id)
	part_broken.emit(part_id)
	_sync_live_part(part_id, true)


func mark_repaired(part_id: String) -> void:
	broken_part_ids.erase(part_id)
	_sync_live_part(part_id, false)


func _sync_live_part(part_id: String, broken: bool) -> void:
	for p in get_tree().get_nodes_in_group("engine_parts"):
		if p is EnginePart and p.part_id == part_id:
			p.set_broken(broken)


func set_qte_active(value: bool) -> void:
	qte_active = value


func halt_at_boundary(zone_index: int) -> void:
	halted_at_boundary = true
	pending_salvage_zone_index = zone_index
	set_salvage_available(true)
	_update_descent_audio(false)
	_play_sfx(descent_stopped_sound)


func resume_descent() -> void:
	halted_at_boundary = false
	pending_salvage_zone_index = -1
	set_salvage_available(false)
	_update_descent_audio(can_descend())


func set_salvage_available(value: bool) -> void:
	salvage_available = value
	salvage_available_changed.emit(value)


func _play_sfx(stream: AudioStream) -> void:
	if stream and _sfx_player:
		_sfx_player.stream = stream
		_sfx_player.play()
