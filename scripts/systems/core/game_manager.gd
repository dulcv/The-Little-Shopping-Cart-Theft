extends Node
## Autoload "GameManager".
## Fuente de verdad: personaje(s), zona, pausa, dinero (maíz), muro de
## evidencias y espejo de notoriedad-federación.
## Contratos: docs/01-base-bloqueante.md, docs/09-contratos-interfaces.md.
##
## Sin `class_name` a propósito: el nombre del Autoload ya es accesible como
## global (`GameManager.money`); un class_name idéntico provocaría el error
## "hides an Autoload singleton" en Godot 4.
## `selected_character` se tipa como Resource hasta que exista CharacterData
## (docs/03-seleccion-personajes.md); cambiar el tipo entonces sin tocar lógica.

signal character_changed(character: Resource)
signal zone_changed(zone: String)
signal duo_changed(is_duo: bool)
signal money_changed(amount: int)
signal evidence_added(id: String)
signal federacion_changed(level: int)

const FEDERACION_MAX := 5

## Contrato doc 09: será `CharacterData` (pendiente, doc 03).
var selected_character: Resource = null
var current_zone: String = "el_centro"
var is_paused: bool = false

## Dúo v1 (doc 09): ["edgar"] en solitario, ["edgar", "dulce"] juntos.
var selected_ids: Array[String] = ["edgar"]
var is_duo: bool = false

## Economía (docs 08/09): moneda = maíz.
var money: int = 0

## Muro de pruebas (doc 11): id -> EvidenceData.
var evidence_wall: Dictionary = {}

## Espejo de notoriedad-federación (doc 11). La lógica (decaimiento, patrullas)
## vive en WantedSystem (otro agente); aquí solo nivel + señal de contrato.
var federacion_level: int = 0


func select_character(character: Resource) -> void:
	selected_character = character
	character_changed.emit(character)


func set_zone(zone: String) -> void:
	if current_zone == zone:
		return
	current_zone = zone
	zone_changed.emit(zone)


func set_paused(value: bool) -> void:
	is_paused = value
	get_tree().paused = value


func set_selected_ids(ids: Array[String]) -> void:
	selected_ids = ids
	set_duo(selected_ids.has("edgar") and selected_ids.has("dulce"))


func set_duo(enabled: bool) -> void:
	if is_duo == enabled:
		return
	is_duo = enabled
	duo_changed.emit(is_duo)


func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	money_changed.emit(money)


func add_evidence(evidence: EvidenceData) -> void:
	if evidence == null:
		return
	evidence_wall[evidence.id] = evidence
	evidence_added.emit(evidence.id)


func has_evidence(id: String) -> bool:
	return evidence_wall.has(id)


func evidence_count() -> int:
	return evidence_wall.size()


func add_federacion(amount: int, _reason: String = "") -> void:
	var next: int = clampi(federacion_level + amount, 0, FEDERACION_MAX)
	if next == federacion_level:
		return
	federacion_level = next
	federacion_changed.emit(federacion_level)


## Alias para diálogos `{alias}` (docs 06/09): lee `alias_llamado` por
## duck-typing para no exigir CharacterData en tiempo de parseo.
func get_alias(default_alias: String = "PLACEHOLDER_alias") -> String:
	if selected_character != null:
		var value: Variant = selected_character.get("alias_llamado")
		if value is String and not (value as String).is_empty():
			return value
	return default_alias
