extends Node

signal part_broken(part: EnginePart)

@export var depth: float = 0.0
@export var milestone_interval: float = 500.0 
@export var break_chance: float = 0.35        

var _last_milestone_checked: float = 0.0


func set_depth(value: float) -> void:
	var new_depth: float = max(value, 0.0)
	depth = new_depth
	_check_milestones()


func _check_milestones() -> void:
	var current_milestone: float = floor(depth / milestone_interval) * milestone_interval
	if current_milestone > _last_milestone_checked:
		_last_milestone_checked = current_milestone
		if randf() < break_chance:
			_trigger_random_part_break()


func _trigger_random_part_break() -> void:
	var parts := get_tree().get_nodes_in_group("engine_parts")
	var working_parts: Array = []
	for p in parts:
		if p is EnginePart and not p.is_broken:
			working_parts.append(p)

	if working_parts.is_empty():
		return 

	var chosen: EnginePart = working_parts[randi() % working_parts.size()]
	chosen.break_part()
	part_broken.emit(chosen)
