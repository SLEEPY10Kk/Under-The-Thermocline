extends Node

signal part_broken(part_id: String)

@export var depth: float = 0.0
@export var descent_rate: float = 20.0
@export var milestone_interval: float = 500.0
@export var break_chance: float = 0.35

var all_part_ids: Array[String] = [
	"coolant_pump",
	#"ballast_pump",
	#"air_compressor",
	#"co2_scrubber",
	#"drive_shaft",
	#"hydraulic_line",
	#"bilge_pump",
	#"emergency_blow_valve",
]

var broken_part_ids: Array[String] = []
var player_inside: bool = true
var _last_milestone_checked: float = 0.0


func _process(delta: float) -> void:
	if can_descend():
		print(depth)
		set_depth(depth + descent_rate * delta)


func can_descend() -> bool:
	return player_inside and not is_submarine_broken()


func is_submarine_broken() -> bool:
	return not broken_part_ids.is_empty()


func set_player_inside(value: bool) -> void:
	player_inside = value


func set_depth(value: float) -> void:
	depth = max(value, 0.0)
	_check_milestones()


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
	print("BROKE: ", part_id)
	part_broken.emit(part_id)

	_sync_live_part(part_id, true)


func mark_repaired(part_id: String) -> void:
	broken_part_ids.erase(part_id)
	_sync_live_part(part_id, false)


func _sync_live_part(part_id: String, broken: bool) -> void:
	for p in get_tree().get_nodes_in_group("engine_parts"):
		if p is EnginePart and p.part_id == part_id:
			p.is_broken = broken
