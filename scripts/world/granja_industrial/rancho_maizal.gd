extends Node2D
## Nivel 3 — "Rancho Maizal" (Granja Industrial).
## 1) Entra a la granja sin que te vean y toma el MAPA de la oficina.
##    El mapa marca una tabla suelta en la cerca este -> se abre el paso.
## 2) Cruza el maizal hasta la bodega y FOTOGRAFÍA el plantío (mantén E).
## 3) ¡ALARMA! Camionetas de los Gallos Negros te persiguen.
##    Sube a un coche y escapa por la carretera del oeste (los guardias a pie huyen).
## Si una camioneta te alcanza, la escena se recarga desde la bodega
## (CaseManager conserva las pistas, así que no repites todo).

const TIEMPO_CAPTURA := 1.5
const RETRASO_PERSEGUIDORES := 2.0

@onready var player: CharacterBody2D = $Player
@onready var hud := $ExpedienteHUD
@onready var tabla: StaticBody2D = $TablaSuelta
@onready var foto_spot = $Bodega/FotoSpot
@onready var salida_granja: Marker2D = $SalidaGranja
@onready var spawn_alarma: Marker2D = $SpawnAlarma
@onready var zona_escape: Marker2D = $ZonaEscape
@onready var sirena: Node2D = $Bodega/Sirena

var alarma: bool = false
var terminado: bool = false
var _captura: float = 0.0
var _gracia: float = 0.0
var _t: float = 0.0

func _ready() -> void:
	CaseManager.sincronizar_con_zona("granja_industrial")
	for g in get_tree().get_nodes_in_group("guardias"):
		g.jugador_detectado.connect(_on_detectado)
	foto_spot.plantado.connect(_on_foto)
	CaseManager.pista_obtenida.connect(_on_pista)
	sirena.visible = false
	if CaseManager.tiene_pista("mapa_rancho"):
		_abrir_tabla()
	if CaseManager.tiene_pista("escape_rancho"):
		terminado = true
	elif CaseManager.tiene_pista("foto_plantio"):
		# Reintento tras ser atrapado: empiezas en la bodega con la alarma sonando.
		foto_spot.listo = true
		player.global_position = spawn_alarma.global_position
		_iniciar_alarma.call_deferred()

func _process(delta: float) -> void:
	_t += delta
	if _gracia > 0.0:
		_gracia -= delta
		if _gracia <= 0.0 and not alarma:
			_set_guardias(true)
	if alarma and not terminado:
		sirena.modulate = Color(1, 0.2, 0.2) if int(_t * 4.0) % 2 == 0 else Color(0.2, 0.4, 1)
		_revisar_captura(delta)
		_revisar_escape()

# --- Paso 1: mapa + tabla suelta ------------------------------------------

func _on_pista(id: String, _texto: String) -> void:
	if id == "mapa_rancho":
		_abrir_tabla()
		await get_tree().create_timer(4.0).timeout
		hud.mostrar("El mapa marca una TABLA SUELTA en la cerca este de la granja.", 4.0)

func _abrir_tabla() -> void:
	tabla.get_node("CollisionShape2D").set_deferred("disabled", true)
	tabla.get_node("Vista").color = Color(0.35, 0.22, 0.1, 0.35)

# --- Sigilo en la granja (antes de la alarma) ------------------------------

func _on_detectado(_g: Node) -> void:
	if alarma or _gracia > 0.0:
		return
	hud.mostrar("¡Un guardia te vio! Te echaron de la granja.", 3.0)
	if player.current_vehicle:
		player.current_vehicle.exit()
	player.global_position = salida_granja.global_position
	for g in get_tree().get_nodes_in_group("guardias"):
		g.reiniciar()
	_set_guardias(false)
	_gracia = 1.5

func _set_guardias(v: bool) -> void:
	for g in get_tree().get_nodes_in_group("guardias"):
		g.activo = v

# --- Paso 2 y 3: foto, alarma y persecución --------------------------------

func _on_foto() -> void:
	CaseManager.agregar_pista("foto_plantio")
	_iniciar_alarma()

func _iniciar_alarma() -> void:
	alarma = true
	sirena.visible = true
	# Los guardias a pie corren a esconderse: así no estorban al manejar.
	for g in get_tree().get_nodes_in_group("guardias"):
		g.queue_free()
	await get_tree().create_timer(4.5).timeout
	if terminado:
		return
	hud.mostrar("¡ALARMA! Sube a la camioneta (E) y escapa por la carretera del OESTE.", 4.0)
	# Margen para llegar a la camioneta antes de que arranquen los perseguidores.
	await get_tree().create_timer(RETRASO_PERSEGUIDORES).timeout
	if terminado:
		return
	for c in get_tree().get_nodes_in_group("perseguidores"):
		c.iniciar()

func _revisar_captura(delta: float) -> void:
	var alguno := false
	for c in get_tree().get_nodes_in_group("perseguidores"):
		if c.tocando_objetivo():
			alguno = true
	var en_coche_destruido: bool = player.current_vehicle == null and _todos_mis_coches_destruidos()
	if alguno:
		_captura += delta
	else:
		_captura = maxf(_captura - delta, 0.0)
	if _captura >= TIEMPO_CAPTURA or en_coche_destruido:
		_atrapado()

func _todos_mis_coches_destruidos() -> bool:
	for v in get_tree().get_nodes_in_group("coches_escape"):
		if not v.is_wrecked:
			return false
	return true

func _atrapado() -> void:
	terminado = true
	hud.mostrar("¡Te atraparon los Gallos Negros! Inténtalo de nuevo...", 2.5)
	for c in get_tree().get_nodes_in_group("perseguidores"):
		c.detener()
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

func _revisar_escape() -> void:
	if player.current_vehicle == null:
		return
	if player.global_position.x < zona_escape.global_position.x:
		terminado = true
		for c in get_tree().get_nodes_in_group("perseguidores"):
			c.detener()
		CaseManager.agregar_pista("escape_rancho")
