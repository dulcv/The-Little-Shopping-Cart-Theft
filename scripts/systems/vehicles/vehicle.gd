class_name Vehicle
extends CharacterBody2D

## Entidad coche desacoplada del conductor (clon del patrón Weapon).
## Acepta conductor jugador (lee Input) o NPC (nodo con get_drive_input()).
## Daño por armas vía take_damage() (compatible con bullet.gd) y por
## choques vía velocidad de impacto. Visual = AnimatedSprite2D con las
## animaciones avanzar/retroceder (+ variantes humo/crítico) y explosion.
## Sonidos reales de assets/audio/sfx/auto/ + radio de 4 estaciones
## (scripts/systems/vehicles/vehicle_radio.gd). R = cambiar estación,
## H = claxon.

signal hp_changed(current: int, maximum: int)
signal state_changed(new_state: int)
signal driver_entered(driver: Node2D)
signal driver_exited(driver: Node2D)
signal crashed(impact_speed: float, damage: int)
signal exploded(vehicle: Vehicle)

enum DamageState { PRISTINE, SMOKING, CRITICAL, WRECKED }

@export var vehicle_data: VehicleData

var current_hp: int = 100
var max_hp: int = 100
var damage_state: int = DamageState.PRISTINE
## Velocidad escalar hacia adelante (+ adelante, - reversa)
var speed: float = 0.0
var driver: Node2D = null
var is_wrecked: bool = false

var _crash_cooldown: float = 0.0
var _ram_cooldown: float = 0.0

@onready var visual: Node2D = $Visual
@onready var car_sprite: AnimatedSprite2D = $Visual/CarSprite
@onready var enter_area: Area2D = $EnterArea
@onready var ram_area: Area2D = $RamArea
@onready var smoke: CPUParticles2D = $SmokeParticles
@onready var fire: CPUParticles2D = $FireParticles
@onready var engine_sound: AudioStreamPlayer2D = $EngineSound
@onready var crash_sound: AudioStreamPlayer2D = $CrashSound
@onready var explosion_sound: AudioStreamPlayer2D = $ExplosionSound
@onready var door_sound: AudioStreamPlayer2D = $DoorSound
@onready var horn_sound: AudioStreamPlayer2D = $HornSound
@onready var ignition_sound: AudioStreamPlayer2D = $IgnitionSound
@onready var reverse_sound: AudioStreamPlayer2D = $ReverseSound
@onready var siren_sound: AudioStreamPlayer2D = $SirenSound
@onready var radio: VehicleRadio = $Radio
@onready var debug_label: Label = $DebugLabel

## Teclas de prueba: F1 = simula golpe de 15, F2 = repara 30.
## (El daño por choque real se prueba estrellándose contra el muro de test_vehicles.tscn)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		match key:
			KEY_F1:
				take_damage(15)
			KEY_F2:
				repair(30)
	if driver == null or is_wrecked:
		return
	# Solo el conductor jugador usa estos atajos (el NPC no pulsa teclas).
	if driver != null and not driver.has_method("get_drive_input"):
		if event.is_action_pressed("radio_next") or _is_key(event, KEY_R):
			if radio:
				radio.next_station()
		elif event.is_action_pressed("horn") or _is_key(event, KEY_H):
			play_horn()

## Compara tecla física/lógica (vale para layouts que no reportan physical).
func _is_key(event: InputEvent, code: Key) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		return k.physical_keycode == code or k.keycode == code
	return false

func _process(_delta: float) -> void:
	_update_animation()
	if debug_label:
		var state_name: String = ["OK", "HUMO", "CRITICO", "DESTRUIDO"][damage_state]
		var line1 := "HP %d/%d %s | %d px/s" % [current_hp, max_hp, state_name, int(absf(speed))]
		if vehicle_data == null:
			line1 = "SIN DATOS (asigna vehicle_data)\n" + line1
		if driver != null and not is_wrecked and radio:
			debug_label.text = "%s\n%s - %s" % [line1, radio.get_station_name(), radio.get_track_name()]
		else:
			debug_label.text = line1

