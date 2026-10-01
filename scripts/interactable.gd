class_name Interactable
extends Area2D

@export var prompt_text: String = "Interact"
@export var enabled: bool = true

var is_highlighted: bool = false


func can_interact() -> bool:
	return enabled


func interact(_player: Node) -> void:
	push_warning("Interactable: interact() not implemented on %s" % name)


func set_highlighted(value: bool) -> void:
	is_highlighted = value
	_on_highlight_changed(value)


func _on_highlight_changed(_value: bool) -> void:
	pass
