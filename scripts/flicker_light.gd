extends PointLight2D

@export var base_energy: float = 1.0
@export var flicker_strength: float = 0.08
@export var pulse_speed: float = 3.5
@export var random_jitter: float = 0.04

var _time: float = 0.0


func _ready() -> void:
	_time = randf() * 100.0


func _process(delta: float) -> void:
	_time += delta * pulse_speed
	var pulse: float = sin(_time) * flicker_strength
	var jitter: float = (randf() - 0.5) * random_jitter
	energy = max(0.1, base_energy + pulse + jitter)