func _ready() -> void:
	add_to_group("vehicles")
	_apply_collision_layers()
	if vehicle_data:
		_setup_from_data()
	else:
		current_hp = 100
		max_hp = 100
		push_warning("Vehicle sin vehicle_data en '%s': no podrá moverse. Asigna un .tres de resources/vehicles/ en el inspector." % get_path())
	_update_damage_state(false)
	_update_engine_sound()
	_update_reverse_sound()
	_update_siren_sound()
	if ram_area:
		ram_area.body_entered.connect(_on_ram_body_entered)

func _apply_collision_layers() -> void:
	# Capa 7: Vehiculos (bit 6 -> 64). Choca con Mundo(1)+Player(2)+Enemigos(4)+Vehiculos(64)
	collision_layer = 1 << 6
	collision_mask = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 6)

func _setup_from_data() -> void:
	max_hp = vehicle_data.max_hp
	current_hp = max_hp
	if car_sprite:
		if vehicle_data.sprite_frames:
			car_sprite.sprite_frames = vehicle_data.sprite_frames
		car_sprite.modulate = vehicle_data.sprite_tint
		car_sprite.speed_scale = vehicle_data.sprite_speed_scale
	# Los .tres solo traen stream si el coche tiene sonido propio;
	# si es null se conserva el default de vehicle.tscn (sfx/auto/).
	if vehicle_data.engine_sound and engine_sound:
		engine_sound.stream = vehicle_data.engine_sound
	if vehicle_data.crash_sound and crash_sound:
		crash_sound.stream = vehicle_data.crash_sound
	if vehicle_data.explosion_sound and explosion_sound:
		explosion_sound.stream = vehicle_data.explosion_sound
		explosion_sound.pitch_scale = 1.0
	if vehicle_data.door_sound and door_sound:
		door_sound.stream = vehicle_data.door_sound
	if vehicle_data.horn_sound and horn_sound:
		horn_sound.stream = vehicle_data.horn_sound
	if vehicle_data.ignition_sound and ignition_sound:
		ignition_sound.stream = vehicle_data.ignition_sound
	if vehicle_data.reverse_sound and reverse_sound:
		reverse_sound.stream = vehicle_data.reverse_sound
	if vehicle_data.siren_sound and siren_sound:
		siren_sound.stream = vehicle_data.siren_sound

# ------------------------------------------------------------------
# Conductor: jugador o NPC
# ------------------------------------------------------------------

func has_driver() -> bool:
	return driver != null

func can_be_entered() -> bool:
	return not is_wrecked and driver == null

## Llamado por el jugador/NPC para subir. Retorna false si no se puede.
func enter(body: Node2D) -> bool:
	if not can_be_entered():
		return false
	driver = body
	# Ocultar/desactivar al conductor a pie (el jugador se auto-gestiona)
	if driver.has_method("on_enter_vehicle"):
		driver.on_enter_vehicle(self)
	speed = 0.0
	driver_entered.emit(driver)
	_play_door()
	_play_ignition()
	if radio:
		radio.start()
	_update_engine_sound()
	_update_siren_sound()
	return true

## Expulsa al conductor en el primer lateral libre (evita solaparse con
## el coche y que física los pegue/empuje al salir).
func exit() -> void:
	if driver == null:
		return
	var exiting: Node2D = driver
	driver = null
	speed = 0.0
	velocity = Vector2.ZERO
	var exit_pos := _find_free_exit()
	if exiting.has_method("on_exit_vehicle"):
		exiting.on_exit_vehicle(exit_pos)
	driver_exited.emit(exiting)
	_play_door()
	if radio:
		radio.stop()
	_update_engine_sound()
	_update_siren_sound()
	_update_reverse_sound()

