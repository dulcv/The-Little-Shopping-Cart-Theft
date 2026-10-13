extends CharacterBody2D
## NPC base: reutiliza los sprites del pollo (player1_sprite_frames.tres, NO duplicar).
## Cada instancia crea su propio ShaderMaterial en _ready() para no compartir
## parámetros del shader entre NPCs. Ver docs/02-shader-pollos.md.

const VARIANT_SHADER: Shader = preload("res://assets/shaders/chicken_variant.gdshader")
## PLACEHOLDER docs/08: escena de maíz (carga perezosa: el archivo lo crea el Agente-Salud).

signal health_changed(current: int, maximum: int)
signal died(who: Node2D, killer: Node)

@export var variant: NPCVariant

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_hp: int = 30
var _mat: ShaderMaterial

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("npcs")
	# Material único por instancia (no compartido entre NPCs).
	_mat = ShaderMaterial.new()
	_mat.shader = VARIANT_SHADER
	animated_sprite.material = _mat
	if variant:
		apply_variant(variant)
	elif _mat:
		# Valores por defecto = pollo blanco base.
		_mat.set_shader_parameter("plume_color", Color.WHITE)
	_npc_ai_ready()

func _physics_process(delta: float) -> void:
	_npc_ai_physics(delta)

func apply_variant(v: NPCVariant) -> void:
	variant = v
	current_hp = v.max_hp
	scale = Vector2.ONE * v.scale_mult
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = VARIANT_SHADER
		if is_node_ready():
			animated_sprite.material = _mat
	_mat.set_shader_parameter("plume_color", v.plume_color)
	_mat.set_shader_parameter("plume_amount", 1.0)

func set_variant(v: NPCVariant) -> void:
	apply_variant(v)

func take_damage(amount: int) -> void:
	if is_dead():
		return
	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, variant.max_hp if variant else 30)
	if current_hp <= 0:
		die(null)

func heal(amount: int) -> void:
	var max_hp := variant.max_hp if variant else 30
	current_hp = mini(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)

func is_dead() -> bool:
	return current_hp <= 0


# ------------------------------------------------------------------
# IA placeholder Centro (docs/05-ia-npcs-centro.md). Todo diálogo = PLACEHOLDER.
# Estados: IDLE/WANDER/FLEE/CHASE/ATTACK/ENTER_CAR/DRIVE/WITNESS/DEAD.
# ------------------------------------------------------------------
enum NPCState { IDLE, WANDER, FLEE, CHASE, ATTACK, ENTER_CAR, DRIVE, WITNESS, DEAD }

const WALK_SPEED := 100.0
const FLEE_SPEED_MULT := 1.6
const PERCEPTION_RADIUS := 120.0
const ATTACK_RANGE := 28.0
const ATTACK_DAMAGE := 10
const ATTACK_COOLDOWN := 1.0

@export var faction: String = "civil"
@export var display_name: String = "PLACEHOLDER_npc"
@export var dialogue_id: String = "PLACEHOLDER_saludo"

var state: NPCState = NPCState.IDLE
var speed_mult: float = 1.0
var target_body: Node2D = null
var wander_target: Vector2 = Vector2.ZERO
var current_vehicle: Node2D = null
var _state_time: float = 0.0
var _attack_cd: float = 0.0
var _dead_timer: float = 0.0

var _nav: NavigationAgent2D = null
var _perception: Area2D = null

func _npc_ai_ready() -> void:
	add_to_group("enemies")
	if faction == "policia":
		add_to_group("police")
	_nav = get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	_ensure_perception()
	if variant:
		speed_mult = variant.speed_mult
	_state_time = randf() * 2.0
	_enter_state(NPCState.IDLE)

func _ensure_perception() -> void:
	_perception = get_node_or_null("Perception") as Area2D
	if _perception != null:
		_connect_perception()
		return
	# NavigationAgent2D opcional: se crea solo si falta Perception para no
	# tocar npc.tscn en este commit (el bake real de NavigationRegion2D es Fase 6).
	_perception = Area2D.new()
	_perception.name = "Perception"
	_perception.collision_layer = 0
	_perception.collision_mask = 1 + 2 + 4  # player + vehículos/peds
	_perception.monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PERCEPTION_RADIUS
	shape.shape = circle
	_perception.add_child(shape)
	add_child(_perception)
	_connect_perception()

