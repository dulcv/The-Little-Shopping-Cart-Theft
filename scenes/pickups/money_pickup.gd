class_name MoneyPickup
extends Area2D

## PLACEHOLDER docs/08-09: moneda = maíz.
## Area2D en capa 6 ("Pickups"); al contacto suma vía
## GameManager.add_money(value) de forma defensiva y se libera.
## Bob senoidal placeholder para visibilidad.

signal collected(amount: int)

## Valor en maíz de este pickup.
@export var value: int = 1

var _t: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 1 << 5 # capa 6
	collision_mask = 1 << 1 # detecta capa 2 (Player)
	_base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 3.0) * 2.0

func _on_body_entered(_body: Node2D) -> void:
	collected.emit(value)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("add_money"):
		gm.add_money(value)
	else:
		push_warning("MoneyPickup: GameManager.add_money no disponible; maíz '%d' solo emitido." % value)
	queue_free()
