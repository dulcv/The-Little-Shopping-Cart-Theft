extends Control
## CharacterSelect placeholder (docs/04, biblia-minima, doc 09):
## Edgar / Dulce / Duo usando resources/characters/*.tres + set_selected_ids.

const EDGAR: CharacterData = preload("res://resources/characters/edgar.tres")
const DULCE: CharacterData = preload("res://resources/characters/dulce.tres")

@onready var _btn_edgar: Button = $Center/VBox/BtnEdgar
@onready var _btn_dulce: Button = $Center/VBox/BtnDulce
@onready var _btn_duo: Button = $Center/VBox/BtnDuo


func _ready() -> void:
	_btn_edgar.pressed.connect(_on_edgar_pressed)
	_btn_dulce.pressed.connect(_on_dulce_pressed)
	_btn_duo.pressed.connect(_on_duo_pressed)


func _on_edgar_pressed() -> void:
	GameManager.select_character(EDGAR)
	GameManager.set_selected_ids(["edgar"] as Array[String])
	SceneLoader.goto_scene("res://scenes/ui/menus/loading_game.tscn")


func _on_dulce_pressed() -> void:
	GameManager.select_character(DULCE)
	GameManager.set_selected_ids(["dulce"] as Array[String])
	SceneLoader.goto_scene("res://scenes/ui/menus/loading_game.tscn")


func _on_duo_pressed() -> void:
	GameManager.select_character(EDGAR)
	GameManager.set_selected_ids(["edgar", "dulce"] as Array[String])
	SceneLoader.goto_scene("res://scenes/ui/menus/loading_game.tscn")
