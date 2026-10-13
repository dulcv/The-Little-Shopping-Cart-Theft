extends Node
## Autoload "UIManager".
## Abre/cierra menús (pila LIFO) y guarda referencia al HUD (doc 01).
## Sin class_name (ver nota en game_manager.gd).

signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)

var hud: CanvasLayer = null
var _menu_stack: Array[CanvasItem] = []


func set_hud(node: CanvasLayer) -> void:
	hud = node


func open_menu(menu: CanvasItem) -> void:
	if menu == null:
		return
	if _menu_stack.has(menu):
		return
	_menu_stack.append(menu)
	menu.visible = true
	menu.move_to_front()
	menu_opened.emit(menu.name)


func close_menu(menu: CanvasItem) -> void:
	if menu == null:
		return
	_menu_stack.erase(menu)
	menu.visible = false
	menu_closed.emit(menu.name)


func close_top_menu() -> void:
	if _menu_stack.is_empty():
		return
	close_menu(_menu_stack.back())


func close_all_menus() -> void:
	while not _menu_stack.is_empty():
		close_menu(_menu_stack.back())


func is_menu_open() -> bool:
	return not _menu_stack.is_empty()


func show_hud() -> void:
	if hud != null:
		hud.visible = true


func hide_hud() -> void:
	if hud != null:
		hud.visible = false
