extends Node2D
## Arena del jefe final. Conecta a Don Crestón con el HUD y con CaseManager.

@onready var boss: DonCreston = $DonCreston
@onready var barra: ProgressBar = $HUD/BarraJefe
@onready var aviso_label: Label = $HUD/Aviso
@onready var fin_label: Label = $HUD/Fin

var _aviso_timer: float = 0.0

func _ready() -> void:
	CaseManager.sincronizar_con_zona("arena_jefe")
	boss.health_changed.connect(_on_boss_health)
	boss.aviso.connect(_mostrar_aviso)
	boss.died.connect(_on_boss_died)
	fin_label.visible = false
	_mostrar_aviso("Su armadura es de oro... ¡haz que choque contra los pilares!")

func _process(delta: float) -> void:
	if _aviso_timer > 0.0:
		_aviso_timer -= delta
		if _aviso_timer <= 0.0:
			aviso_label.text = ""

func _on_boss_health(current: int, maximum: int) -> void:
	barra.max_value = maximum
	barra.value = current

func _mostrar_aviso(texto: String) -> void:
	aviso_label.text = texto
	_aviso_timer = 1.8

func _on_boss_died(_who: Node2D, _killer: Node) -> void:
	fin_label.visible = true
	CaseManager.agregar_pista("confesion_creston")
	await get_tree().create_timer(3.0).timeout
	CaseManager.completar_nivel()
