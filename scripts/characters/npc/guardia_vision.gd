class_name GuardiaVision
extends CharacterBody2D
## Guardia de los Gallos Negros con patrulla y cono de visión (sigilo).
## Si ve al jugador durante `tiempo_deteccion` segundos seguidos -> emite
## `jugador_detectado`. Las paredes (capa 1 Mundo) bloquean la vista.
## Si le pegan o le disparan, también da la alarma.

signal jugador_detectado(guardia: GuardiaVision)

## Puntos de patrulla en coordenadas del padre (ida y vuelta en bucle).
@export var patrulla: PackedVector2Array = PackedVector2Array()
@export var velocidad: float = 40.0
@export var espera_en_punto: float = 1.2
@export var alcance_vision: float = 95.0
@export_range(10.0, 180.0) var angulo_vision: float = 70.0
@export var tiempo_deteccion: float = 0.6
@export var color_pluma: Color = Color(0.25, 0.25, 0.3)
## "gallo_negro" = pañuelo y lentes oscuros; "policia" = gorra azul.
@export_enum("gallo_negro", "policia") var uniforme: String = "gallo_negro"

var mirando: Vector2 = Vector2.RIGHT
var sospecha: float = 0.0
var activo: bool = true

var _idx: int = 0
var _espera: float = 0.0
var _jugador: Node2D = null
## Patrulla convertida a coordenadas globales en _ready().
var _puntos: Array[Vector2] = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var cono: Polygon2D = $Cono
@onready var alerta: Label = $Alerta

const COLOR_CONO := Color(1.0, 0.95, 0.4, 0.18)
const COLOR_CONO_ALERTA := Color(1.0, 0.2, 0.15, 0.35)

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("guardias")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	sprite.modulate = color_pluma
	if uniforme == "policia":
		Accesorio.poner(sprite, "gorra_policia", Vector2(3, -7))
	else:
		Accesorio.poner(sprite, "panuelo_negro", Vector2(3, -6))
		Accesorio.poner(sprite, "lentes_oscuros", Vector2(4, -3), true)
	_jugador = get_tree().get_first_node_in_group("player") as Node2D
	_construir_cono()
	alerta.text = ""
	var padre := get_parent() as Node2D
	for p in patrulla:
		_puntos.append(padre.to_global(p) if padre else p)

func _physics_process(delta: float) -> void:
	_patrullar(delta)
	_vigilar(delta)

func _patrullar(delta: float) -> void:
	if _puntos.size() < 2:
		velocity = Vector2.ZERO
		sprite.play(&"idle")
		return
	if _espera > 0.0:
		_espera -= delta
		velocity = Vector2.ZERO
		sprite.play(&"idle")
		return
	var to: Vector2 = _puntos[_idx] - global_position
	if to.length() < 2.0:
		_idx = (_idx + 1) % _puntos.size()
		_espera = espera_en_punto
		return
	velocity = to.normalized() * velocidad
	_set_mirando(to.normalized())
	sprite.play(&"walk")
	move_and_slide()

func _set_mirando(dir: Vector2) -> void:
	mirando = dir
	cono.rotation = dir.angle()
	if absf(dir.x) > 0.1:
		sprite.flip_h = dir.x < 0.0

func _vigilar(delta: float) -> void:
	if not activo or not is_instance_valid(_jugador) or not _jugador.visible:
		sospecha = 0.0
		_pintar()
		return
	if puede_ver(_jugador.global_position):
		sospecha += delta
		if sospecha >= tiempo_deteccion:
			sospecha = 0.0
			jugador_detectado.emit(self)
	else:
		sospecha = maxf(sospecha - delta * 0.5, 0.0)
	_pintar()

func puede_ver(punto: Vector2) -> bool:
	var to := punto - global_position
	if to.length() > alcance_vision:
		return false
	if rad_to_deg(absf(mirando.angle_to(to))) > angulo_vision * 0.5:
		return false
	var q := PhysicsRayQueryParameters2D.create(global_position, punto, 1)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()

func _pintar() -> void:
	var alarma := sospecha > 0.0
	cono.color = COLOR_CONO_ALERTA if alarma else COLOR_CONO
	alerta.text = "?" if alarma else ""

func _construir_cono() -> void:
	var pts := PackedVector2Array([Vector2.ZERO])
	var mitad := deg_to_rad(angulo_vision * 0.5)
	for i in 9:
		var a := lerpf(-mitad, mitad, i / 8.0)
		pts.append(Vector2.RIGHT.rotated(a) * alcance_vision)
	cono.polygon = pts
	cono.color = COLOR_CONO

## Pegarle o dispararle a un guardia = alarma inmediata.
func take_damage(_amount: int) -> void:
	if activo:
		jugador_detectado.emit(self)

## Tras atrapar al jugador, el guardia vuelve a su ruta desde el inicio.
func reiniciar() -> void:
	sospecha = 0.0
	_idx = 0
	_espera = espera_en_punto
	if not _puntos.is_empty():
		global_position = _puntos[0]
