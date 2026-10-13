extends Control
## LoadingGame placeholder (docs/04): carga async de escena_principal con
## ProgressBar alimentada por SceneLoader.progress + tips rotando.

const TARGET_SCENE := "res://scenes/main/escena_principal.tscn"
const TIPS: Array[String] = [
	"PLACEHOLDER_tip_1",
	"PLACEHOLDER_tip_2",
	"PLACEHOLDER_tip_3",
]

@onready var _bar: ProgressBar = $Center/VBox/LoadBar
@onready var _pct: Label = $Center/VBox/LoadPct
@onready var _tip: Label = $Center/VBox/Tip
@onready var _tip_timer: Timer = $TipTimer

var _tip_idx: int = 0


func _ready() -> void:
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.value = 0.0
	_pct.text = "PLACEHOLDER_cargando_0"
	_tip.text = TIPS[_tip_idx]
	SceneLoader.progress.connect(_on_loader_progress)
	SceneLoader.load_failed.connect(_on_loader_failed)
	_tip_timer.timeout.connect(_on_tip_timeout)
	_tip_timer.start()
	var err := SceneLoader.load_threaded(TARGET_SCENE)
	if err != OK:
		_on_loader_failed(TARGET_SCENE)


func _on_loader_progress(ratio: float) -> void:
	_bar.value = clampf(ratio, 0.0, 1.0)
	_pct.text = "PLACEHOLDER_cargando_%d" % int(round(ratio * 100.0))


func _on_loader_failed(path: String) -> void:
	_tip_timer.stop()
	_tip.text = "PLACEHOLDER_error_carga"
	push_warning("loading_game: fallo carga %s" % path)


func _on_tip_timeout() -> void:
	_tip_idx = (_tip_idx + 1) % TIPS.size()
	_tip.text = TIPS[_tip_idx]