## Prueba laterales con test_move y devuelve el primero sin colisión.
func _find_free_exit() -> Vector2:
	var candidates := [
		Vector2.UP.rotated(rotation) * 30.0,
		Vector2.DOWN.rotated(rotation) * 30.0,
		Vector2.LEFT.rotated(rotation) * 30.0,
		Vector2.RIGHT.rotated(rotation) * 30.0,
	]
	for offset in candidates:
		# test_move comprueba si el coche colisionaría moviéndose ese offset;
		# si el lateral está libre para el coche, lo está para el conductor.
		if not test_move(global_transform, offset):
			return global_position + offset
	return global_position + candidates[0]

func _physics_process(delta: float) -> void:
	_crash_cooldown = maxf(0.0, _crash_cooldown - delta)
	_ram_cooldown = maxf(0.0, _ram_cooldown - delta)

	var throttle := 0.0
	var steer := 0.0

	if driver != null and not is_wrecked:
		var inp := _read_driver_input()
		throttle = inp.y
		steer = inp.x

	_drive(delta, throttle, steer)
	_detect_crash()
	_update_engine_sound()
	_update_reverse_sound()
	_update_siren_sound()

func _read_driver_input() -> Vector2:
	# NPC: implementa get_drive_input() -> Vector2(steer, throttle)
	if driver != null and driver.has_method("get_drive_input"):
		var v: Vector2 = driver.get_drive_input()
		return Vector2(clampf(v.x, -1.0, 1.0), clampf(v.y, -1.0, 1.0))
	# Jugador: ui_* + WASD/flechas directas (igual que player.gd, que compensa
	# que ui_* por defecto no incluye WASD).
	var th := Input.get_axis("ui_down", "ui_up")
	var st := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		th += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		th -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		st -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		st += 1.0
	return Vector2(clampf(st, -1.0, 1.0), clampf(th, -1.0, 1.0))

func _drive(delta: float, throttle: float, steer: float) -> void:
	if vehicle_data == null:
		return
	var max_fwd := vehicle_data.max_speed
	var max_rev := vehicle_data.reverse_speed
	if damage_state == DamageState.CRITICAL:
		max_fwd *= vehicle_data.critical_speed_mult
		max_rev *= vehicle_data.critical_speed_mult
	if is_wrecked or driver == null:
		throttle = 0.0
		steer = 0.0

	var target := 0.0
	if throttle > 0.0:
		target = throttle * max_fwd
	elif throttle < 0.0:
		target = throttle * max_rev

	var rate := vehicle_data.accel if throttle != 0.0 else vehicle_data.brake
	speed = move_toward(speed, target, rate * delta)

	# Freno de mano: aparcado o destruido = clavado, nadie lo empuja.
	if is_wrecked or driver == null:
		speed = 0.0
		velocity = velocity.move_toward(Vector2.ZERO, vehicle_data.brake * 2.0 * delta)
		move_and_slide()
		return

	# Solo gira si hay movimiento (y menos marcha atrás)
	if absf(speed) > 5.0:
		var dir_sign := 1.0 if speed > 0.0 else -1.0
		var speed_factor := clampf(absf(speed) / max_fwd, 0.25, 1.0)
		rotation += steer * vehicle_data.turn_speed * speed_factor * dir_sign * delta

	var forward := Vector2.RIGHT.rotated(rotation)
	var desired := forward * speed
	# grip simula derrape: interpola velocidad real hacia la deseada
	velocity = velocity.lerp(desired, clampf(vehicle_data.grip * delta, 0.0, 1.0))
	move_and_slide()

# ------------------------------------------------------------------
# Daño: armas + choques + embestidas
# ------------------------------------------------------------------

