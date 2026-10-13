class_name WantedSystem
extends Node

## Scaffolding de doble notoriedad (doc 11, extiende doc 07 sin romperlo).
## Autoload-ready: registrar como Autoload "WantedSystem" en project.godot
## (NO hacerlo en este commit). Todo texto visible = PLACEHOLDER_*.

signal guardia_changed(level: int)
signal federacion_changed(level: int)
## Compatibilidad con contrato doc 09 (wanted_level = guardia).
signal wanted_changed(level: int)

const MAX_LEVEL := 5

var guardia_level: int = 0
var federacion_level: int = 0
## Alias de compatibilidad: wanted_level refleja guardia_level.
var wanted_level: int = 0:
	get:
		return guardia_level
	set(value):
		guardia_level = clampi(value, 0, MAX_LEVEL)

@export var guardia_decay_seconds: float = 30.0
@export var federacion_decay_seconds: float = 120.0

var _guardia_timer: Timer
var _federacion_timer: Timer

func _ready() -> void:
	_guardia_timer = Timer.new()
	_guardia_timer.wait_time = guardia_decay_seconds
	_guardia_timer.timeout.connect(_on_guardia_decay)
	add_child(_guardia_timer)
	_federacion_timer = Timer.new()
	_federacion_timer.wait_time = federacion_decay_seconds
	_federacion_timer.timeout.connect(_on_federacion_decay)
	add_child(_federacion_timer)

func add_guardia(n: int, reason: String = "PLACEHOLDER_motivo") -> void:
	guardia_level = clampi(guardia_level + n, 0, MAX_LEVEL)
	wanted_level = guardia_level
	guardia_changed.emit(guardia_level)
	wanted_changed.emit(guardia_level)
	_restart_decay(_guardia_timer)

func add_federacion(n: int, reason: String = "PLACEHOLDER_motivo") -> void:
	federacion_level = clampi(federacion_level + n, 0, MAX_LEVEL)
	federacion_changed.emit(federacion_level)
	_restart_decay(_federacion_timer)

## Compatibilidad doc 09.
func add_heat(amount: int, reason: String = "PLACEHOLDER_motivo") -> void:
	add_guardia(amount, reason)

func clear_heat() -> void:
	clear_guardia()

## WantedClearZone solo baja guardia (doc 11).
func clear_guardia() -> void:
	guardia_level = 0
	wanted_level = 0
	guardia_changed.emit(guardia_level)
	wanted_changed.emit(guardia_level)

## Federacion solo baja con soborno o tiempo largo (doc 11).
func bribe_federacion() -> void:
	federacion_level = 0
	federacion_changed.emit(federacion_level)

func _on_guardia_decay() -> void:
	if guardia_level > 0:
		guardia_level -= 1
		wanted_level = guardia_level
		guardia_changed.emit(guardia_level)
		wanted_changed.emit(guardia_level)
	if guardia_level > 0:
		_guardia_timer.start()

func _on_federacion_decay() -> void:
	if federacion_level > 0:
		federacion_level -= 1
		federacion_changed.emit(federacion_level)
	if federacion_level > 0:
		_federacion_timer.start()

func _restart_decay(timer: Timer) -> void:
	if timer != null and not timer.is_stopped():
		timer.stop()
	if timer != null:
		timer.start()
