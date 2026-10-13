class_name WeaponPickup
extends Area2D

## PLACEHOLDER docs/08 (Fase 5 de sistema_armas.md:150).
## Area2D en capa 6 ("Pickups") con bob senoidal.
## Con E (interact) cerca: equipa pickup.data vía player.equip_weapon(data)
## y suelta el arma anterior como un nuevo WeaponPickup. Todo defensivo.

signal collected(weapon_id: String)

## Arma que entrega este pickup al equiparse.
@export var data: WeaponData

var _player_in_range: Node2D = null
var _t: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 1 << 5 # capa 6
	collision_mask = 1 << 1 # detecta capa 2 (Player)
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_sprite()

func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 3.0) * 2.0
	if is_instance_valid(_player_in_range) and Input.is_action_just_pressed("interact"):
		_try_equip(_player_in_range)

func _on_body_entered(body: Node2D) -> void:
	_player_in_range = body

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null

func _try_equip(player: Node2D) -> void:
	if data == null:
		push_warning("WeaponPickup sin WeaponData asignada.")
		return
	if not player.has_method("equip_weapon"):
		push_warning("WeaponPickup: el cuerpo no tiene equip_weapon.")
		return
	var prev: WeaponData = null
	if player.has_method("unequip_weapon"):
		prev = player.call("unequip_weapon") as WeaponData
	player.call("equip_weapon", data)
	collected.emit(data.id)
	if prev != null:
		_spawn_pickup_with(prev)
	queue_free()

## Suelta el arma anterior como un nuevo pickup en este punto.
func _spawn_pickup_with(weapon_data: WeaponData) -> void:
	var scene := load("res://scenes/weapons/weapon_pickup.tscn") as PackedScene
	if scene == null:
		return
	var parent := get_parent()
	if parent == null:
		return
	var pickup := scene.instantiate() as Area2D
	if pickup == null:
		return
	pickup.set("data", weapon_data)
	parent.add_child(pickup)
	pickup.global_position = global_position

## Muestra el sprite del arma si hay WeaponData asignada (placeholder).
func _update_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	if data != null and data.sprite != null:
		sprite.texture = data.sprite
