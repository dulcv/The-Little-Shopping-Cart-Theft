class_name MissionManager
extends Node

## Stub de misiones (doc 11, apdo. 4). Todo texto visible = PLACEHOLDER_*.
## Flujo: add_evidence (GameManager) -> try_unlock(evidence_id) ->
## mission_unlocked -> complete_mission -> mission_completed.
## Autoload-ready (NO registrar en este commit).

signal mission_unlocked(mission_id: String)
signal mission_completed(mission_id: String)

## mission_id -> MissionData (inyectado desde resources/missions/*.tres).
@export var missions: Array[MissionData] = []

var unlocked: Dictionary = {}
var completed: Dictionary = {}

func is_unlocked(mission_id: String) -> bool:
	return unlocked.get(mission_id, false)

func is_completed(mission_id: String) -> bool:
	return completed.get(mission_id, false)

## Llamado cuando GameManager.add_evidence registra una evidencia.
## Desbloquea toda mision cuyo requisito_evidencia coincida.
func try_unlock(evidence_id: String) -> Array[String]:
	var newly: Array[String] = []
	for m in missions:
		if m == null:
			continue
		if m.requisito_evidencia == evidence_id and not is_unlocked(m.mission_id):
			unlocked[m.mission_id] = true
			newly.append(m.mission_id)
			mission_unlocked.emit(m.mission_id)
	return newly

func complete_mission(mission_id: String) -> void:
	if is_completed(mission_id):
		return
	completed[mission_id] = true
	mission_completed.emit(mission_id)
