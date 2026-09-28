class_name VehicleRadio
extends Node

## Radio del vehículo: 4 estaciones, cada una = una carpeta en assets/audio/radio/.
## Escanea las carpetas en tiempo de ejecución, así que basta con soltar .mp3
## nuevos para que suenen sin tocar código. Tolera estaciones vacías.
## Sin UI todavía: vehicle.gd muestra estación/canción en el DebugLabel y
## la acción "radio_next" (tecla R) cambia de estación.

signal station_changed(station_name: String)
signal track_changed(track_name: String)

const BASE_DIR := "res://assets/audio/radio"

## Orden oficial de estaciones. El nombre bonito se deriva del nombre de carpeta.
@export var station_dirs: PackedStringArray = [
	"anita_radio",
	"dulce_radio",
	"edgar_radio",
	"jessi_radio",
]

var station_names: PackedStringArray = []
var tracks: Array = [] # Array[PackedStringArray] de rutas por estación
var current_station: int = 0
var current_track: int = 0
var radio_on: bool = false

@onready var player: AudioStreamPlayer2D = $"../RadioPlayer"

func _ready() -> void:
	_scan_stations()
	if player:
		player.finished.connect(_on_track_finished)

## Lee cada carpeta y guarda los .mp3/.ogg/.wav encontrados.
func _scan_stations() -> void:
	station_names.clear()
	tracks.clear()
	for dir_name in station_dirs:
		var pretty := _pretty_name(dir_name)
		station_names.append(pretty)
		var paths := PackedStringArray()
		var full := "%s/%s" % [BASE_DIR, dir_name]
		if DirAccess.dir_exists_absolute(full):
			for f in DirAccess.get_files_at(full):
				var low := f.to_lower()
				if low.ends_with(".mp3") or low.ends_with(".ogg") or low.ends_with(".wav"):
					paths.append("%s/%s" % [full, f])
		paths.sort()
		tracks.append(paths)

func _pretty_name(dir_name: String) -> String:
	var n := dir_name.replace("_radio", "").replace("_", " ")
	return n.capitalize() + " Radio"

## Enciende la radio al subir al coche. Si la estación actual está vacía,
## busca la siguiente con música.
func start() -> void:
	radio_on = true
	if tracks.is_empty():
		return
	var tries := 0
	while tries < tracks.size() and (tracks[current_station] as PackedStringArray).is_empty():
		current_station = (current_station + 1) % tracks.size()
		tries += 1
	if (tracks[current_station] as PackedStringArray).is_empty():
		return # todas vacías: sin señal, en silencio
	_play_current()

func stop() -> void:
	radio_on = false
	if player:
		player.stop()

func next_station() -> void:
	if tracks.is_empty():
		return
	current_station = (current_station + 1) % tracks.size()
	current_track = 0
	station_changed.emit(get_station_name())
	if not radio_on:
		return
	if (tracks[current_station] as PackedStringArray).is_empty():
		if player:
			player.stop()
		track_changed.emit("Sin señal")
		return
	_play_current()

func next_track() -> void:
	if tracks.is_empty():
		return
	var list: PackedStringArray = tracks[current_station]
	if list.is_empty():
		return
	current_track = (current_track + 1) % list.size()
	_play_current()

func get_station_name() -> String:
	if station_names.is_empty():
		return "Radio"
	return station_names[current_station]

func get_track_name() -> String:
	if tracks.is_empty():
		return ""
	var list: PackedStringArray = tracks[current_station]
	if list.is_empty():
		return "Sin señal"
	return (list[current_track] as String).get_file().get_basename()

func _play_current() -> void:
	if not radio_on or player == null:
		return
	var list: PackedStringArray = tracks[current_station]
	if list.is_empty():
		return
	var path: String = list[current_track]
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	player.stream = stream
	player.play()
	track_changed.emit(get_track_name())

func _on_track_finished() -> void:
	if not radio_on:
		return
	next_track()
