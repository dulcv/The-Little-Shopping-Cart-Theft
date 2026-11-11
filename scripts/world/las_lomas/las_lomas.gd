extends Node2D
## Nivel 2 — "La Fiesta del Gallo" (Las Lomas).
## 1) Encuentra la invitación afuera -> el portero abre la reja.
## 2) Entra sin que te vean los guardias y planta el micrófono en el despacho.
## 3) Quédate cerca (y escondido) mientras Don Crestón y el comandante hablan.

const RADIO_SENAL := 260.0
const CONVERSACION := [
	["Comandante", "Don Crestón, hay un detective preguntando por el agente Kiko."],
	["Don Crestón", "Si alguien pregunta, nadie vio nada. ¿Entendido?"],
	["Comandante", "¿Y dónde tienen al agente?"],
	["Don Crestón", "Donde está el maíz, compadre. En el Rancho Maizal."],
	["Comandante", "Mis patrullas no se van a acercar por allá. Como siempre."],
	["Don Crestón", "Así me gusta. Su sobre llega el viernes, como cada semana."],
]
const SEG_POR_LINEA := 3.0

enum Escucha { NADA, ESCUCHANDO, HECHO }

@onready var player: CharacterBody2D = $Player
@onready var hud := $ExpedienteHUD
@onready var reja: StaticBody2D = $Reja
@onready var portero_area: Area2D = $Portero/Zona
@onready var microfono = $Mansion/MicrofonoSpot
@onready var creston: Node2D = $Mansion/Creston
@onready var comandante: Node2D = $Mansion/Comandante
@onready var salida: Marker2D = $SalidaFiesta

var escucha: Escucha = Escucha.NADA
var _linea: int = 0
var _t_linea: float = 0.0
var _sin_senal: bool = false
var _gracia: float = 0.0
var _pos_creston: Vector2
var _pos_comandante: Vector2

func _ready() -> void:
	CaseManager.sincronizar_con_zona("las_lomas")
	for g in get_tree().get_nodes_in_group("guardias"):
		g.jugador_detectado.connect(_on_detectado)
	portero_area.body_entered.connect(_on_portero)
	microfono.plantado.connect(_on_microfono_plantado)
	_pos_creston = creston.position
	_pos_comandante = comandante.position
	creston.visible = false
	comandante.visible = false
	if CaseManager.tiene_pista("invitacion_fiesta"):
		_abrir_reja()
	if CaseManager.tiene_pista("grabacion_microfono"):
		escucha = Escucha.HECHO

func _process(delta: float) -> void:
	if _gracia > 0.0:
		_gracia -= delta
		if _gracia <= 0.0:
			_set_guardias_activos(true)
	if escucha == Escucha.ESCUCHANDO:
		_avanzar_conversacion(delta)

# --- Portero ---------------------------------------------------------------

func _on_portero(body: Node2D) -> void:
	if body != player or not reja.visible:
		return
	if CaseManager.tiene_pista("invitacion_fiesta"):
		hud.mostrar("Portero: Adelante. Bienvenido a la fiesta de Don Crestón.", 3.0)
		_abrir_reja()
	else:
		hud.mostrar("Portero: Sin invitación no pasas, plumífero. Lárgate.", 3.0)

func _abrir_reja() -> void:
	reja.visible = false
	reja.get_node("CollisionShape2D").set_deferred("disabled", true)

# --- Micrófono y conversación ---------------------------------------------

func _on_microfono_plantado() -> void:
	hud.mostrar("Micrófono plantado. Alguien viene... ¡escóndete y escucha!", 3.0)
	creston.visible = true
	comandante.visible = true
	var entrada := Vector2(250, -135)
	creston.position = entrada
	comandante.position = entrada
	var tw := create_tween().set_parallel()
	tw.tween_property(creston, "position", _pos_creston, 2.0)
	tw.tween_property(comandante, "position", _pos_comandante, 2.4)
	escucha = Escucha.ESCUCHANDO
	_linea = -1
	_t_linea = -2.5  # deja que lleguen antes de hablar

func _avanzar_conversacion(delta: float) -> void:
	var lejos := player.global_position.distance_to(microfono.global_position) > RADIO_SENAL
	if lejos:
		if not _sin_senal:
			_sin_senal = true
			hud.mostrar("*bzzzt* Se pierde la señal... ¡acércate al despacho!", 2.0)
		return
	_sin_senal = false
	_t_linea += delta
	if _t_linea < 0.0:
		return
	var idx := int(_t_linea / SEG_POR_LINEA)
	if idx >= CONVERSACION.size():
		_terminar_grabacion()
	elif idx != _linea:
		_linea = idx
		var l: Array = CONVERSACION[idx]
		hud.mostrar("[MIC] %s: %s" % [l[0], l[1]], SEG_POR_LINEA)

func _terminar_grabacion() -> void:
	escucha = Escucha.HECHO
	CaseManager.agregar_pista("grabacion_microfono")

# --- Sigilo ----------------------------------------------------------------

func _on_detectado(_g: Node) -> void:
	if _gracia > 0.0:
		return
	hud.mostrar("¡Un Gallo Negro te vio! Te sacaron de la fiesta a picotazos.", 3.0)
	player.global_position = salida.global_position
	player.velocity = Vector2.ZERO
	for g in get_tree().get_nodes_in_group("guardias"):
		g.reiniciar()
	_set_guardias_activos(false)
	_gracia = 1.5
	if escucha == Escucha.ESCUCHANDO:
		# Te descubrieron: quitaron el micrófono y se fueron.
		escucha = Escucha.NADA
		microfono.reiniciar()
		creston.visible = false
		comandante.visible = false

func _set_guardias_activos(v: bool) -> void:
	for g in get_tree().get_nodes_in_group("guardias"):
		g.activo = v
