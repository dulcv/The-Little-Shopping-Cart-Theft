extends Node
## Autoload "SceneLoader".
## `goto_scene(path)`: cambio inmediato (sin barra).
## `load_threaded(path)`: carga en hilo con `progress(ratio)` para barras de
## carga (doc 01).
## Sin class_name (ver nota en game_manager.gd).

signal progress(ratio: float)
signal scene_loaded(path: String)
signal load_failed(path: String)

var _loading_path: String = ""
var _loading: bool = false


func _ready() -> void:
	set_process(false)


func is_loading() -> bool:
	return _loading


func goto_scene(path: String) -> void:
	cancel_load()
	get_tree().call_deferred("change_scene_to_file", path)


func load_threaded(path: String) -> int:
	if _loading:
		return ERR_BUSY
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		load_failed.emit(path)
		return err
	_loading_path = path
	_loading = true
	progress.emit(0.0)
	set_process(true)
	return OK


func cancel_load() -> void:
	_loading = false
	_loading_path = ""
	set_process(false)


func _process(_delta: float) -> void:
	if not _loading:
		return
	var prog: Array = []
	var status := ResourceLoader.load_threaded_get_status(_loading_path, prog)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		progress.emit(float(prog[0]) if not prog.is_empty() else 0.0)
		return
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed: PackedScene = ResourceLoader.load_threaded_get(_loading_path) as PackedScene
		var path := _loading_path
		cancel_load()
		progress.emit(1.0)
		if packed == null:
			load_failed.emit(path)
			return
		get_tree().change_scene_to_packed(packed)
		scene_loaded.emit(path)
		return
	var path := _loading_path
	cancel_load()
	load_failed.emit(path)
