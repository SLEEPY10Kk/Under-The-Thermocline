class_name EnginePart
extends Interactable

signal repaired

@export var part_id: String = "coolant_pump"  
@export var part_name: String = "Coolant Pump"
@export var engine_room_swap_chance: float = 0.3

var is_broken: bool = false


func _ready() -> void:
	add_to_group("engine_parts")
	prompt_text = "Repair " + part_name
	is_broken = SubmarineState.broken_part_ids.has(part_id)


func can_interact() -> bool:
	return enabled and is_broken


func interact(player: Node) -> void:
	_do_repair()


func _do_repair() -> void:
	SubmarineState.mark_repaired(part_id)
	is_broken = false
	repaired.emit()
	print("Fixed!")
	set_highlighted(false)

	if randf() < engine_room_swap_chance:
		SceneManager.go_to_room("engine_room", "PlayerSpawn")
