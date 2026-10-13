extends Node
## Autoload "SaveManager".
## Persiste GameManager (dinero, dúo/personaje, zona, evidencias, federación)
## en `user://save.cfg` vía ConfigFile (doc 01).
## Sin class_name (ver nota en game_manager.gd). Accede a GameManager por ruta
## de Autoload con guarda para no acoplarse en tiempo de parseo.

signal save_finished
signal load_finished(success: bool)

const SAVE_PATH := "user://save.cfg"


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> int:
	var gm := _game_manager()
	if gm == null:
		return ERR_UNAVAILABLE
	var cfg := ConfigFile.new()
	cfg.set_value("game", "money", gm.get("money"))
	cfg.set_value("game", "current_zone", gm.get("current_zone"))
	cfg.set_value("game", "selected_ids", Array(gm.get("selected_ids")))
	cfg.set_value("game", "is_duo", gm.get("is_duo"))
	cfg.set_value("game", "federacion_level", gm.get("federacion_level"))
	var sel: Variant = gm.get("selected_character")
	var sel_id := ""
	if sel is Resource:
		var raw: Variant = (sel as Resource).get("id")
		if raw is String:
			sel_id = raw
	cfg.set_value("game", "selected_character_id", sel_id)
	cfg.set_value("evidence", "items", _serialize_evidence(gm))
	var err := cfg.save(SAVE_PATH)
	if err == OK:
		save_finished.emit()
	return err


func load_game() -> int:
	var gm := _game_manager()
	if gm == null:
		return ERR_UNAVAILABLE
	if not has_save():
		load_finished.emit(false)
		return ERR_FILE_NOT_FOUND
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		load_finished.emit(false)
		return err
	var typed_ids: Array[String] = []
	for id in cfg.get_value("game", "selected_ids", ["edgar"]):
		typed_ids.append(str(id))
	gm.call("set_selected_ids", typed_ids)
	gm.call("set_zone", str(cfg.get_value("game", "current_zone", "el_centro")))
	var target_money: int = maxi(0, int(cfg.get_value("game", "money", 0)))
	gm.set("money", target_money)
	gm.emit_signal("money_changed", gm.get("money"))
	var fed_delta: int = int(cfg.get_value("game", "federacion_level", 0)) - int(gm.get("federacion_level"))
	if fed_delta != 0:
		gm.call("add_federacion", fed_delta, "save")
	# selected_character_id queda guardado; CharacterData (doc 03, pendiente)
	# lo resolverá a recurso cuando exista el catálogo de personajes.
	_restore_evidence(gm, cfg.get_value("evidence", "items", []))
	load_finished.emit(true)
	return OK


func clear_save() -> int:
	if not has_save():
		return OK
	return DirAccess.remove_absolute(SAVE_PATH)


func _serialize_evidence(gm: Node) -> Array:
	var items: Array = []
	var wall: Dictionary = gm.get("evidence_wall")
	for key in wall:
		var ev: EvidenceData = wall[key] as EvidenceData
		if ev == null:
			continue
		items.append({
			"id": ev.id,
			"kind": ev.kind,
			"title": ev.title,
			"description": ev.description,
			"district": ev.district,
			"unlocks_mission": ev.unlocks_mission,
			"target_id": ev.target_id,
		})
	return items


func _restore_evidence(gm: Node, items: Array) -> void:
	var wall: Dictionary = gm.get("evidence_wall")
	wall.clear()
	for item in items:
		if not (item is Dictionary):
			continue
		var data: Dictionary = item
		var ev_id := str(data.get("id", ""))
		if ev_id.is_empty():
			continue
		var ev := EvidenceData.new()
		ev.id = ev_id
		ev.kind = int(data.get("kind", 0))
		ev.title = str(data.get("title", "PLACEHOLDER_titulo"))
		ev.description = str(data.get("description", "PLACEHOLDER_descripcion"))
		ev.district = str(data.get("district", "el_centro"))
		ev.unlocks_mission = str(data.get("unlocks_mission", ""))
		ev.target_id = str(data.get("target_id", ""))
		wall[ev.id] = ev
		gm.emit_signal("evidence_added", ev.id)
