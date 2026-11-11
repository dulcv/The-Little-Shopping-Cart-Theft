extends Area2D
## Pista recogible (capa 6 Pickups). Al tocarla el jugador, la registra en
## CaseManager y desaparece. Si ya la tenía (recarga de escena), no aparece.

@export var pista_id: String = "pluma_dorada"

var _t: float = 0.0
@onready var visual: Node2D = $Visual

func _ready() -> void:
	add_to_group("pickups")
	if CaseManager.tiene_pista(pista_id):
		queue_free()
		return
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Flota y brilla para que se note en el mapa.
	_t += delta
	visual.position.y = sin(_t * 4.0) * 1.5
	visual.modulate.a = 0.75 + sin(_t * 6.0) * 0.25

func _on_body_entered(body: Node2D) -> void:
	# Capa 2 = Player.
	if body is CollisionObject2D and (body as CollisionObject2D).collision_layer & 2:
		CaseManager.agregar_pista(pista_id)
		queue_free()
