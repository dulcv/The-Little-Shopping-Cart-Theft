class_name DonCreston
extends CharacterBody2D
## JEFE FINAL — Don Crestón, el capo de los Gallos Negros.
##
## DEBILIDAD: su armadura de plumas de oro lo hace inmune a balas y picotazos.
## Pero es tan orgulloso que embiste a lo loco. Si choca contra una pared o
## pilar queda ATURDIDO (armadura abierta) y recibe el doble de daño.
## En la fase 2 (≤50% vida) después de cada aturdimiento se pone a cacarear
## y lanza granos de maíz en círculo: también es vulnerable mientras canta.
##
## Ciclo: PERSEGUIR -> AVISO (parpadea, fija dirección) -> EMBESTIDA
##        -> choca pared: ATURDIDO -> (fase 2: CACAREO) -> PERSEGUIR
##        -> choca jugador / falla: PERSEGUIR

signal health_changed(current: int, maximum: int)
signal died(who: Node2D, killer: Node)
signal fase_cambiada(fase: int)
## Para el HUD: "¡TINK!" cuando pega a la armadura, "¡AHORA!" cuando es vulnerable.
signal aviso(texto: String)

enum Estado { PERSEGUIR, AVISO, EMBESTIDA, ATURDIDO, CACAREO, MUERTO }

const BULLET_SCENE := preload("res://scenes/weapons/bullet.tscn")

@export var max_hp: int = 300
@export var walk_speed: float = 45.0
@export var charge_speed: float = 240.0
@export var contact_damage: int = 20
@export var stun_time: float = 2.5
@export var multiplicador_debilidad: int = 2
## Daño máximo por cada vez que se aturde (fracción de la vida total).
## Así ninguna arma lo mata en un solo aturdimiento: hay que estrellarlo
## al menos 4 veces (más en la fase 2 si fallas tiros).
@export_range(0.05, 1.0) var dano_max_por_aturdimiento: float = 0.25
## Si no hay nodo en el grupo "player", se usa esta ruta.
@export var target_path: NodePath

var hp: int
var fase: int = 1
var estado: Estado = Estado.PERSEGUIR
var _timer: float = 0.0
var _charge_dir: Vector2 = Vector2.RIGHT
var _target: Node2D = null
var _dano_ventana: int = 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const COLOR_ARMADURA := Color(1.0, 0.82, 0.25)
const COLOR_VULNERABLE := Color(1.0, 0.45, 0.45)

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	hp = max_hp
	Accesorio.poner(sprite, "sombrero_oro", Vector2(3, -8))
	Accesorio.poner(sprite, "cadena_oro", Vector2(5, 2), true)
	_target = get_tree().get_first_node_in_group("player") as Node2D
	if _target == null and not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node2D
	_cambiar_estado(Estado.PERSEGUIR)
	health_changed.emit.call_deferred(hp, max_hp)

func _physics_process(delta: float) -> void:
	_timer -= delta
	match estado:
		Estado.PERSEGUIR:
			_perseguir()
		Estado.AVISO:
			velocity = Vector2.ZERO
			# Parpadeo: la pista visual para que el jugador se aparte.
			sprite.visible = int(_timer * 20.0) % 2 == 0
			if _timer <= 0.0:
				sprite.visible = true
				_cambiar_estado(Estado.EMBESTIDA)
		Estado.EMBESTIDA:
			_embestir()
		Estado.ATURDIDO:
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			if _timer <= 0.0:
				_cambiar_estado(Estado.CACAREO if fase == 2 else Estado.PERSEGUIR)
		Estado.CACAREO:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_cambiar_estado(Estado.PERSEGUIR)
		Estado.MUERTO:
			velocity = Vector2.ZERO
	move_and_slide()

func _perseguir() -> void:
	if not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	var to := _target.global_position - global_position
	velocity = to.normalized() * walk_speed
	_mirar(to)
	if _timer <= 0.0:
		_cambiar_estado(Estado.AVISO)

