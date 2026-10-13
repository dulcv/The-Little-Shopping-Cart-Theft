extends Node2D
## Spawner placeholder de peds + tráfico (doc 05).
## Pool: máx 10 peds + 4 coches en radio 300px del player.
## Respawnea en Spawns/PedSpawns/* y Spawns/CarSpawns/* de Centro.
## Usa pick_random_paint() + apply_variant(). Todo diálogo = PLACEHOLDER.

const NPC_SCENE: PackedScene = preload("res://scenes/characters/npc/npc.tscn")

const MAX_PEDS := 10
const MAX_CARS := 4
const ACTIVE_RADIUS := 300.0
const RESPAWN_SECONDS := 5.0

@export var variant_pool: Array[NPCVariant] = []
@export var car_scene: PackedScene = null  # PLACEHOLDER: asignar coche de tráfico en editor

var _ped_spawns: Array[Marker2D] = []
var _car_spawns: Array[Marker2D] = []
var _peds: Array[Node2D] = []
var _cars: Array[Node2D] = []
var _timer: float = 0.0
var _player: Node2D = null

func _ready() -> void:
	add_to_group("npc_spawner")
	_collect_spawns()
	_player = _find_player()
	# PLACEHOLDER: si no hay variantes asignadas, intenta cargar las 5 de npc_data.
	if variant_pool.is_empty():
		for id in ["civil", "gallo_negro", "guardia", "policia", "campesino"]:
			var v := load("res://resources/npc_data/%s.tres" % id) as NPCVariant
			if v:
				variant_pool.append(v)

func _collect_spawns() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	# Centro cuelga de EscenaPrincipal: búsqueda recursiva (no ruta fija).
	var ped_node := root.find_child("PedSpawns", true, false)
	var car_node := root.find_child("CarSpawns", true, false)
	if ped_node:
		for c in ped_node.get_children():
			if c is Marker2D:
				_ped_spawns.append(c)
	if car_node:
		for c in car_node.get_children():
			if c is Marker2D:
				_car_spawns.append(c)

func _process(delta: float) -> void:
	_timer -= delta
	_prune()
	if _timer > 0.0:
		return
	_timer = RESPAWN_SECONDS
	_player = _find_player()
	_maintain_peds()
	_maintain_cars()

func _find_player() -> Node2D:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p:
		return p
	p = get_tree().get_first_node_in_group("Player") as Node2D
	if p:
		return p
	var root := get_tree().current_scene
	if root:
		var n := root.find_child("Player", true, false) as Node2D
		if n:
			return n
	return null

func _prune() -> void:
	_peds.assign(_peds.filter(func(n): return is_instance_valid(n)))
	_cars.assign(_cars.filter(func(n): return is_instance_valid(n)))

func _maintain_peds() -> void:
	# Libera peds lejos del player (radio 300px * 2) para mantener el pool.
	for p in _peds.duplicate():
		if _player and p.global_position.distance_to(_player.global_position) > ACTIVE_RADIUS * 3.0:
			p.queue_free()
	_prune()
	var want := mini(MAX_PEDS, 8)  # arranque: 8 NPCs caminando (aceptación doc 05)
	while _peds.size() < want and not _ped_spawns.is_empty():
		spawn_ped(_random_ped_spawn_pos())

func _maintain_cars() -> void:
	if car_scene == null or _car_spawns.is_empty():
		return  # PLACEHOLDER: sin escena de coche asignada no hay tráfico
	for c in _cars.duplicate():
		if _player and c.global_position.distance_to(_player.global_position) > ACTIVE_RADIUS * 3.0:
			c.queue_free()
	_prune()
	while _cars.size() < mini(MAX_CARS, 2) and not _car_spawns.is_empty():
		spawn_car(_random_car_spawn_pos())

func _random_ped_spawn_pos() -> Vector2:
	var m: Marker2D = _ped_spawns[randi() % _ped_spawns.size()]
	if _player and m.global_position.distance_to(_player.global_position) > ACTIVE_RADIUS * 2.0:
		# Prefiere spawns cercanos al player; si el aleatorio queda lejos, usa el más cercano.
		var best: Marker2D = m
		for s in _ped_spawns:
			if s.global_position.distance_to(_player.global_position) < best.global_position.distance_to(_player.global_position):
				best = s
		m = best
	return m.global_position

func _random_car_spawn_pos() -> Vector2:
	var m: Marker2D = _car_spawns[randi() % _car_spawns.size()]
	return m.global_position

func spawn_ped(pos: Vector2) -> Node2D:
	var npc := NPC_SCENE.instantiate() as Node2D
	get_tree().current_scene.add_child(npc)
	npc.global_position = pos
	if not variant_pool.is_empty() and npc.has_method("apply_variant"):
		var v: NPCVariant = variant_pool[randi() % variant_pool.size()]
		npc.call("apply_variant", v)
		if "faction" in npc:
			npc.set("faction", _faction_for_variant(v))
	_peds.append(npc)
	if npc.has_method("set_wander_target") and not _ped_spawns.is_empty():
		var dest: Marker2D = _ped_spawns[randi() % _ped_spawns.size()]
		npc.call("set_wander_target", dest.global_position)
	return npc

func spawn_car(pos: Vector2) -> Node2D:
	if car_scene == null:
		return null
	var car := car_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(car)
	car.global_position = pos
	if car.has_method("pick_random_paint") and car.has_method("set_paint_color"):
		car.call("set_paint_color", car.call("pick_random_paint"))
	_cars.append(car)
	# PLACEHOLDER_conductor: genera un ped que intentará entrar al coche.
	if not _ped_spawns.is_empty() and car.has_method("enter"):
		var driver := spawn_ped(pos + Vector2(24, 0))
		if driver and driver.has_method("drive_to_car"):
			driver.call("drive_to_car", car)
	return car

func _faction_for_variant(v: NPCVariant) -> String:
	match v.id:
		"gallo_negro", "gallos_negros":
			return "gallos_negros"
		"guardia":
			return "guardia_corral"
		"policia":
			return "policia"
	return "civil"