## Receptor universal (lo llama bullet.gd). También lo usan choques y explosiones.
func take_damage(amount: int) -> void:
	if is_wrecked:
		return
	current_hp = maxi(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	_update_damage_state()
	if current_hp <= 0:
		_explode()

func repair(amount: int) -> void:
	if is_wrecked:
		return
	current_hp = mini(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)
	_update_damage_state()

func _detect_crash() -> void:
	if vehicle_data == null or _crash_cooldown > 0.0 or is_wrecked:
		return
	if get_slide_collision_count() == 0:
		return
	var impact := absf(speed)
	if impact < vehicle_data.crash_min_speed:
		# Golpe suave: frena sin daño
		speed *= 0.4
		return
	var dmg := int((impact - vehicle_data.crash_min_speed) / 100.0 * vehicle_data.crash_factor) + 1
	_crash_cooldown = 0.5
	speed *= -0.25 # rebote
	_play_crash_sound(impact)
	crashed.emit(impact, dmg)
	# El choque también daña al otro si puede recibir daño
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i).get_collider()
		if col != null and col != driver and col.has_method("take_damage"):
			col.take_damage(dmg)
	take_damage(dmg)

func _on_ram_body_entered(body: Node2D) -> void:
	# Atropello: solo a alta velocidad, con cooldown, sin dañar al conductor
	if _ram_cooldown > 0.0 or is_wrecked or driver == null:
		return
	if body == driver or not body.has_method("take_damage"):
		return
	if body.is_in_group("vehicles"):
		return
	if absf(speed) < 80.0 or vehicle_data == null:
		return
	_ram_cooldown = 0.6
	var dmg := int(vehicle_data.ram_damage * clampf(absf(speed) / vehicle_data.max_speed, 0.5, 1.5))
	body.take_damage(dmg)

func _update_damage_state(emit_signal: bool = true) -> void:
	if max_hp <= 0:
		return
	var frac := float(current_hp) / float(max_hp)
	var prev := damage_state
	if current_hp <= 0:
		damage_state = DamageState.WRECKED
	elif vehicle_data and frac <= vehicle_data.critical_threshold:
		damage_state = DamageState.CRITICAL
	elif vehicle_data and frac <= vehicle_data.smoke_threshold:
		damage_state = DamageState.SMOKING
	else:
		damage_state = DamageState.PRISTINE
	_update_damage_visuals()
	if emit_signal and prev != damage_state:
		state_changed.emit(damage_state)

## Elige animación según daño + sentido de marcha. Convención de texturas:
## avanzar / retroceder (sano), *_humo (SMOKING), *_critico (CRITICAL),
## explosion (WRECKED, se deja en el último frame). Si un coche futuro no
## trae alguna variante, se cae a avanzar/retroceder.
func _update_animation() -> void:
	if car_sprite == null or car_sprite.sprite_frames == null:
		return
	var anim := "avanzar"
	if is_wrecked or damage_state == DamageState.WRECKED:
		anim = "explosion"
	else:
		var reversing := speed < -5.0
		match damage_state:
			DamageState.SMOKING:
				anim = "retroceder_humo" if reversing else "avanzar_humo"
			DamageState.CRITICAL:
				anim = "retroceder_critico" if reversing else "avanzar_critico"
			_:
				anim = "retroceder" if reversing else "avanzar"
		if not car_sprite.sprite_frames.has_animation(anim):
			anim = "retroceder" if reversing else "avanzar"
		if not car_sprite.sprite_frames.has_animation(anim):
			return
	if car_sprite.animation != anim:
		car_sprite.play(anim)
	if is_wrecked:
		# Congela la explosión en su último frame en vez de ocultarla.
		if car_sprite.frame >= car_sprite.sprite_frames.get_frame_count(anim) - 1:
			car_sprite.pause()
		return
	if absf(speed) > 8.0:
		if not car_sprite.is_playing():
			car_sprite.play(anim)
	else:
		car_sprite.pause()
		car_sprite.frame = 0

