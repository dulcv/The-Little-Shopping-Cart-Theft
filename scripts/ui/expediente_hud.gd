extends CanvasLayer
## HUD del detective: contador de pistas del nivel actual + aviso al
## recoger una. Escucha a CaseManager; instánciala en cada escena de nivel.

@onready var contador: Label = $Contador
@onready var aviso: Label = $Aviso

var _aviso_timer: float = 0.0
## Diálogos en cola: [texto, segundos]. Se muestran uno tras otro.
var _cola: Array = []

func _ready() -> void:
	add_to_group("expediente_hud")
	CaseManager.pista_obtenida.connect(_on_pista)
	CaseManager.nivel_iniciado.connect(func(_n): _actualizar())
	CaseManager.nivel_completado.connect(_on_nivel_completado)
	aviso.text = ""
	_actualizar()
	if CaseManager.nivel_actual:
		mostrar("%s\n%s" % [CaseManager.nivel_actual.titulo, CaseManager.nivel_actual.objetivo], 5.0)

func _process(delta: float) -> void:
	if _aviso_timer > 0.0:
		_aviso_timer -= delta
		if _aviso_timer <= 0.0:
			aviso.text = ""
			if not _cola.is_empty():
				var sig: Array = _cola.pop_front()
				aviso.text = sig[0]
				_aviso_timer = sig[1]

func _actualizar() -> void:
	var n := CaseManager.nivel_actual
	if n == null or n.pistas_requeridas.is_empty():
		contador.text = ""
		return
	var total := n.pistas_requeridas.size()
	var tengo := total - CaseManager.pistas_faltantes().size()
	contador.text = "Pistas: %d/%d" % [tengo, total]

func _on_pista(_id: String, texto: String) -> void:
	_actualizar()
	mostrar("PISTA: " + texto, 4.0)

func _on_nivel_completado(n: LevelData) -> void:
	mostrar("¡%s completado!" % n.titulo, 4.0)

func mostrar(texto: String, segundos: float) -> void:
	_cola.clear()
	aviso.text = texto
	_aviso_timer = segundos

## Muestra varias líneas seguidas (diálogos). Reemplaza lo que hubiera.
func mostrar_lineas(lineas: PackedStringArray, segundos_por_linea: float = 3.0) -> void:
	if lineas.is_empty():
		return
	mostrar(lineas[0], segundos_por_linea)
	for i in range(1, lineas.size()):
		_cola.append([lineas[i], segundos_por_linea])

func hablando() -> bool:
	return _aviso_timer > 0.0 and not _cola.is_empty()
