extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if not PendingBook.book_id.is_empty():
		JournalState.mark_read(PendingBook.book_id)
		PendingBook.book_id = ""

	SceneManager.go_to_scene("res://scenes/story_board.tscn")