func _update_damage_visuals() -> void:
	if smoke:
		smoke.emitting = damage_state >= DamageState.SMOKING and not is_wrecked or is_wrecked
	if fire:
		fire.emitting = damage_state >= DamageState.CRITICAL
	# El feedback visual ahora lo dan las texturas (humo/crítico/explosión);
	# sin sprites (coches futuros sin textura) se conserva el humo/fuego.

func _explode() -> void:
	is_wrecked = true
	damage_state = DamageState.WRECKED
	speed = 0.0
	velocity = Vector2.ZERO
	_play_explosion_sound()
	# Expulsa al conductor (si es jugador reaparece al lado)
	if driver != null:
		exit()
	_update_damage_visuals()
	_update_animation()
	_update_engine_sound()
	_update_reverse_sound()
	_update_siren_sound()
	exploded.emit(self)

# ------------------------------------------------------------------
# Audio real (assets/audio/sfx/auto/, nombre = sonido que es)
# ------------------------------------------------------------------

## Loop de motor: solo suena si el .tres trae engine_sound.
## Por ahora no hay loop de motor grabado, así que con el default (null)
## el coche arranca con encendido y suena reversa/choque/radio.
func _update_engine_sound() -> void:
	if engine_sound == null:
		return
	if engine_sound.stream == null:
		if engine_sound.playing:
			engine_sound.stop()
		return
	if driver != null and not is_wrecked:
		if not engine_sound.playing:
			engine_sound.play()
		var f := 0.7 + 0.8 * clampf(absf(speed) / 280.0, 0.0, 1.0)
		engine_sound.pitch_scale = f
	else:
		if engine_sound.playing:
			engine_sound.stop()

## Loop de reversa mientras se va marcha atrás con conductor.
func _update_reverse_sound() -> void:
	if reverse_sound == null:
		return
	if driver != null and not is_wrecked and speed < -8.0:
		if not reverse_sound.playing:
			reverse_sound.play()
	else:
		if reverse_sound.playing:
			reverse_sound.stop()

## La patrulla lleva sirena sonando mientras está en servicio.
func _update_siren_sound() -> void:
	if siren_sound == null:
		return
	var on := driver != null and not is_wrecked and _is_police()
	if on:
		if not siren_sound.playing:
			siren_sound.play()
	else:
		if siren_sound.playing:
			siren_sound.stop()

func _is_police() -> bool:
	return vehicle_data != null and vehicle_data.id == "patrulla"

func _play_crash_sound(impact: float) -> void:
	if crash_sound == null:
		return
	crash_sound.pitch_scale = randf_range(0.85, 1.1)
	crash_sound.volume_db = clampf(-6.0 + impact / 40.0, -6.0, 2.0)
	crash_sound.play()

## Puerta al entrar/salir, encendido al arrancar (alterna encendido2),
## claxon con H, explosión (hasta tener explosion.mp3 usa choque grave).
func _play_door() -> void:
	if door_sound:
		door_sound.pitch_scale = randf_range(0.95, 1.05)
		door_sound.play()

func _play_ignition() -> void:
	if ignition_sound == null:
		return
	if vehicle_data and vehicle_data.ignition_alt_sound and randf() < 0.5:
		ignition_sound.stream = vehicle_data.ignition_alt_sound
	elif vehicle_data and vehicle_data.ignition_sound:
		ignition_sound.stream = vehicle_data.ignition_sound
	ignition_sound.pitch_scale = randf_range(0.95, 1.05)
	ignition_sound.play()

func play_horn() -> void:
	if horn_sound == null or is_wrecked:
		return
	horn_sound.pitch_scale = randf_range(0.97, 1.03)
	horn_sound.play()

func _play_explosion_sound() -> void:
	if explosion_sound == null:
		return
	if explosion_sound.stream == null and crash_sound and crash_sound.stream:
		explosion_sound.stream = crash_sound.stream
	explosion_sound.pitch_scale = 0.5
	explosion_sound.volume_db = 4.0
	explosion_sound.play()
