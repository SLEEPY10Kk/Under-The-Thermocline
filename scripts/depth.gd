extends Label

func _process(_delta: float) -> void:
	text = "DEPTH: %dm" % int(SubmarineState.depth)
