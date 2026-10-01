extends AnimatedSprite2D

func _ready() -> void:
	_update_animation()
	JournalState.book_found.connect(_on_book_found)


func _on_book_found(_id: String) -> void:
	_update_animation()


func _update_animation() -> void:
	if not sprite_frames:
		return
	var count: int = JournalState.found_count()
	var anim_name: String = str(count)

	if sprite_frames.has_animation(anim_name):
		animation = anim_name
		stop()  
		frame = 0
	elif sprite_frames.has_animation("default"):
		animation = "default"
		stop()
		frame = 0
