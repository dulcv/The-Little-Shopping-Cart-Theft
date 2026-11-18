extends Control
## Menú principal: Nuevo caso / Continuar / Salir.
## Fondo con los edificios del Centro y el detective pollo animado.

const FUENTE := preload("res://assets/fonts/BoldPixels.ttf")
const EDIFICIOS := preload("res://assets/sprites/edificios/edificios.png")
const POLLO := preload("res://scenes/characters/player/player1_sprite_frames.tres")
## Regiones de edificios.png (fachadas completas) para la fila del fondo.
const FACHADAS := [Rect2(8, 0, 95, 156), Rect2(104, 0, 95, 156), Rect2(200, 30, 126, 126),
	Rect2(8, 158, 95, 94), Rect2(104, 158, 95, 94), Rect2(200, 158, 95, 94)]

var _botones: Array[Button] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo()
	_titulo()
	_menu()
	if has_node("/root/Musica"):
		get_node("/root/Musica").tocar("menu")

func _fondo() -> void:
	var cielo := ColorRect.new()
	cielo.color = Color(0.16, 0.13, 0.24)
	cielo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cielo)
	var luna := Polygon2D.new()
	luna.color = Color(1, 0.93, 0.7)
	luna.position = Vector2(420, 34)
	luna.polygon = PackedVector2Array([Vector2(-4, -9), Vector2(4, -9), Vector2(9, -4), Vector2(9, 4),
		Vector2(4, 9), Vector2(-4, 9), Vector2(-9, 4), Vector2(-9, -4)])
	add_child(luna)
	var sombra_luna := Polygon2D.new()  # luna creciente
	sombra_luna.color = Color(0.16, 0.13, 0.24)
	sombra_luna.position = Vector2(425, 31)
	sombra_luna.polygon = luna.polygon
	add_child(sombra_luna)
	# Fila de edificios (tu arte del Centro) a lo largo del horizonte.
	var x := -20.0
	var i := 0
	while x < 520.0:
		var r: Rect2 = FACHADAS[(i * 4 + 1) % FACHADAS.size()]
		var t := AtlasTexture.new()
		t.atlas = EDIFICIOS
		t.region = r
		var s := TextureRect.new()
		s.texture = t
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2(x, 210 - r.size.y)
		s.modulate = Color(0.55, 0.5, 0.7)  # de noche
		add_child(s)
		x += r.size.x - 2
		i += 1
	var piso := ColorRect.new()
	piso.color = Color(0.25, 0.25, 0.28)
	piso.position = Vector2(0, 208)
	piso.size = Vector2(480, 70)
	add_child(piso)
	var linea := ColorRect.new()
	linea.color = Color(0.95, 0.85, 0.3)
	linea.position = Vector2(0, 238)
	linea.size = Vector2(480, 2)
	add_child(linea)
	var pollo := AnimatedSprite2D.new()
	pollo.sprite_frames = POLLO
	pollo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pollo.scale = Vector2(3, 3)
	pollo.position = Vector2(90, 190)
	pollo.play(&"idle")
	add_child(pollo)
	Accesorio.poner(pollo, "sombrero_detective", Vector2(3, -8))

func _label(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.05))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _titulo() -> void:
	var t := _label("OPERACIÓN MAZORCA", 32, Color(1, 0.84, 0.25))
	t.position = Vector2(0, 26)
	t.size = Vector2(480, 40)
	add_child(t)
	var st := _label("The Little Shopping Cart Theft", 8, Color(0.95, 0.92, 1))
	st.position = Vector2(0, 64)
	st.size = Vector2(480, 12)
	add_child(st)

func _boton(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_override("font", FUENTE)
	b.add_theme_font_size_override("font_size", 8)
	b.custom_minimum_size = Vector2(120, 18)
	for estado in ["normal", "hover", "focus", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = {"normal": Color(0.2, 0.14, 0.1, 0.9), "hover": Color(0.55, 0.35, 0.12),
			"focus": Color(0.75, 0.5, 0.12), "pressed": Color(0.9, 0.65, 0.2),
			"disabled": Color(0.2, 0.2, 0.2, 0.6)}[estado]
		sb.border_color = Color(0.08, 0.05, 0.05)
		sb.set_border_width_all(1)
		add_theme_stylebox_override(estado, sb)
		b.add_theme_stylebox_override(estado, sb)
	b.pressed.connect(accion)
	_botones.append(b)
	return b

func _menu() -> void:
	var caja := VBoxContainer.new()
	caja.position = Vector2(300, 100)
	caja.add_theme_constant_override("separation", 5)
	add_child(caja)
	var nuevo := _boton("Nuevo caso", _on_nuevo)
	var cont := _boton("Continuar caso", _on_continuar)
	cont.disabled = not CaseManager.hay_partida()
	caja.add_child(nuevo)
	caja.add_child(cont)
	caja.add_child(_boton("Salir", func(): get_tree().quit()))
	var ayuda := _label("WASD: moverse   Espacio/clic: atacar   E: interactuar   Esc: pausa", 8, Color(0.85, 0.85, 0.9))
	ayuda.position = Vector2(0, 252)
	ayuda.size = Vector2(480, 12)
	add_child(ayuda)
	# Con partida guardada, el foco empieza en "Continuar".
	(nuevo if cont.disabled else cont).grab_focus.call_deferred()

func _on_nuevo() -> void:
	get_node("/root/Juego").ir_a_escena(get_node("/root/Juego").SELECCION)

func _on_continuar() -> void:
	CaseManager.continuar()
