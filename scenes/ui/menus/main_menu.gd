extends Control
## MainMenu placeholder (docs/04-flujo-gta): Nueva partida / Continuar.
## Continuar usa SaveManager.load_game y salta a loading_game.

@onready var _btn_new: Button = $Center/VBox/BtnNew
@onready var _btn_continue: Button = $Center/VBox/BtnContinue


func _ready() -> void:
	_btn_new.pressed.connect(_on_new_pressed)
	_btn_continue.pressed.connect(_on_continue_pressed)
	_btn_continue.disabled = not SaveManager.has_save()


func _on_new_pressed() -> void:
	SceneLoader.goto_scene("res://scenes/ui/menus/character_select.tscn")


func _on_continue_pressed() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	SceneLoader.goto_scene("res://scenes/ui/menus/loading_game.tscn")