func _embestir() -> void:
	velocity = _charge_dir * charge_speed * (1.25 if fase == 2 else 1.0)
	# Revisa contra qué choca tras el move_and_slide del frame anterior.
	for i in get_slide_collision_count():
		var col := get_slide_collision(i).get_collider()
		if col == _target:
			if col.has_method("take_damage"):
				col.take_damage(contact_damage)
			_cambiar_estado(Estado.PERSEGUIR)
			return
		# Cualquier otra cosa (pared, pilar, edificio) = ¡se descalabra!
		velocity = -_charge_dir * 60.0  # pequeño rebote
		_cambiar_estado(Estado.ATURDIDO)
		return
	if _timer <= 0.0:
		_cambiar_estado(Estado.PERSEGUIR)

func _cambiar_estado(nuevo: Estado) -> void:
	estado = nuevo
	sprite.visible = true
	match nuevo:
		Estado.PERSEGUIR:
			_timer = randf_range(1.5, 2.5) if fase == 1 else randf_range(0.8, 1.5)
			sprite.modulate = COLOR_ARMADURA
			sprite.play(&"walk")
		Estado.AVISO:
			_timer = 0.6 if fase == 1 else 0.4
			if is_instance_valid(_target):
				_charge_dir = (_target.global_position - global_position).normalized()
			sprite.play(&"idle")
		Estado.EMBESTIDA:
			_timer = 1.4
			sprite.play(&"run")
			_mirar(_charge_dir)
		Estado.ATURDIDO:
			_timer = stun_time
			_dano_ventana = 0
			sprite.modulate = COLOR_VULNERABLE
			sprite.play(&"idle")
			aviso.emit("¡AHORA! ¡Su armadura se abrió!")
		Estado.CACAREO:
			_timer = 1.2
			sprite.modulate = COLOR_VULNERABLE
			sprite.play(&"attack")
			_lluvia_de_maiz()
		Estado.MUERTO:
			sprite.modulate = Color(0.6, 0.6, 0.6)
			sprite.stop()

func es_vulnerable() -> bool:
	return estado == Estado.ATURDIDO or estado == Estado.CACAREO

## Contrato de daño (docs/09-contratos-interfaces.md).
func take_damage(amount: int) -> void:
	if estado == Estado.MUERTO:
		return
	if not es_vulnerable():
		aviso.emit("¡TINK! La armadura de oro lo protege")
		return
	var tope := int(max_hp * dano_max_por_aturdimiento)
	if _dano_ventana >= tope:
		aviso.emit("¡Se cubrió con las alas! Haz que se estrelle otra vez")
		return
	var dano: int = mini(amount * multiplicador_debilidad, tope - _dano_ventana)
	_dano_ventana += dano
	hp = max(hp - dano, 0)
	health_changed.emit(hp, max_hp)
	_flash()
	if fase == 1 and hp <= max_hp / 2:
		fase = 2
		fase_cambiada.emit(2)
		aviso.emit("Don Crestón está furioso: ¡FASE 2!")
	if hp == 0:
		_morir()

func heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)

func is_dead() -> bool:
	return estado == Estado.MUERTO

func _morir() -> void:
	_cambiar_estado(Estado.MUERTO)
	set_collision_layer_value(3, false)
	died.emit(self, _target)

## Fase 2: ráfaga de granos de maíz en 8 (luego 12) direcciones.
func _lluvia_de_maiz() -> void:
	var n := 12 if hp <= max_hp / 4 else 8
	var offset := randf() * TAU
	for i in n:
		var dir := Vector2.RIGHT.rotated(offset + TAU * i / n)
		var b := BULLET_SCENE.instantiate() as Bullet
		b.setup(dir, 110.0, 10, true, self)
		b.global_position = global_position + dir * 18.0
		b.modulate = Color(1, 0.9, 0.3)
		get_parent().add_child(b)

func _mirar(dir: Vector2) -> void:
	if absf(dir.x) > 0.1:
		sprite.flip_h = dir.x < 0.0

func _flash() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	tw.tween_property(sprite, "modulate", COLOR_VULNERABLE, 0.1)
