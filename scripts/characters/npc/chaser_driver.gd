class_name ChaserDriver
extends Node2D
## Conductor de los Gallos Negros que persigue al jugador (a pie o en coche).
## Se sube a `vehiculo` con iniciar() y conduce hacia el objetivo con
## get_drive_input() (interfaz que lee vehicle.gd). Si se atora contra algo,
## da reversa un momento y vuelve a intentarlo.
## Sin navmesh: si no ve al jugador directo (paredes, maizal), sigue su RASTRO
## (migas de pan compartidas): va al punto más reciente del rastro que sí ve.
## Por ahí ya pasó el jugador, así que es un camino transitable.

## Rastro compartido por todos los perseguidores (coordenadas globales).
static var rastro: PackedVector2Array = PackedVector2Array()
const RASTRO_PASO := 16.0
const RASTRO_MAX := 500

@export var vehiculo_path: NodePath
## Distancia a la que "atrapa" al jugador.
@export var radio_captura: float = 34.0
## Segundos extra antes de arrancar (para escalonar a los perseguidores).
@export var retraso_extra: float = 0.0

var vehiculo: Vehicle = null
var objetivo: Node2D = null
var persiguiendo: bool = false

var _atorado: float = 0.0
var _reversa: float = 0.0
var _giro_reversa: float = 1.0
var _meta: Vector2 = Vector2.ZERO
var _t_meta: float = 0.0

func _ready() -> void:
	vehiculo = get_node_or_null(vehiculo_path) as Vehicle
	objetivo = get_tree().get_first_node_in_group("player") as Node2D
	add_to_group("perseguidores")
	visible = false
	if vehiculo:
		# Camionetas de los Gallos Negros: negras (tras el color aleatorio del Vehicle).
		vehiculo.set_paint_color.call_deferred(Color(0.13, 0.13, 0.15))

func iniciar() -> void:
	if retraso_extra > 0.0:
		await get_tree().create_timer(retraso_extra).timeout
	if vehiculo and vehiculo.can_be_entered():
		vehiculo.enter(self)
		persiguiendo = true
		if retraso_extra <= 0.0:
			rastro.clear()

func detener() -> void:
	persiguiendo = false

## ¿Está pegado al jugador? (lo usa el nivel para decidir si te atraparon)
func tocando_objetivo() -> bool:
	if not persiguiendo or vehiculo == null or vehiculo.is_wrecked or not is_instance_valid(objetivo):
		return false
	return vehiculo.global_position.distance_to(objetivo.global_position) < radio_captura

func _physics_process(delta: float) -> void:
	if vehiculo == null or not is_instance_valid(vehiculo):
		return
	global_position = vehiculo.global_position
	if not persiguiendo:
		return
	_grabar_rastro()
	_t_meta -= delta
	if _t_meta <= 0.0:
		_t_meta = 0.2
		_meta = _elegir_meta()
	# Detección de atasco: quiere avanzar pero casi no se mueve.
	if _reversa > 0.0:
		_reversa -= delta
	elif absf(vehiculo.speed) < 25.0:
		_atorado += delta
		if _atorado > 0.7:
			_atorado = 0.0
			_reversa = 0.9
			_giro_reversa = 1.0 if randf() < 0.5 else -1.0
	else:
		_atorado = 0.0

## x = giro, y = acelerador (contrato de vehicle.gd)
func get_drive_input() -> Vector2:
	if not persiguiendo or vehiculo == null or not is_instance_valid(objetivo):
		return Vector2.ZERO
	if _reversa > 0.0:
		return Vector2(_giro_reversa, -1.0)
	var to := _meta - vehiculo.global_position
	var fwd := Vector2.RIGHT.rotated(vehiculo.rotation)
	var ang := fwd.angle_to(to.normalized())
	# Objetivo detrás: gira fuerte con poco gas para no pasarse.
	var gas := 1.0 if absf(ang) < 1.6 else 0.45
	return Vector2(clampf(ang * 2.5, -1.0, 1.0), gas)

func _grabar_rastro() -> void:
	if not is_instance_valid(objetivo):
		return
	var p := objetivo.global_position
	if rastro.is_empty() or rastro[rastro.size() - 1].distance_to(p) >= RASTRO_PASO:
		rastro.append(p)
		if rastro.size() > RASTRO_MAX:
			rastro.remove_at(0)

func _veo(punto: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(vehiculo.global_position, punto, 1)
	return vehiculo.get_world_2d().direct_space_state.intersect_ray(q).is_empty()

## Jugador visible -> directo a él. Si no, la miga más reciente que se vea.
func _elegir_meta() -> Vector2:
	var p := objetivo.global_position
	if _veo(p):
		return p
	var i := rastro.size() - 1
	var revisadas := 0
	while i >= 0 and revisadas < 60:
		if _veo(rastro[i]):
			return rastro[i]
		i -= 3
		revisadas += 1
	return p

# Callbacks que llama Vehicle.enter()/exit()
func on_enter_vehicle(_v: Vehicle) -> void:
	pass

func on_exit_vehicle(pos: Vector2) -> void:
	global_position = pos
	persiguiendo = false

func take_damage(_amount: int) -> void:
	pass
