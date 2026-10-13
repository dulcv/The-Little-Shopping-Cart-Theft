extends CanvasLayer
## WantedDead placeholder (docs/04 "busted"): pantalla de atrapado.
## show_busted() la muestra y pausa; reintentar recarga el Centro.

@onready var _panel: Control = $Panel
@onready var _btn_retry: Button = $Panel/Center/VBox/BtnRetry
@onready var _btn_quit: Button = $Panel/Center/VBox/BtnQuit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	_btn_retry.pressed.connect(_on_retry_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)


## Llamar al morir/caer busted. Limpia calor de guardia si el Autoload existe.
func show_busted() -> void:
	var wanted := get_node_or_null("/root/WantedSystem")
	if wanted != null and wanted.has_method("clear_guardia"):
		wanted.call("clear_guardia")
	GameManager.set_paused(true)
	_panel.visible = true


func _on_retry_pressed() -> void:
	GameManager.set_paused(false)
	SceneLoader.goto_scene("res://scenes/main/escena_principal.tscn")


func _on_quit_pressed() -> void:
	GameManager.set_paused(false)
	SceneLoader.goto_scene("res://scenes/ui/menus/main_menu.tscn")
