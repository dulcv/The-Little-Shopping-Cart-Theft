extends Control
## Selección de personaje: A/D o flechas para elegir, Enter/E para empezar, Esc para volver.
## Para agregar o cambiar personajes edita PERSONAJES y resources/characters/*.tres.

const FUENTE := preload("res://assets/fonts/BoldPixels.ttf")
const PERSONAJES := ["detective", "edgar", "dulce", "jess", "ana"]
const NOMBRES_ARMA := {"lanzahuevos": "Lanzahuevos", "pistol": "Pistola", "assault_rifle": "Rifle"}

var _datos: Array[CharacterData] = []
var _tarjetas: Array[Panel] = []
var _sel: int = 0
var _nombre: Label
var _desc: Label
var _stats: Label
var _listo: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for id in PERSONAJES:
		var d := load("res://resources/characters/%s.tres" % id) as CharacterData
		if d:
			_datos.append(d)
	var actual: CharacterData = get_node("/root/Juego").personaje
	if actual:
		_sel = maxi(PERSONAJES.find(actual.id), 0)
	_construir()
	_actualizar()

func _label(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.05))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.16, 0.13, 0.24)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var t := _label("ELIGE A TU DETECTIVE", 16, Color(1, 0.84, 0.25))
	t.position = Vector2(0, 10)
	t.size = Vector2(480, 20)
	add_child(t)
	var ancho := 84.0
	var x0 := (480.0 - ancho * _datos.size() - 6.0 * (_datos.size() - 1)) / 2.0
	for i in _datos.size():
		var d := _datos[i]
		var p := Panel.new()
		p.position = Vector2(x0 + i * (ancho + 6.0), 40)
		p.size = Vector2(ancho, 100)
		add_child(p)
		_tarjetas.append(p)
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = d.sprite_frames
		spr.self_modulate = d.color
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.scale = Vector2(3, 3)
		spr.position = Vector2(ancho / 2.0, 50)
		spr.play(&"idle")
		p.add_child(spr)
		if not d.accesorio.is_empty():
			Accesorio.poner(spr, d.accesorio, d.accesorio_lado)
		var n := _label(d.display_name, 8, Color.WHITE)
		n.position = Vector2(0, 82)
		n.size = Vector2(ancho, 12)
		p.add_child(n)
	_nombre = _label("", 16, Color(1, 0.84, 0.25))
	_nombre.position = Vector2(0, 148)
	_nombre.size = Vector2(480, 20)
	add_child(_nombre)
	_desc = _label("", 8, Color(0.95, 0.95, 1))
	_desc.position = Vector2(40, 172)
	_desc.size = Vector2(400, 30)
	add_child(_desc)
	_stats = _label("", 8, Color(1, 0.75, 0.4))
	_stats.position = Vector2(0, 208)
	_stats.size = Vector2(480, 12)
	add_child(_stats)
	var ayuda := _label("A/D: elegir    Enter: empezar el caso    Esc: volver", 8, Color(0.8, 0.8, 0.9))
	ayuda.position = Vector2(0, 248)
	ayuda.size = Vector2(480, 12)
	add_child(ayuda)

func _estilo(activa: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.55, 0.38, 0.12, 0.95) if activa else Color(0.1, 0.08, 0.14, 0.85)
	sb.border_color = Color(1, 0.84, 0.25) if activa else Color(0.3, 0.27, 0.4)
	sb.set_border_width_all(2 if activa else 1)
	return sb

func _actualizar() -> void:
	for i in _tarjetas.size():
		_tarjetas[i].add_theme_stylebox_override("panel", _estilo(i == _sel))
	var d := _datos[_sel]
	_nombre.text = d.display_name
	_desc.text = d.description
	var arma := "-"
	if d.starting_weapon:
		arma = NOMBRES_ARMA.get(d.starting_weapon.id, d.starting_weapon.weapon_name)
	_stats.text = "Vida: %d    Velocidad: %d%%    Arma: %s" % [d.max_hp, roundi(d.speed_mult * 100.0), arma]

func _unhandled_input(event: InputEvent) -> void:
	if _listo:
		return
	var mover := 0
	if event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_A):
		mover = -1
	elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_D):
		mover = 1
	if mover != 0:
		_sel = wrapi(_sel + mover, 0, _datos.size())
		_actualizar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		elegir()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_node("/root/Juego").ir_a_escena(get_node("/root/Juego").MENU)

## Confirma el personaje y empieza un caso nuevo (pasa por la cochera).
func elegir() -> void:
	_listo = true
	get_node("/root/Juego").personaje = _datos[_sel]
	CaseManager.borrar_partida()
	CaseManager.reiniciar_caso()
