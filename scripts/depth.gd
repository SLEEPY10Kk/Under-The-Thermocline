extends Label

func _ready() -> void:
	var font: FontFile = load("res://Early GameBoy.ttf") as FontFile
	if font:
		add_theme_font_override("font", font)
		add_theme_font_size_override("font_size", 8)
		add_theme_color_override("font_color", Color("#00b9be"))


func _process(_delta: float) -> void:
	text = "DEPTH: %dm" % int(SubmarineState.depth)
