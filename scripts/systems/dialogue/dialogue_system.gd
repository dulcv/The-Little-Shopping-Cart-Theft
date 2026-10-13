extends Node

## Sistema de diálogos (docs 06-dialogos, 09-contratos).
## Autoload-READY SIN REGISTRAR: no se toca project.godot. Para activarlo,
## añadir este script como Autoload "DialogueSystem" (otro agente / manual).
## También funciona instanciado en una escena (se auto-prepara en _ready).
##
## Contrato doc 09 (congelado):
##   func start_dialogue(id: String, talker_name: String) -> void
##   signal dialogue_finished(id: String)
## Uso en NPC: DialogueSystem.start_dialogue(npc.dialogue_id, npc.display_name)
##
## E (acción "interact") avanza: 1ª pulsación completa el typewriter,
## 2ª muestra la siguiente línea; al final cierra y emite dialogue_finished.
## Mientras está activo congela al player vía GameManager.set_paused(true)
## (is_paused queda como flag) y al hablante vía duck-typing `frozen = true`.

signal dialogue_finished(id: String)

const DIALOGUE_DIR: String = "res://resources/dialogos/"
const BOX_SCENE: PackedScene = preload("res://scenes/ui/hud/dialogue_box.tscn")

var is_active: bool = false

var _box: DialogueBox = null
var _data: DialogueData = null
var _current_id: String = ""
var _index: int = 0
var _talker: Node = null
var _talker_name: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box = BOX_SCENE.instantiate() as DialogueBox
	add_child(_box)
	_box.hide_box()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("interact"):
		advance()
		get_viewport().set_input_as_handled()


## Inicia un diálogo por id de recurso (res://resources/dialogos/{id}.tres).
## `talker` es opcional (no rompe el contrato de 2 args): si se pasa y tiene
## propiedad `frozen`, se congela/descongela con el diálogo.
func start_dialogue(id: String, talker_name: String, talker: Node = null) -> void:
	if is_active:
		return
	var data: DialogueData = load(DIALOGUE_DIR + id + ".tres") as DialogueData
	if data == null or data.is_empty():
		push_error("DialogueSystem: diálogo no encontrado o vacío: '%s'" % id)
		return
	_data = data
	_current_id = data.id
	if _current_id.is_empty():
		_current_id = id
	_index = 0
	_talker = talker
	_talker_name = talker_name
	is_active = true
	_freeze_talker(true)
	_set_paused_tree(true)
	_show_current()


## Avanza el diálogo (llamado con E). Expuesto para NPC/UI.
func advance() -> void:
	if not is_active or _box == null or _data == null:
		return
	if _box.is_typing():
		_box.complete()
		return
	_index += 1
	if _index < _data.line_count():
		_show_current()
	else:
		_finish()


func is_dialogue_active() -> bool:
	return is_active


func current_id() -> String:
	return _current_id


func _show_current() -> void:
	var line: DialogueData.DialogueLine = _data.get_line(_index)
	var speaker: String = line.speaker
	if speaker.is_empty() or speaker.begins_with("PLACEHOLDER"):
		speaker = _talker_name
	_box.show_line(speaker, line.formatted_text(_resolve_alias(), _resolve_zona()))


func _finish() -> void:
	var finished_id: String = _current_id
	_box.hide_box()
	_freeze_talker(false)
	_set_paused_tree(false)
	_data = null
	_current_id = ""
	_index = 0
	_talker = null
	is_active = false
	dialogue_finished.emit(finished_id)


func _resolve_alias() -> String:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("get_alias"):
		return str(gm.call("get_alias"))
	return "PLACEHOLDER_alias"


func _resolve_zona() -> String:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		var zona: Variant = gm.get("current_zone")
		if zona is String and not (zona as String).is_empty():
			return zona
	return "PLACEHOLDER_zona"


func _set_paused_tree(value: bool) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("set_paused"):
		gm.call("set_paused", value)


func _freeze_talker(value: bool) -> void:
	if _talker == null or not is_instance_valid(_talker):
		return
	# Duck-typing: el NPC expone `frozen` (doc 06); si no existe, no se rompe.
	if "frozen" in _talker:
		_talker.set("frozen", value)
