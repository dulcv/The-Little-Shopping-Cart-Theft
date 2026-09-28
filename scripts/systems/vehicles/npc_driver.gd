class_name NPCDriver
extends CharacterBody2D

## Conductor NPC de ejemplo para Vehicles.
## - A pie: camina hacia el coche libre más cercano y lo ocupa.
## - Conduciendo: implementa get_drive_input() persiguiendo waypoints.
## Sirve como plantilla para guardia_corral / bandas.

@export var walk_speed: float = 60.0
@export var waypoints: Array[Vector2] = []
var current_vehicle: Vehicle = null
var wp_index: int = 0

func _physics_process(_delta: float) -> void:
	if current_vehicle != null:
		if is_instance_valid(current_vehicle):
			global_position = current_vehicle.global_position
			velocity = Vector2.ZERO
			move_and_slide()
		else:
			current_vehicle = null
		return
	# A pie: buscar coche libre y entrar al contacto
	var target := _nearest_free_vehicle()
	if target:
		var to: Vector2 = target.global_position - global_position
		if to.length() < 30.0:
			target.enter(self)
			return
		velocity = to.normalized() * walk_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

## Interfaz que lee Vehicle: x = giro, y = acelerador
func get_drive_input() -> Vector2:
	if current_vehicle == null or waypoints.is_empty():
		# Sin ruta: circula en óvalo para demo
		return Vector2(0.5, 0.6)
	var target: Vector2 = waypoints[wp_index]
	var to_local: Vector2 = target - current_vehicle.global_position
	if to_local.length() < 24.0:
		wp_index = (wp_index + 1) % waypoints.size()
		return Vector2.ZERO
	var fwd := Vector2.RIGHT.rotated(current_vehicle.rotation)
	var angle := fwd.angle_to(to_local.normalized())
	return Vector2(clampf(angle * 2.0, -1.0, 1.0), 1.0 if absf(angle) < 2.2 else 0.3)

func on_enter_vehicle(vehicle: Vehicle) -> void:
	current_vehicle = vehicle
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)

func on_exit_vehicle(pos: Vector2) -> void:
	global_position = pos
	current_vehicle = null
	visible = true
	$CollisionShape2D.set_deferred("disabled", false)

func take_damage(_amount: int) -> void:
	pass

func _nearest_free_vehicle() -> Vehicle:
	var best: Vehicle = null
	var best_d := 1e20
	for n in get_tree().get_nodes_in_group("vehicles"):
		if n is Vehicle and (n as Vehicle).can_be_entered():
			var d: float = global_position.distance_squared_to((n as Node2D).global_position)
			if d < best_d:
				best_d = d
				best = n
	return best
