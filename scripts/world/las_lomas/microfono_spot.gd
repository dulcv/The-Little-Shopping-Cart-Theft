extends Area2D
## Punto de "mantén E" reutilizable: plantar el micrófono (Las Lomas),
## tomar la foto del plantío (Rancho Maizal), etc.
## El jugador entra al área y MANTIENE E durante `tiempo_plantar` segundos.
## Al terminar emite `plantado`; el nivel arranca la conversación.

signal plantado

@export var tiempo_plantar: float = 2.0
## Si no está vacío, reemplaza el texto del Label "Ayuda".
@export var texto_ayuda: String = ""

var dentro: bool = false
var listo: bool = false
var _progreso: float = 0.0

@onready var barra: ProgressBar = $Barra
@onready var ayuda: Label = $Ayuda
@onready var bicho: Polygon2D = $Bicho

func _ready() -> void:
	body_entered.connect(func(b): if _es_jugador(b): dentro = true)
	body_exited.connect(func(b): if _es_jugador(b): dentro = false)
	if not texto_ayuda.is_empty():
		ayuda.text = texto_ayuda
	reiniciar()

func _process(delta: float) -> void:
	if listo:
		return
	ayuda.visible = dentro
	if dentro and Input.is_action_pressed("interact"):
		_progreso += delta
		barra.visible = true
		barra.value = _progreso / tiempo_plantar * 100.0
		if _progreso >= tiempo_plantar:
			listo = true
			barra.visible = false
			ayuda.visible = false
			bicho.visible = true
			plantado.emit()
	else:
		_progreso = 0.0
		barra.visible = false

func reiniciar() -> void:
	listo = false
	_progreso = 0.0
	barra.visible = false
	ayuda.visible = false
	bicho.visible = false

func _es_jugador(b: Node) -> bool:
	return b.is_in_group("player")
