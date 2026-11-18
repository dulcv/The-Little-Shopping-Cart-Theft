extends Node
## Autoload "Musica": una pista por escena, con fundido al cambiar.
## Baja el volumen cuando el jugador va en coche (para que se oiga la radio).
## Música: Juhani Junkala, CC0 (ver CREDITOS_MUSICA.txt).

const CARPETA := "res://assets/audio/music/"
## Escena -> pista (nombre del .ogg sin extensión)
const POR_ESCENA := {
	"res://scenes/ui/menus/menu_principal.tscn": "menu",
	"res://scenes/main/escena_principal.tscn": "centro",
	"res://scenes/world/las_lomas/LasLomas.tscn": "lomas",
	"res://scenes/world/granja_industrial/RanchoMaizal.tscn": "rancho",
	"res://scenes/world/la_federal/LaFederal.tscn": "federal",
	"res://scenes/world/arena_jefe/ArenaJefe.tscn": "jefe",
	"res://scenes/ui/menus/final.tscn": "final",
}
const VOLUMEN_DB := -9.0
const VOLUMEN_EN_COCHE_DB := -28.0

var _reproductor: AudioStreamPlayer
var _actual: String = ""
var _escena_vista: Node = null
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reproductor = AudioStreamPlayer.new()
	_reproductor.volume_db = VOLUMEN_DB
	add_child(_reproductor)

func _process(_delta: float) -> void:
	var escena := get_tree().current_scene
	if escena != _escena_vista:
		_escena_vista = escena
		if escena and POR_ESCENA.has(escena.scene_file_path):
			tocar(POR_ESCENA[escena.scene_file_path])
	# Más bajito si va manejando (la radio del coche toma el control).
	if _tween == null or not _tween.is_running():
		var p := get_tree().get_first_node_in_group("player")
		var en_coche: bool = p != null and p.get("current_vehicle") != null
		var meta := VOLUMEN_EN_COCHE_DB if en_coche else VOLUMEN_DB
		_reproductor.volume_db = move_toward(_reproductor.volume_db, meta, 30.0 * _delta)

## Cambia a la pista `nombre` con fundido. Si ya suena, no hace nada.
func tocar(nombre: String) -> void:
	if nombre == _actual:
		return
	var ruta := CARPETA + nombre + ".ogg"
	if not ResourceLoader.exists(ruta):
		push_warning("Musica: no existe " + ruta)
		return
	_actual = nombre
	var stream = load(ruta)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if _reproductor.playing:
		_tween.tween_property(_reproductor, "volume_db", -40.0, 0.5)
	_tween.tween_callback(func():
		_reproductor.stream = stream
		_reproductor.volume_db = -40.0
		_reproductor.play())
	_tween.tween_property(_reproductor, "volume_db", VOLUMEN_DB, 0.8)

func detener() -> void:
	_actual = ""
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_reproductor, "volume_db", -40.0, 0.6)
	_tween.tween_callback(_reproductor.stop)
