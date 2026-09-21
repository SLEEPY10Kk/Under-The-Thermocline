class_name JournalEntry
extends Area2D

enum ContentType { SCENE, NOTE }

@export var book_id: String = "book_1"
@export var content_type: ContentType = ContentType.NOTE
@export var target_scene: String = ""
@export var note_title: String = ""
@export var note_text: String = ""


func _ready() -> void:
	input_event.connect(_on_input_event)
	input_pickable = true


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if content_type == ContentType.SCENE and not JournalState.is_found(book_id):
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open()


func _open() -> void:
	match content_type:
		ContentType.SCENE:
			PendingBook.book_id = book_id
			SceneManager.go_to_scene(target_scene)
		ContentType.NOTE:
			NoteOverlay.show_note(note_title, note_text)
