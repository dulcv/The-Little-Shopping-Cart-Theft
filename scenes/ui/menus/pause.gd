extends CanvasLayer
## Pause placeholder (docs/04): ESC alterna pausa. process_mode ALWAYS para
## funcionar con get_tree().paused = true. Se instancia sobre el nivel.

@onready var _panel: Control = $Panel
@onready var _btn_resume: Button = $Panel/Center/VBox/BtnResume
@onready var _btn_quit: Button = $Panel/Center/VBox/BtnQuit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	_btn_resume.pressed.connect(resume_game)
	_btn_quit.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			toggle_pause()
			get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if GameManager.is_paused:
		resume_game()
	else:
		GameManager.set_paused(true)
		_panel.visible = true


func resume_game() -> void:
	GameManager.set_paused(false)
	_panel.visible = false


func _on_quit_pressed() -> void:
	GameManager.set_paused(false)
	SceneLoader.goto_scene("res://scenes/ui/menus/main_menu.tscn")
