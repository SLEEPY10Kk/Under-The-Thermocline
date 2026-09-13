class_name EnginePart
extends Interactable

signal repaired

@export var part_name: String = "Coolant Pump"
@export var is_broken: bool = true

func _ready() -> void:
	prompt_text = "Repair " + part_name


func can_interact() -> bool:
	return enabled and is_broken


func interact(player: Node) -> void:
	_do_repair()


func _do_repair() -> void:
	is_broken = false
	repaired.emit()
	set_highlighted(false)
	print(part_name, " repaired!")


func _on_highlight_changed(value: bool) -> void:
	modulate = Color.YELLOW if value else Color.WHITE
