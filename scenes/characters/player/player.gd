extends CharacterBody2D

const SPEED = 100.0 # Velocidad de paso
const RUN_SPEED = 150.0 # Velocidad aumentada al correr
const DOUBLE_TAP_TIME = 0.3 # Tiempo máximo (segundos) entre toques para activar carrera

const DIRECTION_KEYS := {    
	KEY_W: "up",
	KEY_UP: "up",
	KEY_S: "down",
	KEY_DOWN: "down",
	KEY_A: "left",
	KEY_LEFT: "left",
	KEY_D: "right",
	KEY_RIGHT: "right",
}

## Balanceo vertical del cuerpo dibujado dentro de cada frame del sprite
## (medido del arte: el pollo baja/sube 1 px según el frame). El arma suma
## este mismo desplazamiento para no parecer flotante.
## Clave = nombre de animación, valor = offset Y por frame.
const BODY_BOB := {
	&"idle": [0, 0, 1, 1, 1],
	&"walk": [0, -1, -1, 0],
	&"run": [0, -1, -1, 0],
}

@export_group("Equipamiento")
## Arma inicial equipada al iniciar la escena (opcional)
@export var starting_weapon: WeaponData

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon: Weapon = $Weapon
@onready var melee_sound: AudioStreamPlayer2D = $MeleeSound

var is_attacking: bool = false
var is_running: bool = false
var active_run_dir: String = ""
var last_pressed_dir: String = ""
var last_dir_press_time: float = -1.0
var last_facing_dir: Vector2 = Vector2.RIGHT
## Anclaje base del arma según la dirección (sin balanceo de animación).
## `_apply_weapon_bob()` le suma el BODY_BOB del frame actual cada tick.
var _weapon_base_pos: Vector2 = Vector2(6, 2)

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	if weapon:
		weapon.set_aim_direction(last_facing_dir)
		_update_weapon_visual_depth()
		if starting_weapon:
			equip_weapon(starting_weapon)

func _unhandled_input(event: InputEvent) -> void:
	# Detectar doble toque en cualquier dirección (WASD o flechas)
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if DIRECTION_KEYS.has(key):
			var dir: String = DIRECTION_KEYS[key]
			var current_time := Time.get_ticks_msec() / 1000.0
			if dir == last_pressed_dir and (current_time - last_dir_press_time) <= DOUBLE_TAP_TIME:
				is_running = true
				active_run_dir = dir
				last_pressed_dir = ""
			else:
				last_pressed_dir = dir
				last_dir_press_time = current_time
		
		# Teclas rápidas de prueba (1: Pistola, 2: Rifle, 3: Ametralladora, 0: Desarmar)
		match key:
			KEY_1:
				equip_weapon(load("res://resources/weapons/pistol.tres"))
			KEY_2:
				equip_weapon(load("res://resources/weapons/assault_rifle.tres"))
			KEY_3:
				equip_weapon(load("res://resources/weapons/machine_gun.tres"))
			KEY_0:
				unequip_weapon()


func _physics_process(_delta: float) -> void:
	# Gestión de combate unificada con tecla de ataque (Espacio):
	# - Con arma: dispara proyectiles
	# - Sin arma: ejecuta ataque cuerpo a cuerpo
	if has_weapon():
		var trigger_pressed := Input.is_action_pressed("attack") or Input.is_action_pressed("shoot")
		var trigger_just_pressed := Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("shoot")
		if trigger_pressed or trigger_just_pressed:
			weapon.handle_trigger(trigger_pressed, trigger_just_pressed)
	else:
		if Input.is_action_just_pressed("attack") and not is_attacking:
			is_attacking = true
			is_running = false
			active_run_dir = ""
			velocity = Vector2.ZERO
			animated_sprite.play("attack")
			_play_melee_sound()
			move_and_slide()
			return

	# Mientras realiza ataque cuerpo a cuerpo, el personaje no se mueve
	if is_attacking:
		move_and_slide()
		return

	# Captura movimiento tanto por flechas (ui_*) como por WASD
	var input_x := Input.get_axis("ui_left", "ui_right")
	var input_y := Input.get_axis("ui_up", "ui_down")

	if Input.is_key_pressed(KEY_A):
		input_x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_y += 1.0

	var raw_direction := Vector2(input_x, input_y)
	# Movimiento restringido a 4 direcciones: si se pulsan dos ejes a la vez
	# (diagonal), se conserva solo el eje dominante. En empate gana el
	# horizontal para un comportamiento predecible.
	var direction := Vector2.ZERO
	if raw_direction != Vector2.ZERO:
		if absf(raw_direction.x) >= absf(raw_direction.y):
			direction = Vector2(signf(raw_direction.x), 0.0)
		else:
			direction = Vector2(0.0, signf(raw_direction.y))
	if direction != Vector2.ZERO:
		last_facing_dir = direction
		if weapon:
			weapon.set_aim_direction(last_facing_dir)
			_update_weapon_visual_depth()

	# Si está corriendo pero suelta la tecla de la dirección activa o se detiene, desactiva la carrera
	if is_running and (not _is_dir_pressed(active_run_dir) or direction == Vector2.ZERO):
		is_running = false
		active_run_dir = ""

	if direction:
		if is_running:
			velocity = direction * RUN_SPEED
			animated_sprite.play("run")
		else:
			velocity = direction * SPEED
			animated_sprite.play("walk")

		# Voltea el sprite horizontalmente según la dirección
		if direction.x != 0.0:
			animated_sprite.flip_h = direction.x < 0.0
	else:
		# Detiene al personaje inmediatamente al soltar los controles
		velocity = Vector2.ZERO
		is_running = false
		active_run_dir = ""
		animated_sprite.play("idle")

	move_and_slide()

