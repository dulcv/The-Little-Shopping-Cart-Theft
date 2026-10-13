extends Control
## Boot placeholder (docs/04-flujo-gta): muestra logo 1.5s y salta a main_menu.
## Sin arte final: todo texto PLACEHOLDER_* con BoldPixels.ttf.

@onready var _timer: Timer = $Timer


func _ready() -> void:
	_timer.timeout.connect(_on_timer_timeout)
	_timer.start()


func _on_timer_timeout() -> void:
	SceneLoader.goto_scene("res://scenes/ui/menus/main_menu.tscn")
