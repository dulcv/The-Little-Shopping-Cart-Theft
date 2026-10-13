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
	_ensure_placeholder_dot()
	body_entered.connect(_on_body_entered)

## PLACEHOLDER visible: el Sprite2D no trae textura; se dibuja un
## rombo cian hasta tener sprite de casete/libreta/foto.
func _ensure_placeholder_dot() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null and sprite.texture != null:
		return
	var dot := ColorRect.new()
	dot.name = "PlaceholderDot"
	dot.color = Color(0.3, 1.0, 1.0, 1.0)
	dot.offset_left = -5.0
	dot.offset_top = -5.0
	dot.offset_right = 5.0
	dot.offset_bottom = 5.0
	add_child(dot)

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
