class_name EnginePart
extends Interactable

signal repaired
signal broken

@export var part_name: String = "Coolant Pump"
@export var is_broken: bool = false

@export var engine_room_swap_chance: float = 0.3  

func _ready() -> void:
	add_to_group("engine_parts")
	prompt_text = "Repair " + part_name


func can_interact() -> bool:
	return enabled and is_broken


func interact(player: Node) -> void:
	_do_repair()


func break_part() -> void:
	is_broken = true
	broken.emit()
	print(part_name, " broke!")


func _do_repair() -> void:
	is_broken = false
	repaired.emit()
	set_highlighted(false)
	print(part_name, " repaired!")

	if randf() < engine_room_swap_chance:
		SceneManager.go_to_room("engine_room", "PlayerSpawn", true)


func _on_highlight_changed(value: bool) -> void:
	modulate = Color.YELLOW if value else Color.WHITE
