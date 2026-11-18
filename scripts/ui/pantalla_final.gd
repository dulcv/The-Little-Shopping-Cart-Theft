extends Control
## Pantalla final: epílogo + créditos que suben. Enter/Esc = menú principal.
## Edita CREDITOS para poner los nombres del equipo.

const FUENTE := preload("res://assets/fonts/BoldPixels.ttf")
const MENU := "res://scenes/ui/menus/menu_principal.tscn"

const EPILOGO := [
	["¡CASO CERRADO!", 24, Color(1, 0.84, 0.25)],
	["Don Crestón fue capturado en su bodega del puerto.", 8, Color.WHITE],
	["El comandante Espolón perdió su placa... para siempre.", 8, Color.WHITE],
	["El Rancho Maizal ahora es un huerto comunitario.", 8, Color.WHITE],
	["Y el agente Kiko Cacareña volvió a casa, sano y salvo.", 8, Color(0.7, 1, 0.7)],
	["", 8, Color.WHITE],
]
const CREDITOS := [
	["OPERACIÓN MAZORCA", 16, Color(1, 0.84, 0.25)],
	["The Little Shopping Cart Theft", 8, Color.WHITE],
	["", 8, Color.WHITE],
	["Desarrollo, arte y diseño", 8, Color(1, 0.75, 0.4)],
	["El equipo de The Little Shopping Cart Theft", 8, Color.WHITE],
	["", 8, Color.WHITE],
	["Programación asistida", 8, Color(1, 0.75, 0.4)],
	["Claude Code (Anthropic)", 8, Color.WHITE],
	["", 8, Color.WHITE],
	["Música", 8, Color(1, 0.75, 0.4)],
	["(ver CREDITOS_MUSICA.txt)", 8, Color.WHITE],
	["", 8, Color.WHITE],
	["Una parodia con pollos inspirada en historias reales", 8, Color(0.8, 0.8, 0.85)],
	["de la lucha contra el narco. Nombres y hechos ficticios.", 8, Color(0.8, 0.8, 0.85)],
	["", 8, Color.WHITE],
	["¡Gracias por jugar!", 16, Color(1, 0.84, 0.25)],
]

var _caja: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.06, 0.1)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_caja = VBoxContainer.new()
	_caja.position = Vector2(0, 280)
	_caja.custom_minimum_size = Vector2(480, 0)
	_caja.add_theme_constant_override("separation", 4)
	add_child(_caja)
	for linea in EPILOGO + CREDITOS:
		var l := Label.new()
		l.text = linea[0]
		l.add_theme_font_override("font", FUENTE)
		l.add_theme_font_size_override("font_size", linea[1])
		l.add_theme_color_override("font_color", linea[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(480, 0)
		_caja.add_child(l)
	CaseManager.borrar_partida()
	if has_node("/root/Musica"):
		get_node("/root/Musica").tocar("final")

func _process(delta: float) -> void:
	# Sube hasta que "¡Gracias por jugar!" queda al centro.
	var alto := _caja.size.y
	_caja.position.y = maxf(_caja.position.y - 18.0 * delta, 135.0 - alto + 10.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_node("/root/Juego").ir_a_escena(MENU)
