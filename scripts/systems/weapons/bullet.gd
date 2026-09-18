class_name Bullet
extends Area2D

## Script que controla el proyectil de las armas.
## Funciona tanto para el jugador como para NPCs/enemigos gracias a la configuración dinámica de capas de colisión.

@export var speed: float = 400.0
@export var damage: int = 10
@export var max_lifetime: float = 2.0
@export var is_enemy_bullet: bool = false

var direction: Vector2 = Vector2.RIGHT
var _lifetime_elapsed: float = 0.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Ajustar rotación inicial según la dirección
	if direction != Vector2.ZERO:
		rotation = direction.angle()
	
	_apply_collision_layers()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

## Inicializa las propiedades del proyectil desde el arma que lo dispara
func setup(p_direction: Vector2, p_speed: float, p_damage: int, p_is_enemy: bool = false) -> void:
	direction = p_direction.normalized()
	rotation = direction.angle()
	speed = p_speed
	damage = p_damage
	is_enemy_bullet = p_is_enemy
	_apply_collision_layers()

func _apply_collision_layers() -> void:
	# Capa 1: Mundo (bit 0 -> 1)
	# Capa 2: Player (bit 1 -> 2)
	# Capa 3: Enemigos (bit 2 -> 4)
	# Capa 4: Balas_Player (bit 3 -> 8)
	# Capa 5: Balas_Enemigos (bit 4 -> 16)
	if is_enemy_bullet:
		collision_layer = 1 << 4 # Balas_Enemigos
		collision_mask = (1 << 0) | (1 << 1) # Choca con Mundo y Player
	else:
		collision_layer = 1 << 3 # Balas_Player
		collision_mask = (1 << 0) | (1 << 2) # Choca con Mundo y Enemigos

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
	_lifetime_elapsed += delta
	if _lifetime_elapsed >= max_lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Aplica daño si el objetivo tiene la función take_damage
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Para compatibilidad con sistemas basados en Hurtbox
	if area.has_method("take_damage"):
		area.take_damage(damage)
	elif area.get_parent() and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)
	queue_free()
