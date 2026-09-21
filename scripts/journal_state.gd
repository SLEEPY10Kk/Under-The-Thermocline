extends Node

signal book_found(book_id: String)
signal book_read(book_id: String)

var found_book_ids: Array[String] = []
var read_book_ids: Array[String] = []

func mark_found(book_id: String) -> void:
	if not found_book_ids.has(book_id):
		found_book_ids.append(book_id)
		book_found.emit(book_id)


func mark_read(book_id: String) -> void:
	if not read_book_ids.has(book_id):
		read_book_ids.append(book_id)
		book_read.emit(book_id)


func is_found(book_id: String) -> bool:
	return found_book_ids.has(book_id)


func found_count() -> int:
	return found_book_ids.size()
