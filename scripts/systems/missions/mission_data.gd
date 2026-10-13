class_name MissionData
extends Resource

## Scaffolding de mision v1 (doc 11, apdo. 4). Todo texto = PLACEHOLDER_*.

@export var mission_id: String = "PLACEHOLDER_mission_id"
@export var title: String = "PLACEHOLDER_titulo"
@export_multiline var description: String = "PLACEHOLDER_descripcion"
## id de EvidenceData requerida ("" = sin requisito, ej. tutorial_radio).
@export var requisito_evidencia: String = ""
@export var zone: String = "PLACEHOLDER_zona"
@export var objective: String = "PLACEHOLDER_objetivo"
@export var reward_maiz: int = 0
