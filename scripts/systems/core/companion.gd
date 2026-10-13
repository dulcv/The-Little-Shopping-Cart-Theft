class_name Companion
extends CharacterBody2D

## Companera IA del modo Duo Edgar+Dulce (biblia-minima v1).
## STUB: sigue al jugador (FOLLOW), revive en 5s y hackea libretas (ledger)
## con E en 3s. Sin dialogos finales: todo texto usa PLACEHOLDER.
## No toca shaders, Centro, evidencias, wanted ni UI.
## Contrato de dano/salud segun docs/09-contratos-interfaces.md.

signal health_changed(current: int, maximum: int)
signal died(who: Node2D, killer: Node)
signal downed(companion: Companion)
signal revive_started(companion: Companion)
signal revived(companion: Companion)
signal hack_started(companion: Companion)
signal hack_finished(companion: Companion, ledger: Node)

enum State { FOLLOW, HACKING, DOWN, REVIVING }

## Unica linea de "voz" del stub. Dialogos reales pendientes.
const RADIO_PLACEHOLDER: String = "PLACEHOLDER"

@export var character: CharacterData
@export var follow_distance: float = 48.0
@export var move_speed: float = 110.0
## Biblia: si uno cae, el otro lo levanta en 5s.
@export var revive_time: float = 5.0
## Biblia: hackeo de libretas auto en 3s en v1.
@export var hack_time: float = 3.0

var target: Node2D
var state: State = State.FOLLOW
var current_hp: int = 100
var _revive_t: float = 0.0
var _hack_t: float = 0.0
var _hack_target: Node = null


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("npcs")
	if character:
		current_hp = character.max_hp


func _physics_process(delta: float) -> void:
	match state:
		State.FOLLOW:
			_follow(delta)
		State.HACKING:
			_tick_hack(delta)
		State.REVIVING:
			_tick_revive(delta)
		State.DOWN:
			velocity = Vector2.ZERO
			move_and_slide()
	_update_anim()


func _follow(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var to: Vector2 = target.global_position - global_position
	if to.length() > follow_distance:
		velocity = to.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()


## Revivir: lo inicia el otro miembro del duo junto al caido.
func try_start_revive(by: Node) -> bool:
	if state != State.DOWN or by == null:
		return false
	state = State.REVIVING
	_revive_t = 0.0
	revive_started.emit(self)
	return true


func _tick_revive(delta: float) -> void:
	_revive_t += delta
	if _revive_t >= revive_time:
		state = State.FOLLOW
		heal(current_max_hp())
		revived.emit(self)


## Hackeo: lo dispara el sistema duo cuando el jugador pulsa E junto a un ledger.
func try_start_hack(ledger: Node) -> bool:
	if state != State.FOLLOW or ledger == null:
		return false
	state = State.HACKING
	_hack_target = ledger
	_hack_t = 0.0
	hack_started.emit(self)
	return true


func cancel_hack() -> void:
	if state == State.HACKING:
		state = State.FOLLOW
		_hack_target = null


func _tick_hack(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_hack_t += delta
	if _hack_t >= hack_time:
		state = State.FOLLOW
		hack_finished.emit(self, _hack_target)
		_hack_target = null


func current_max_hp() -> int:
	return character.max_hp if character else 100


func take_damage(amount: int) -> void:
	if state == State.DOWN:
		return
	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, current_max_hp())
	cancel_hack()
	if current_hp <= 0:
		state = State.DOWN
		downed.emit(self)
		died.emit(self, null)


func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, current_max_hp())
	health_changed.emit(current_hp, current_max_hp())
	if state == State.DOWN and current_hp > 0:
		state = State.FOLLOW


func is_dead() -> bool:
	return state == State.DOWN


func _update_anim() -> void:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return
	var want := &"idle"
	if state == State.DOWN:
		want = &"die"
	elif velocity.length() > 1.0:
		want = &"walk"
	if sprite.sprite_frames.has_animation(want) and sprite.animation != want:
		sprite.play(want)
