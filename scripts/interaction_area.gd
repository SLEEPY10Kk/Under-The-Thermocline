extends Area2D

@export var interact_action: String = "interact"

var _nearby: Array[Interactable] = []
var _current: Interactable = null


func _ready() -> void:
	pass


func _physics_process(_delta: float) -> void:
	_update_closest()

	if Input.is_action_just_pressed(interact_action) and _current and _current.can_interact():
		_current.interact(get_parent())


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable:
		_nearby.append(area)


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable and _nearby.has(area):
		_nearby.erase(area)
		if _current == area:
			_current.set_highlighted(false)
			_current = null


func _update_closest() -> void:
	var closest: Interactable = null
	var closest_dist: float = INF

	for i in _nearby:
		if not is_instance_valid(i) or not i.can_interact():
			continue
		var dist: float = global_position.distance_squared_to(i.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = i

	if closest != _current:
		if _current:
			_current.set_highlighted(false)
		_current = closest
		if _current:
			_current.set_highlighted(true)


func get_current_interactable() -> Interactable:
	return _current
