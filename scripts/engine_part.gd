class_name EnginePart
extends Interactable

signal repaired

@export var part_id: String = "coolant_pump"
@export var part_name: String = "Coolant Pump"
@export var engine_room_swap_chance: float = 0.3
@export var qte_scene: PackedScene = preload("res://scenes/qte.tscn")

@onready var _sprite: AnimatedSprite2D = get_node_or_null("../AnimatedSprite2D") as AnimatedSprite2D

var is_broken: bool = false
var _qte_active: bool = false


func _ready() -> void:
	add_to_group("engine_parts")
	prompt_text = "Repair " + part_name
	SubmarineState.part_display_names[part_id] = part_name
	is_broken = SubmarineState.broken_part_ids.has(part_id)
	_update_sprite()


func can_interact() -> bool:
	return enabled and is_broken and not _qte_active


func interact(_player: Node) -> void:
	_start_qte()


func set_broken(value: bool) -> void:
	is_broken = value
	_update_sprite()


func _update_sprite() -> void:
	if not _sprite:
		push_warning("EnginePart: no AnimatedSprite2D found for %s" % name)
		return
	_sprite.play("broken" if is_broken else "fine")


func _start_qte() -> void:
	_qte_active = true
	SubmarineState.set_qte_active(true)
	PromptUi.show_interact_prompt("Press W or Space to Align")

	var layer := CanvasLayer.new()
	layer.layer = 90
	get_tree().current_scene.add_child(layer)

	var qte := qte_scene.instantiate()
	layer.add_child(qte)

	await get_tree().process_frame
	qte.position = get_viewport().get_visible_rect().size / 2.0 - qte.size / 2.0

	qte.succeeded.connect(_on_qte_succeeded.bind(qte, layer))
	qte.failed.connect(_on_qte_failed.bind(qte, layer))


func _on_qte_succeeded(_qte: Node, layer: Node) -> void:
	layer.queue_free()
	_qte_active = false
	SubmarineState.set_qte_active(false)
	PromptUi.hide_interact_prompt()
	PromptUi.show_temporary(part_name + " Repaired!", 1.5)
	_do_repair()


func _on_qte_failed(_qte: Node, layer: Node) -> void:
	layer.queue_free()
	_qte_active = false
	SubmarineState.set_qte_active(false)
	PromptUi.hide_interact_prompt()
	PromptUi.show_temporary("Repair Failed!", 1.5)


func _do_repair() -> void:
	SubmarineState.mark_repaired(part_id)
	set_broken(false)
	repaired.emit()
	set_highlighted(false)
