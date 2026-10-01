extends Node2D

const TRIGGER_X: float = 2000.0
const END_X: float = -4450.0

var _warped: bool = false
var _player: CharacterBody2D


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func _process(_delta: float) -> void:
	if _warped:
		return

	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		return

	# When player walking left reaches 2000, fade out and warp to the end
	if _player.global_position.x <= TRIGGER_X:
		_warped = true
		_warp_to_end()


func _warp_to_end() -> void:
	await TransitionLayer.fade_out(0.6)

	if _player and is_instance_valid(_player):
		_player.global_position.x = END_X
		_player.velocity = Vector2.ZERO

	await get_tree().process_frame
	await TransitionLayer.fade_in(0.6)