func _connect_perception() -> void:
	if not _perception.body_entered.is_connected(_on_perception_body_entered):
		_perception.body_entered.connect(_on_perception_body_entered)

func _npc_ai_physics(delta: float) -> void:
	if state == NPCState.DEAD:
		_dead_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if _dead_timer <= 0.0:
			queue_free()  # cadáver 10s placeholder
		return
	_state_time -= delta
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	match state:
		NPCState.IDLE:
			velocity = Vector2.ZERO
			_play_4dir(Vector2.ZERO, false)
			if _state_time <= 0.0:
				_pick_wander_target()
				_enter_state(NPCState.WANDER)
		NPCState.WANDER:
			_move_toward_point(wander_target, WALK_SPEED * speed_mult, delta)
			if _reached(wander_target, 8.0) or _state_time <= 0.0:
				_enter_state(NPCState.IDLE)
		NPCState.FLEE:
			var away := _flee_dir()
			_move_dir(away, WALK_SPEED * FLEE_SPEED_MULT * speed_mult)
			if _state_time <= 0.0:
				_enter_state(NPCState.IDLE)
		NPCState.CHASE:
			if not is_instance_valid(target_body):
				_enter_state(NPCState.IDLE)
				return
			var to: Vector2 = target_body.global_position - global_position
			if to.length() <= ATTACK_RANGE:
				_enter_state(NPCState.ATTACK)
				return
			_move_dir(to.normalized(), WALK_SPEED * speed_mult)
		NPCState.ATTACK:
			if not is_instance_valid(target_body):
				_enter_state(NPCState.IDLE)
				return
			var d: Vector2 = target_body.global_position - global_position
			if d.length() > ATTACK_RANGE * 1.5:
				_enter_state(NPCState.CHASE)
				return
			velocity = Vector2.ZERO
			_play_4dir(d.normalized(), false)
			_face(d.normalized())
			if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("attack"):
				if animated_sprite.animation != "attack":
					animated_sprite.play("attack")
			if _attack_cd <= 0.0:
				_attack_cd = ATTACK_COOLDOWN
				if target_body.has_method("take_damage"):
					target_body.take_damage(ATTACK_DAMAGE)
			move_and_slide()
			return
		NPCState.WITNESS:
			# PLACEHOLDER: mira al crimen, luego huye y reporta 1 huevo.
			velocity = Vector2.ZERO
			if is_instance_valid(target_body):
				_face((target_body.global_position - global_position).normalized())
			_play_4dir(Vector2.ZERO, false)
			if _state_time <= 0.0:
				_enter_state(NPCState.FLEE)
		NPCState.ENTER_CAR:
			if not is_instance_valid(target_body):
				_enter_state(NPCState.IDLE)
				return
			_move_toward_point(target_body.global_position, WALK_SPEED * speed_mult, delta)
			if global_position.distance_to(target_body.global_position) < 24.0:
				if target_body.has_method("enter") and target_body.call("enter", self, true):
					_enter_state(NPCState.DRIVE)
				else:
					_enter_state(NPCState.IDLE)
		NPCState.DRIVE:
			if not is_instance_valid(current_vehicle):
				current_vehicle = null
				_enter_state(NPCState.IDLE)
				return
			global_position = current_vehicle.global_position
			velocity = Vector2.ZERO
			move_and_slide()
			return
	move_and_slide()

func _enter_state(s: NPCState) -> void:
	state = s
	match s:
		NPCState.IDLE:
			_state_time = randf_range(1.0, 3.0)
		NPCState.WANDER:
			_state_time = randf_range(4.0, 8.0)
		NPCState.FLEE:
			_state_time = randf_range(2.0, 4.0)
			talk("PLACEHOLDER_grito_huida")
		NPCState.WITNESS:
			_state_time = 2.0
			talk("PLACEHOLDER_testigo_grito")
			_report_crime(1, "PLACEHOLDER_crimen_visto")
		NPCState.CHASE:
			talk("PLACEHOLDER_amenaza")

