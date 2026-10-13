extends Node
## Autoload "AudioManager".
## Buses música/sfx (se crean en runtime si no existen en el proyecto) +
## música persistente + `play_sfx(stream, pos)` con pool no posicional y
## one-shot AudioStreamPlayer2D cuando pos != Vector2.ZERO (doc 01).
## Sin class_name (ver nota en game_manager.gd).

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const SFX_POOL_SIZE := 8

var music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SfxPlayer_%d" % i
		p.bus = SFX_BUS
		add_child(p)
		_sfx_pool.append(p)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


## Contrato doc 01. pos == Vector2.ZERO = no posicional (pool round-robin).
func play_sfx(stream: AudioStream, pos: Vector2 = Vector2.ZERO, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	if pos == Vector2.ZERO:
		var p := _sfx_pool[_sfx_index]
		_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
		p.stream = stream
		p.volume_db = volume_db
		p.pitch_scale = pitch
		p.play()
		return
	var player_2d := AudioStreamPlayer2D.new()
	player_2d.stream = stream
	player_2d.volume_db = volume_db
	player_2d.pitch_scale = pitch
	player_2d.bus = SFX_BUS
	player_2d.position = pos
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(player_2d)
	player_2d.finished.connect(player_2d.queue_free)
	player_2d.play()


func play_music(stream: AudioStream, volume_db: float = -8.0) -> void:
	if stream == null:
		return
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()


func stop_music() -> void:
	music_player.stop()


func set_music_volume(volume_db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), volume_db)


func set_sfx_volume(volume_db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), volume_db)
