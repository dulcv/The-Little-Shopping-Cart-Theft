extends CanvasLayer
## HUD placeholder (docs/04 + contratos doc 09 + biblia-minima):
## HP bar, maiz (dinero), 5 huevos (guardia/wanted), plumas (federacion),
## arma actual y mensaje de dialogo. Todo texto PLACEHOLDER_*.
##
## Escucha: health_changed (player/companion via bind_player), money_changed
## y federacion_changed (GameManager), wanted_changed/guardia_changed y
## federacion_changed (WantedSystem si existe como Autoload). Sin arte final.

const EGG_FULL := "O"
const EGG_EMPTY := "o"
const FEATHER_FULL := "V"
const FEATHER_EMPTY := "v"
const MAX_LEVEL := 5

@onready var _hp_bar: ProgressBar = $TopLeft/HPBar
@onready var _hp_label: Label = $TopLeft/HPLabel
@onready var _money_label: Label = $TopLeft/MoneyLabel
@onready var _eggs_label: Label = $TopRight/EggsLabel
@onready var _feathers_label: Label = $TopRight/FeathersLabel
@onready var _weapon_label: Label = $BottomRight/WeaponLabel
@onready var _dialogue_label: Label = $BottomCenter/DialogueLabel

var _bound_health: Object = null


func _ready() -> void:
	layer = 10
	UIManager.set_hud(self)
	_set_hp(100, 100)
	_set_money(GameManager.money)
	_set_guardia(_get_wanted_level())
	_set_federacion(GameManager.federacion_level)
	_set_weapon("PLACEHOLDER_arma_ninguna")
	set_dialogue_text("")
	# Contratos doc 09 (GameManager es Autoload: conexion directa segura).
	GameManager.money_changed.connect(_set_money)
	GameManager.federacion_changed.connect(_set_federacion)
	# WantedSystem aun no es Autoload: solo si existe (ver wanted_system.gd).
	var wanted := get_node_or_null("/root/WantedSystem")
	if wanted != null:
		if wanted.has_signal("wanted_changed"):
			wanted.connect("wanted_changed", _set_guardia)
		if wanted.has_signal("guardia_changed"):
			wanted.connect("guardia_changed", _set_guardia)
		if wanted.has_signal("federacion_changed"):
			wanted.connect("federacion_changed", _set_federacion)
	# Intentar enlazar player ya presente en el nivel.
	_auto_bind_player()
	# DialogueSystem aun no existe: solo si aparece como Autoload.
	var dlg := get_node_or_null("/root/DialogueSystem")
	if dlg != null and dlg.has_signal("dialogue_finished"):
		dlg.connect("dialogue_finished", _on_dialogue_finished)


## Enlaza un cuerpo con senal health_changed(current, maximum) y opcional
## died + arma (weapon/weapon_equipped). Llamar al spawnear el player.
func bind_player(body: Node) -> void:
	if body == null:
		return
	if _bound_health != null and is_instance_valid(_bound_health):
		if _bound_health.has_signal("health_changed"):
			_bound_health.disconnect("health_changed", _set_hp)
	if body.has_signal("health_changed"):
		body.connect("health_changed", _set_hp)
		_bound_health = body
	var weapon: Variant = body.get("weapon")
	if weapon != null and (weapon as Object).has_signal("weapon_equipped"):
		(weapon as Object).connect("weapon_equipped", _on_weapon_equipped)
	_refresh_weapon_from(body)


func set_dialogue_text(text: String) -> void:
	_dialogue_label.text = text


func _auto_bind_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		bind_player(players[0])


func _get_wanted_level() -> int:
	var wanted := get_node_or_null("/root/WantedSystem")
	if wanted != null:
		var v: Variant = wanted.get("guardia_level")
		if v is int:
			return v
		var w: Variant = wanted.get("wanted_level")
		if w is int:
			return w
	return 0


func _set_hp(current: int, maximum: int) -> void:
	var maxv := maxi(1, maximum)
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = float(maxv)
	_hp_bar.value = float(clampi(current, 0, maxv))
	_hp_label.text = "PLACEHOLDER_hp_%d_%d" % [current, maxv]


func _set_money(amount: int) -> void:
	_money_label.text = "PLACEHOLDER_maiz_%d" % amount


func _set_guardia(level: int) -> void:
	_eggs_label.text = "PLACEHOLDER_huevos_" + _pips(level)


func _set_federacion(level: int) -> void:
	_feathers_label.text = "PLACEHOLDER_plumas_" + _pips(level, true)


func _pips(level: int, feathers: bool = false) -> String:
	var full := FEATHER_FULL if feathers else EGG_FULL
	var empty := FEATHER_EMPTY if feathers else EGG_EMPTY
	var out := ""
	for i in MAX_LEVEL:
		out += full if i < clampi(level, 0, MAX_LEVEL) else empty
	return out


func _on_weapon_equipped(data: WeaponData) -> void:
	if data == null:
		_set_weapon("PLACEHOLDER_arma_ninguna")
	else:
		var wid: Variant = data.get("id")
		_set_weapon("PLACEHOLDER_arma_%s" % str(wid) if wid is String and not (wid as String).is_empty() else "PLACEHOLDER_arma")


func _refresh_weapon_from(body: Node) -> void:
	var weapon: Variant = body.get("weapon")
	if weapon == null:
		return
	var data: Variant = (weapon as Object).get("current_data")
	if data == null:
		data = (weapon as Object).get("data")
	if data is WeaponData:
		_on_weapon_equipped(data as WeaponData)


func _on_dialogue_finished(_id: String) -> void:
	set_dialogue_text("")


func _set_weapon(text: String) -> void:
	_weapon_label.text = text