func _pick_wander_target() -> void:
	# PLACEHOLDER: punto aleatorio cercano; el spawner reasigna con PedSpawns
	# vía set_wander_target(). NavigationAgent2D se usa si existe bake.
	wander_target = global_position + Vector2(randf_range(-160, 160), randf_range(-160, 160))
	if _nav:
		_nav.target_position = wander_target

func set_wander_target(p: Vector2) -> void:
	wander_target = p
	if _nav:
		_nav.target_position = p
	if state == NPCState.IDLE:
		_enter_state(NPCState.WANDER)

func _move_toward_point(p: Vector2, speed: float, _delta: float) -> void:
	var dir := Vector2.ZERO
	if _nav and _nav.is_target_reachable():
		var next: Vector2 = _nav.get_next_path_position()
		dir = (next - global_position).normalized() if next.distance_to(global_position) > 2.0 else Vector2.ZERO
	else:
		var to: Vector2 = p - global_position
		dir = to.normalized() if to.length() > 4.0 else Vector2.ZERO
	_move_dir(dir, speed)

func _move_dir(dir: Vector2, speed: float) -> void:
	# Movimiento 4-dir como player.gd:171-180 (eje dominante, sin diagonales).
	var flat := Vector2.ZERO
	if dir != Vector2.ZERO:
		if absf(dir.x) >= absf(dir.y):
			flat = Vector2(signf(dir.x), 0.0)
		else:
			flat = Vector2(0.0, signf(dir.y))
	velocity = flat * speed
	_play_4dir(flat, speed > WALK_SPEED * 1.2)
	_face(flat)

func _reached(p: Vector2, dist: float) -> bool:
	return global_position.distance_to(p) <= dist

func _flee_dir() -> Vector2:
	if is_instance_valid(target_body):
		return (global_position - target_body.global_position).normalized()
	return Vector2.RIGHT.rotated(randf() * TAU)

func _face(dir: Vector2) -> void:
	if dir.x != 0.0:
		animated_sprite.flip_h = dir.x < 0.0
		animated_sprite.flip_v = false
	elif dir.y != 0.0:
		animated_sprite.flip_h = false
		animated_sprite.flip_v = false

## Anim 4-dir compatible con player (walk/walk_up/walk_down, idle/idle_up/idle_down).
func _play_4dir(dir: Vector2, running: bool) -> void:
	if animated_sprite.sprite_frames == null:
		return
	var prefix := "walk" if dir != Vector2.ZERO else "idle"
	if running:
		prefix = "run"
	var anim := StringName(prefix)
	if dir.y < 0.0:
		anim = StringName(prefix + "_up")
	elif dir.y > 0.0:
		anim = StringName(prefix + "_down")
	if not animated_sprite.sprite_frames.has_animation(anim):
		anim = StringName(prefix)
	if animated_sprite.sprite_frames.has_animation(anim) and animated_sprite.animation != anim:
		animated_sprite.play(anim)

# ------------------------------------------------------------------
# Reacciones (contrato doc 09: take_damage ya existía arriba; aquí IA).
# ------------------------------------------------------------------
func on_damaged(attacker: Node, amount: int) -> void:
	if is_dead():
		return
	take_damage(amount)
	if is_dead():
		return
	if current_hp <= int(float(variant.max_hp if variant else 30) * 0.3):
		target_body = attacker as Node2D
		_enter_state(NPCState.FLEE)
		return
	if attacker != null and NPCFactions.is_hostile_to(faction, _faction_of(attacker)):
		target_body = attacker as Node2D
		_enter_state(NPCState.CHASE)
	else:
		target_body = attacker as Node2D
		_enter_state(NPCState.FLEE)

## Llamado por RamArea del coche (vehicle.gd:408 speed>80): víctima huye,
## testigos cercanos entran en WITNESS (ellos reportan el huevo).
func on_run_over(car: Node) -> void:
	if is_dead():
		return
	target_body = car as Node2D
	take_damage(20)  # PLACEHOLDER_cantidad_atropello
	if is_dead():
		return
	_enter_state(NPCState.FLEE)
	_alert_witnesses(car)

