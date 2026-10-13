extends CharacterBody2D
## NPC base: reutiliza los sprites del pollo (player1_sprite_frames.tres, NO duplicar).
## Cada instancia crea su propio ShaderMaterial en _ready() para no compartir
## parámetros del shader entre NPCs. Ver docs/02-shader-pollos.md.

const VARIANT_SHADER: Shader = preload("res://assets/shaders/chicken_variant.gdshader")

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
	_mat.set_shader_parameter("spot_color", v.spot_color)
	_mat.set_shader_parameter("spot_amount", v.spot_amount)

func set_variant(v: NPCVariant) -> void:
	apply_variant(v)

func take_damage(amount: int) -> void:
	if is_dead():
		return
	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, variant.max_hp if variant else 30)
	if current_hp <= 0:
		died.emit(self, null)

func heal(amount: int) -> void:
	var max_hp := variant.max_hp if variant else 30
	current_hp = mini(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)

func is_dead() -> bool:
	return current_hp <= 0
