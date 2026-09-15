extends CharacterBody2D

const SPEED = 100.0 # Velocidad de paso deseada
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

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_attacking: bool = false
var is_running: bool = false
var active_run_dir: String = ""
var last_pressed_dir: String = ""
var last_dir_press_time: float = -1.0

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)

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

func _physics_process(_delta: float) -> void:
	# Iniciar ataque con Espacio (solo si no está atacando ya)
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		is_running = false
		active_run_dir = ""
		velocity = Vector2.ZERO
		animated_sprite.play("attack")
		move_and_slide()
		return

	# Mientras ataca, el personaje no se mueve ni cambia de animación
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

	var direction := Vector2(input_x, input_y)
	if direction != Vector2.ZERO:
		direction = direction.normalized()

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
