extends Node
## BootRoot: nuevo main_scene (docs/04). Delega a boot.tscn en el primer tick
## para que escena_principal.tscn pase a ser nivel cargado async.
## No toca Autoloads, Centro, NPCs ni evidencias.


func _ready() -> void:
	SceneLoader.goto_scene("res://scenes/ui/menus/boot.tscn")
