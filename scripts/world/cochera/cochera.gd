extends Node2D
## La Cochera: cuartel secreto del detective encubierto (como en el caso real,
## donde el agente llevaba la investigación desde un lugar discreto).
## Entre nivel y nivel vuelves aquí: el tablero muestra cómo va el caso
## y la cortina del garage te lleva al siguiente nivel.

@onready var hud := $ExpedienteHUD
@onready var lista: VBoxContainer = $Tablero/Lista
@onready var zona_tablero: Area2D = $Tablero/Zona
@onready var ayuda_tablero: Label = $Tablero/Zona/Ayuda
@onready var salida = $Salida

const FUENTE := preload("res://assets/fonts/BoldPixels.ttf")

var _en_tablero: bool = false

func _ready() -> void:
	zona_tablero.body_entered.connect(func(b): if b.is_in_group("player"): _en_tablero = true)
	zona_tablero.body_exited.connect(func(b): if b.is_in_group("player"): _en_tablero = false)
	salida.plantado.connect(_on_salir)
	var siguiente: LevelData = CaseManager.nivel_actual
	if siguiente:
		salida.ayuda.text = "Mantén E: salir al caso (%s)" % siguiente.titulo
	_llenar_tablero()

func _process(_delta: float) -> void:
	ayuda_tablero.visible = _en_tablero
	if _en_tablero and Input.is_action_just_pressed("interact"):
		_leer_expediente()

func _llenar_tablero() -> void:
	for i in CaseManager.NIVELES.size():
		var data := load(CaseManager.NIVELES[i]) as LevelData
		var marca := "[OK]" if i < CaseManager.nivel_index else (">> " if i == CaseManager.nivel_index else "[??]")
		var titulo := data.titulo if i <= CaseManager.nivel_index else "???"
		var l := Label.new()
		l.text = "%s %d. %s" % [marca, i + 1, titulo]
		l.add_theme_font_override("font", FUENTE)
		l.add_theme_font_size_override("font_size", 8)
		var color := Color(0.15, 0.4, 0.15) if i < CaseManager.nivel_index else (Color(0.55, 0.1, 0.1) if i == CaseManager.nivel_index else Color(0.3, 0.25, 0.2))
		l.add_theme_color_override("font_color", color)
		lista.add_child(l)

func _leer_expediente() -> void:
	var lineas := PackedStringArray(["EXPEDIENTE - Operación Mazorca"])
	if CaseManager.pistas.is_empty():
		lineas.append("Aún no hay pistas. El caso empieza en El Centro.")
	for p in CaseManager.pistas:
		lineas.append("- " + CaseManager.TEXTO_PISTAS.get(p, p))
	if CaseManager.nivel_actual:
		lineas.append("Siguiente paso: " + CaseManager.nivel_actual.objetivo)
	hud.mostrar_lineas(lineas, 3.0)

func _on_salir() -> void:
	CaseManager.ir_a_nivel(CaseManager.nivel_index)
