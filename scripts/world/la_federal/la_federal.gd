extends Node2D
## Nivel 4 — "El Soplón" (La Federal, comisaría del corral).
## Deducción: uno de los 3 comandantes cobra sobornos de Don Crestón.
## 1) Interroga a la secretaria y a los comandantes (E).
## 2) Pruebas: la PLACA perdida (estacionamiento, junto a la camioneta de los
##    Gallos Negros) y la LIBRETA de pagos (bote de basura de los vestidores,
##    vigilado por un policía).
## 3) Acusa al culpable en el tablero de la Jefa (mantén E en su nombre).
##    Sin las 2 pruebas la Jefa no te hace caso; si acusas a un inocente te echa.

const CULPABLE := "espolon"
const NOMBRES := {"plumas": "Plumas", "pico": "Pico", "espolon": "Espolón"}
const CONFESION := [
	"Jefa Cacaraca: ¡Comandante Espolón! ¿Dónde está su placa?",
	"Espolón: Está bien, está bien... ¡Don Crestón me pagaba cada viernes!",
	"Espolón: Se esconde en su bodega del puerto. ¡No le digan que fui yo!",
	"Jefa Cacaraca: Detective, vaya por Don Crestón. Esta vez no se nos escapa.",
]
const SEG_LINEA := 3.2

@onready var player: CharacterBody2D = $Player
@onready var hud := $ExpedienteHUD
@onready var calle: Marker2D = $Calle

var _resuelto: bool = false
var _gracia: float = 0.0

func _ready() -> void:
	CaseManager.sincronizar_con_zona("la_federal")
	for g in get_tree().get_nodes_in_group("guardias"):
		g.jugador_detectado.connect(_on_detectado)
	for id in NOMBRES:
		var spot = get_node("DespachoJefa/Acusar_" + id)
		spot.plantado.connect(_on_acusar.bind(id, spot))
	$CamionetaGallos.set_paint_color.call_deferred(Color(0.13, 0.13, 0.15))
	_resuelto = CaseManager.tiene_pista("soplon_acusado")

func _process(delta: float) -> void:
	if _gracia > 0.0:
		_gracia -= delta
		if _gracia <= 0.0:
			_set_guardias(true)

# --- Acusación -------------------------------------------------------------

func _on_acusar(id: String, spot) -> void:
	if _resuelto:
		return
	if not (CaseManager.tiene_pista("placa_policia") and CaseManager.tiene_pista("libreta_pagos")):
		hud.mostrar("Jefa Cacaraca: Sin pruebas no acuso a nadie. Tráigame la placa perdida y la libreta de pagos.", 4.0)
		spot.reiniciar()
		return
	if id != CULPABLE:
		hud.mostrar_lineas(PackedStringArray([
			"Jefa Cacaraca: ¿El comandante %s? ¡Él tiene su placa y estaba aquí el viernes!" % NOMBRES[id],
			"Jefa Cacaraca: ¡Acusó a un inocente! Fuera de mi comisaría, detective.",
		]), 3.0)
		spot.reiniciar()
		await get_tree().create_timer(3.0).timeout
		_echar()
		return
	_resuelto = true
	hud.mostrar_lineas(PackedStringArray(CONFESION), SEG_LINEA)
	await get_tree().create_timer(SEG_LINEA * CONFESION.size()).timeout
	CaseManager.agregar_pista("soplon_acusado")

# --- Sigilo en los vestidores -----------------------------------------------

func _on_detectado(_g: Node) -> void:
	if _gracia > 0.0:
		return
	hud.mostrar("Policía: ¡Oiga! Los vestidores son solo para personal. ¡Afuera!", 3.0)
	_echar()

func _echar() -> void:
	if player.current_vehicle:
		player.current_vehicle.exit()
	player.global_position = calle.global_position
	player.velocity = Vector2.ZERO
	for g in get_tree().get_nodes_in_group("guardias"):
		g.reiniciar()
	_set_guardias(false)
	_gracia = 1.5

func _set_guardias(v: bool) -> void:
	for g in get_tree().get_nodes_in_group("guardias"):
		g.activo = v