func _alert_witnesses(crime_node: Node) -> void:
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc == self or not (npc is CharacterBody2D):
			continue
		if (npc as Node2D).global_position.distance_to(global_position) <= PERCEPTION_RADIUS:
			if npc.has_method("become_witness"):
				npc.call("become_witness", crime_node)

func become_witness(crime_node: Node) -> void:
	if is_dead() or state == NPCState.WITNESS:
		return
	target_body = crime_node as Node2D
	_enter_state(NPCState.WITNESS)

func die(killer: Node = null) -> void:
	if state == NPCState.DEAD:
		return
	_enter_state(NPCState.DEAD)
	state = NPCState.DEAD
	_dead_timer = 10.0  # cadáver 10s
	velocity = Vector2.ZERO
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.play("die")
	# PLACEHOLDER_drop_dinero: spawnea money_pickup con variant.money_min/max (doc 08).
	drop_money()
	_report_crime(2, "PLACEHOLDER_asesinato")
	died.emit(self, killer)

## PLACEHOLDER docs/08: suelta maíz (variant.money_min/max) como
## money_pickup. Todo defensivo: sin escena, sin padre o sin valor no rompe
## la IA. El aviso a la guardia (+2 huevos rotos) ya lo hace die() vía
## _report_crime; aquí se reintenta add_guardia por contrato doc 09.
func drop_money() -> void:
	var min_corn := 5
	var max_corn := 20
	if variant:
		min_corn = variant.money_min
		max_corn = variant.money_max
	var amount := randi_range(mini(min_corn, max_corn), maxi(min_corn, max_corn))
	if amount <= 0:
		return
	var parent := get_parent()
	if parent == null:
		return
	if not ResourceLoader.exists("res://scenes/pickups/money_pickup.tscn"):
		return
	var scene := load("res://scenes/pickups/money_pickup.tscn") as PackedScene
	if scene == null:
		return
	var pickup := scene.instantiate() as Area2D
	if pickup == null:
		return
	pickup.set("value", amount)
	parent.add_child(pickup)
	pickup.global_position = global_position

## Reporte defensivo: no rompe si WantedSystem aún no es Autoload.
func _report_crime(n: int, reason: String) -> void:
	var ws: Node = get_node_or_null("/root/WantedSystem")
	if ws and ws.has_method("add_heat"):
		ws.call("add_heat", n, reason)
	elif ws and ws.has_method("add_guardia"):
		ws.call("add_guardia", n, reason)

func _on_perception_body_entered(_body: Node2D) -> void:
	# PLACEHOLDER: disparos/crímenes cercanos -> WITNESS (doc 05).
	pass

func _faction_of(node: Node) -> String:
	if node != null and node.get("faction") != null:
		return str(node.get("faction"))
	if node != null and node.is_in_group("police"):
		return "policia"
	return "civil"

# ------------------------------------------------------------------
# Diálogo placeholder (doc 09: DialogueSystem.start_dialogue).
# ------------------------------------------------------------------
func talk(override_id: String = "") -> void:
	var id := override_id if override_id != "" else dialogue_id
	if id == "":
		id = "PLACEHOLDER_saludo"
	var ds: Node = get_node_or_null("/root/DialogueSystem")
	if ds and ds.has_method("start_dialogue"):
		ds.call("start_dialogue", id, display_name)
	# Sin DialogueSystem: PLACEHOLDER silencioso (ver StateLabel/debug).

# ------------------------------------------------------------------
# Conductor NPC (contrato doc 09 + vehicle.gd): persigue RoadPath.
# ------------------------------------------------------------------
var road_path: Path2D = null
var _road_progress: float = 0.0

func on_enter_vehicle(vehicle: Node2D) -> void:
	current_vehicle = vehicle
	visible = false
	set_physics_process(true)

func on_exit_vehicle(_vehicle: Node2D = null) -> void:
	current_vehicle = null
	visible = true
	if state == NPCState.DRIVE:
		_enter_state(NPCState.IDLE)

## x=steer, y=throttle. PLACEHOLDER: avanza por RoadPath si existe.
func get_drive_input() -> Vector2:
	return Vector2(0.0, 0.6)  # PLACEHOLDER_conduccion_recta

func drive_to_car(car: Node2D) -> void:
	target_body = car
	_enter_state(NPCState.ENTER_CAR)
