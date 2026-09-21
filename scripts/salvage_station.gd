# SalvageStation.gd
class_name SalvageStation
extends Interactable

@export var zone_book_ids: Array[String] = ["book_1", "book_2", "book_3"]

@export var search_sound: AudioStream
@export var found_sound: AudioStream

@onready var _audio_player: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer

var _busy: bool = false


func _ready() -> void:
	prompt_text = "Check Salvage"
	SubmarineState.salvage_available_changed.connect(_on_availability_changed)
	_on_availability_changed(SubmarineState.salvage_available)


func can_interact() -> bool:
	return enabled and SubmarineState.salvage_available and not _busy


func _on_availability_changed(_available: bool) -> void:
	set_highlighted(false)


func interact(player: Node) -> void:
	_run_salvage_sequence()


func _run_salvage_sequence() -> void:
	_busy = true
	SubmarineState.set_qte_active(true)

	PromptUi.show_interact_prompt("Searching...")

	if search_sound and _audio_player:
		_audio_player.stream = search_sound
		_audio_player.play()
		await _audio_player.finished
	else:
		await get_tree().create_timer(1.2).timeout

	var zone_index: int = SubmarineState.pending_salvage_zone_index
	var found_text: String = "Nothing here..."

	if zone_index >= 0 and zone_index < zone_book_ids.size():
		var book_id: String = zone_book_ids[zone_index]
		JournalState.mark_found(book_id)
		found_text = "Found a journal entry!"

	if found_sound and _audio_player:
		_audio_player.stream = found_sound
		_audio_player.play()

	PromptUi.show_interact_prompt(found_text)
	await get_tree().create_timer(1.2).timeout

	PromptUi.hide_interact_prompt()
	SubmarineState.resume_descent()
	SubmarineState.set_qte_active(false)
	_busy = false
