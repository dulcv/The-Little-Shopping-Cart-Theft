class_name DialogueData
extends Resource

## Datos de un diálogo (docs 06-dialogos, 09-contratos).
## Todo texto = PLACEHOLDER_*. Sustitución en tiempo de uso: {alias} y {zona}.
##
## `lines` es Array[Dictionary] con claves speaker/text/emotion para que el
## .tres serialice sin sub-recursos. La clase interna DialogueLine da acceso
## tipado a cada línea (equivalente a Array[DialogueLine] del doc 06).


class DialogueLine:
	extends RefCounted
	var speaker: String = "PLACEHOLDER_speaker"
	var text: String = "PLACEHOLDER_text"
	var emotion: String = "PLACEHOLDER_emotion"

	func _init(p_speaker: String = "PLACEHOLDER_speaker", p_text: String = "PLACEHOLDER_text", p_emotion: String = "PLACEHOLDER_emotion") -> void:
		speaker = p_speaker
		text = p_text
		emotion = p_emotion

	func to_dict() -> Dictionary:
		return {"speaker": speaker, "text": text, "emotion": emotion}

	static func from_dict(d: Dictionary) -> DialogueLine:
		return DialogueLine.new(
			str(d.get("speaker", "PLACEHOLDER_speaker")),
			str(d.get("text", "PLACEHOLDER_text")),
			str(d.get("emotion", "PLACEHOLDER_emotion"))
		)

	## Aplica sustitución {alias} / {zona} al texto de la línea.
	func formatted_text(alias: String, zona: String) -> String:
		return text.replace("{alias}", alias).replace("{zona}", zona)


@export var id: String = "PLACEHOLDER_id"
@export var lines: Array[Dictionary] = []


func line_count() -> int:
	return lines.size()


func is_empty() -> bool:
	return lines.is_empty()


func get_line(index: int) -> DialogueLine:
	if index < 0 or index >= lines.size():
		return DialogueLine.new()
	var entry: Dictionary = lines[index]
	return DialogueLine.from_dict(entry)


func get_speaker(index: int) -> String:
	return get_line(index).speaker


func get_emotion(index: int) -> String:
	return get_line(index).emotion


func get_text(index: int, alias: String = "PLACEHOLDER_alias", zona: String = "PLACEHOLDER_zona") -> String:
	return get_line(index).formatted_text(alias, zona)
