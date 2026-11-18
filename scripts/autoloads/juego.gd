extends CanvasLayer
## Autoload "Juego": flujo general de la partida.
## - Transiciones con fundido + cartel del nivel ("Nivel 2: La Fiesta del Gallo").
## - Pausa (Esc): continuar / menú principal / salir.
## - Game over cuando el jugador muere: Enter = reintentar (se conservan pistas).
## - Final del caso -> pantalla de créditos.
## La UI se construye por código para no depender de escenas extra.

const MENU := "res://scenes/ui/menus/menu_principal.tscn"
const SELECCION := "res://scenes/ui/menus/seleccion_personaje.tscn"
const COCHERA := "res://scenes/world/cochera/Cochera.tscn"
const PERSONAJE_DEFAULT := "res://resources/characters/detective.tres"
const FINAL := "res://scenes/ui/menus/final.tscn"
const FUENTE := preload("res://assets/fonts/BoldPixels.ttf")

var _fundido: ColorRect
var _cartel: Label
var _subcartel: Label
var _pausa: Control
var _game_over: Control
var _escena_vista: Node = null
## Personaje elegido en la selección (lo aplica player.gd).
var personaje: CharacterData
var _cambiando: bool = false
## Cambio pedido durante otra transición: se hace al terminar (no se pierde).
var _pendiente: Array = []

func _ready() -> void:
	layer = 100
	if personaje == null:
		personaje = load(PERSONAJE_DEFAULT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir_ui()
	CaseManager.caso_resuelto.connect(_on_caso_resuelto)

func _process(_delta: float) -> void:
	var actual := get_tree().current_scene
	if actual != _escena_vista:
		_escena_vista = actual
		_game_over.visible = false
		var p := get_tree().get_first_node_in_group("player")
		if p and p.has_signal("died") and not p.died.is_connected(_on_jugador_murio):
			p.died.connect(_on_jugador_murio)

func _unhandled_input(event: InputEvent) -> void:
	if _game_over.visible:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			reintentar()
		return
	if event.is_action_pressed("ui_cancel") and not _cambiando and _es_nivel():
		get_viewport().set_input_as_handled()
		set_pausa(not get_tree().paused)
	elif get_tree().paused and _pausa.visible and event is InputEventKey and event.pressed:
		match (event as InputEventKey).physical_keycode:
			KEY_M:
				set_pausa(false)
				ir_a_escena(MENU)
			KEY_Q:
				get_tree().quit()

func _es_nivel() -> bool:
	var s := get_tree().current_scene
	return s != null and not s.scene_file_path in [MENU, FINAL, SELECCION]

# --- API ---------------------------------------------------------------------

func set_personaje_por_id(id: String) -> void:
	var ruta := "res://resources/characters/%s.tres" % id
	if ResourceLoader.exists(ruta):
		personaje = load(ruta)

## Cambia de escena con fundido a negro y, opcional, un cartel de título.
func ir_a_escena(ruta: String, titulo: String = "", subtitulo: String = "") -> void:
	if _cambiando:
		_pendiente = [ruta, titulo, subtitulo]
		return
	_cambiando = true
	get_tree().paused = false
	_pausa.visible = false
	_game_over.visible = false
	_cartel.text = titulo
	_subcartel.text = subtitulo
	var tw := create_tween()
	tw.tween_property(_fundido, "modulate:a", 1.0, 0.45)
	await tw.finished
	get_tree().change_scene_to_file(ruta)
	if not titulo.is_empty():
		await get_tree().create_timer(1.8).timeout
	else:
		await get_tree().process_frame
	tw = create_tween()
	tw.tween_property(_fundido, "modulate:a", 0.0, 0.45)
	await tw.finished
	_cartel.text = ""
	_subcartel.text = ""
	_cambiando = false
	if not _pendiente.is_empty():
		var p: Array = _pendiente
		_pendiente = []
		ir_a_escena(p[0], p[1], p[2])

func reintentar() -> void:
	var s := get_tree().current_scene
	if s:
		ir_a_escena(s.scene_file_path)

func set_pausa(v: bool) -> void:
	get_tree().paused = v
	_pausa.visible = v

# --- Señales -------------------------------------------------------------------

func _on_jugador_murio(_who: Node2D, _killer: Node) -> void:
	await get_tree().create_timer(1.0).timeout
	_game_over.visible = true

func _on_caso_resuelto() -> void:
	await get_tree().create_timer(2.5).timeout
	ir_a_escena(FINAL)

# --- UI ------------------------------------------------------------------------

func _label(texto: String, tam: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.05))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _panel_centrado(lineas: Array) -> Control:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.03, 0.03, 0.72)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(fondo)
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 6)
	raiz.add_child(caja)
	for l in lineas:
		caja.add_child(l)
	raiz.visible = false
	add_child(raiz)
	return raiz

func _construir_ui() -> void:
	_pausa = _panel_centrado([
		_label("PAUSA", 24, Color(1, 0.85, 0.3)),
		_label("Esc: continuar", 8),
		_label("M: menú principal", 8),
		_label("Q: salir del juego", 8),
	])
	_game_over = _panel_centrado([
		_label("¡TE DESPLUMARON!", 24, Color(1, 0.35, 0.3)),
		_label("Tus pistas están a salvo en el expediente.", 8),
		_label("Enter: reintentar", 8, Color(1, 0.95, 0.6)),
	])
	_fundido = ColorRect.new()
	_fundido.color = Color.BLACK
	_fundido.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundido.modulate.a = 0.0
	add_child(_fundido)
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundido.add_child(caja)
	_cartel = _label("", 16, Color(1, 0.85, 0.3))
	_subcartel = _label("", 8)
	caja.add_child(_cartel)
	caja.add_child(_subcartel)
