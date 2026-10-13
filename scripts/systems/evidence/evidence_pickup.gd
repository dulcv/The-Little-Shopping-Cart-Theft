class_name EvidencePickup
extends Area2D

## Scaffolding: pickup de evidencia en capa 6 ("Pickups").
## Delega el registro a GameManager.add_evidence(ev) si existe;
## si no, emite collected para que MissionManager/tests lo capturen.

signal collected(evidence_id: String)

@export var evidence: EvidenceData

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 1 << 5 # capa 6
	collision_mask = 1 << 1 # detecta capa 2 (Player)
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node2D) -> void:
	if evidence == null:
		push_warning("EvidencePickup sin EvidenceData asignada.")
		return
	collected.emit(evidence.id)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("add_evidence"):
		gm.add_evidence(evidence)
	else:
		push_warning("GameManager.add_evidence no disponible; evidencia '%s' solo emitida." % evidence.id)
	queue_free()
