class_name EvidenceData
extends Resource

## Scaffolding de evidencia (doc 11). Todo texto visible = PLACEHOLDER_*.

enum Kind { CASSETTE, LEDGER, PHOTO, FLIGHT_LOG }

@export var id: String = "PLACEHOLDER_evidence_id"
@export var kind: int = Kind.CASSETTE
@export var title: String = "PLACEHOLDER_titulo"
@export var description: String = "PLACEHOLDER_descripcion"
@export var district: String = "el_centro"
## mission_id que esta evidencia habilita ("" = ninguna).
@export var unlocks_mission: String = ""
## Solo relevante para PHOTO: target_id al que quita inmunidad.
@export var target_id: String = ""