func _is_dir_pressed(dir: String) -> bool:
	match dir:
		"up":
			return Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up")
		"down":
			return Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down")
		"left":
			return Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left")
		"right":
			return Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right")
	return false

func _on_animation_finished() -> void:
	if animated_sprite.animation == &"attack":
		is_attacking = false

## Ajusta la profundidad visual (Z-index / behind parent) y el anclaje del arma según la dirección.
## El pollo mide ~20x21 px (vista lateral, pico a la derecha, ala en X=±6).
## El agarre lateral va a Y≈2 (pecho/ala, por debajo del pico y la barbilla)
## para que el cañón no tape la cara; arriba Y≈-3 (detrás de la cabeza),
## abajo Y≈3 (por delante del cuerpo).
## El origen del nodo Weapon es el punto de agarre (empuñadura/gatillo del
## arma, NO la culata trasera): cada arma define su agarre con hold_offset
## según su tamaño, así la culata larga de los rifles queda apoyada dentro
## del ala y la pistola corta apenas solapa el borde.
func _update_weapon_visual_depth() -> void:
	if not weapon:
		return

	# Al mirar hacia arriba, el arma se dibuja detrás de la cabeza del pollo
	if last_facing_dir.y < -0.4:
		weapon.show_behind_parent = true
	else:
		weapon.show_behind_parent = false

	# Anclaje por dirección alrededor del cuerpo para que el agarre
	# quede sobre el ala correspondiente y no flotando fuera del sprite.
	# (El movimiento es de 4 direcciones, pero se conservan las ramas
	# diagonales por si alguna otra entidad reutiliza esta lógica.)
	var pos := Vector2.ZERO
	if last_facing_dir.x > 0.4:
		pos.x = 6.0
	elif last_facing_dir.x < -0.4:
		pos.x = -6.0
	else:
		pos.x = 0.0

	if last_facing_dir.y < -0.4:
		pos.y = -3.0
	elif last_facing_dir.y > 0.4:
		pos.y = 3.0
	else:
		pos.y = 2.0

	_weapon_base_pos = pos
	_apply_weapon_bob()

## Suma al arma el balanceo vertical del frame actual del sprite para que
## acompañe al cuerpo (idle/walk/run) en vez de quedar flotando en un punto fijo.
func _apply_weapon_bob() -> void:
	if not weapon or not animated_sprite:
		return
	var bob_y := 0
	var table: Array = BODY_BOB.get(animated_sprite.animation, [])
	if not table.is_empty():
		bob_y = table[animated_sprite.frame % table.size()]
	weapon.position = _weapon_base_pos + Vector2(0, bob_y)

func _process(_delta: float) -> void:
	# El cuerpo se balancea dentro del propio sprite (1 px según el frame)
	# también en idle, cuando no hay cambio de dirección que recoloque el arma.
	if has_weapon():
		_apply_weapon_bob()

## Equipa un arma en el componente Weapon del personaje
func equip_weapon(data: WeaponData) -> void:
	if weapon:
		weapon.equip_weapon(data)
		_update_weapon_visual_depth()

## Desequipa el arma actual y la retorna
func unequip_weapon() -> WeaponData:
	if weapon:
		return weapon.unequip_weapon()
	return null

## Comprueba si el personaje tiene un arma lista para disparar
func has_weapon() -> bool:
	return weapon != null and weapon.weapon_data != null

## Reproduce el sonido del golpe cuerpo a cuerpo (hit.mp3).
func _play_melee_sound() -> void:
	if melee_sound == null:
		return
	melee_sound.pitch_scale = randf_range(0.96, 1.04)
	melee_sound.play()

## Receptor de daño para proyectiles y ataques
func take_damage(_amount: int) -> void:
	# Hook para sistema de salud y animaciones de impacto (Fase 6)
	pass
