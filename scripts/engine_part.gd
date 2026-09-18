class_name EnginePart
extends Interactable

signal repaired

@export var part_id: String = "coolant_pump"
@export var part_name: String = "Coolant Pump"
@export var engine_room_swap_chance: float = 0.3
@export var qte_scene: PackedScene = preload("res://scenes/qte.tscn")

var is_broken: bool = false
var _qte_active: bool = false


func _ready() -> void:
	add_to_group("engine_parts")
	prompt_text = "Repair " + part_name
	is_broken = SubmarineState.broken_part_ids.has(part_id)


func can_interact() -> bool:
	return enabled and is_broken and not _qte_active


func interact(player: Node) -> void:
	_start_qte()


func _start_qte() -> void:
	_qte_active = true
	var qte := qte_scene.instantiate()
	get_tree().current_scene.add_child(qte)
	qte.global_position = get_viewport().get_visible_rect().size / 2.0 - qte.size / 2.0

	qte.succeeded.connect(_on_qte_succeeded.bind(qte))
	qte.failed.connect(_on_qte_failed.bind(qte))


func _on_qte_succeeded(qte: Node) -> void:
	qte.queue_free()
	_qte_active = false
	_do_repair()


func _on_qte_failed(qte: Node) -> void:
	qte.queue_free()
	_qte_active = false


func _do_repair() -> void:
	SubmarineState.mark_repaired(part_id)
	is_broken = false
	repaired.emit()
	set_highlighted(false)
	SceneManager.go_to_room("engine_room", "PlayerSpawn")
