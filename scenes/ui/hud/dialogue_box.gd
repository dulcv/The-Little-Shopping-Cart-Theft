class_name DialogueBox
extends Control

## Caja de diálogo HUD (doc 06): Panel + NameLabel + TextLabel typewriter
## + Hint "E". Todo texto visible por defecto = PLACEHOLDER_*.
## process_mode = ALWAYS para seguir escribiendo mientras GameManager pausa
## el árbol durante el diálogo.

signal typing_finished

@export var chars_per_second: float = 40.0

var _full_text: String = ""
var _shown: float = 0.0
var _typing: bool = false

@onready var _panel: PanelContainer = $Panel
@onready var _name_label: Label = $Panel/Margin/VBox/NameLabel
@onready var _text_label: Label = $Panel/Margin/VBox/TextLabel
@onready var _hint_label: Label = $Panel/Margin/VBox/HintLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_box()


func _process(delta: float) -> void:
	if not _typing:
		return
	if _text_label == null:
		return
	_shown += chars_per_second * delta
	_text_label.visible_characters = int(_shown)
	if int(_shown) >= _full_text.length():
		_typing = false
		typing_finished.emit()


func show_line(speaker: String, text: String) -> void:
	visible = true
	_name_label.text = speaker
	_full_text = text
	_text_label.text = text
	_shown = 0.0
	_text_label.visible_characters = 0
	_typing = _full_text.length() > 0


func is_typing() -> bool:
	return _typing


## Completa al instante la línea en curso (primera pulsación de E).
func complete() -> void:
	if not _typing:
		return
	_shown = float(_full_text.length())
	_text_label.visible_characters = -1
	_typing = false
	typing_finished.emit()


func hide_box() -> void:
	_typing = false
	_full_text = ""
	_shown = 0.0
	visible = false
