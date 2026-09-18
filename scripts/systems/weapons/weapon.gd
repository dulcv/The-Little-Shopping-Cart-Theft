class_name Weapon
extends Node2D

## Componente desacoplado de arma.
## Puede adjuntarse tanto al jugador como a NPCs o enemigos.
## Gestiona el apuntado (por teclado o dirección), instanciación de balas,
## fogonazo de disparo, cadencia y volteo vertical automático.

signal weapon_fired(data: WeaponData)
signal ammo_changed(current: int, max_ammo: int)
signal weapon_equipped(data: WeaponData)

@export var weapon_data: WeaponData
@export var is_enemy: bool = false

var aim_direction: Vector2 = Vector2.RIGHT

@onready var weapon_sprite: Sprite2D = $WeaponSprite
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_flash: Sprite2D = $MuzzleFlash
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var flash_timer: Timer = $FlashTimer
@onready var fire_sound_player: AudioStreamPlayer2D = $FireSound

func _ready() -> void:
	# Inicializar timers
	flash_timer.one_shot = true
	flash_timer.wait_time = 0.05
	flash_timer.timeout.connect(_on_flash_timer_timeout)
	
	cooldown_timer.one_shot = true
	
	if muzzle_flash:
		muzzle_flash.visible = false
	
	# Equipar arma inicial si fue asignada en el inspector
	if weapon_data:
		equip_weapon(weapon_data)
	else:
		_clear_visuals()

## Configura y equipa un recurso WeaponData en el componente
func equip_weapon(data: WeaponData) -> void:
	weapon_data = data
	if weapon_data == null:
		_clear_visuals()
		return
	
	weapon_sprite.visible = true
	weapon_sprite.centered = true
	weapon_sprite.texture = weapon_data.sprite
	weapon_sprite.region_enabled = true
	weapon_sprite.region_rect = weapon_data.sprite_region
	# hold_offset desplaza la TEXTURA (Sprite2D.offset) para que el punto de
	# agarre (empuñadura/gatillo, a `grip` px del borde trasero) coincida con
	# el origen del nodo Weapon (punto que rota sobre el ala).
	# Fórmula: offset.x = w/2 - grip, offset.y = h/2 - gy.
	# La culata (`grip` px) queda detrás de la mano, apoyada en el cuerpo;
	# el cañón (w - grip px) sobresale por delante. El muzzle va en (w-grip+1, 0).
	weapon_sprite.offset = weapon_data.hold_offset
	
	muzzle.position = weapon_data.muzzle_offset
	muzzle_flash.position = weapon_data.muzzle_offset
	
	weapon_equipped.emit(weapon_data)
	ammo_changed.emit(weapon_data.current_ammo, weapon_data.max_ammo)

## Desequipa el arma actual
func unequip_weapon() -> WeaponData:
	var prev_data := weapon_data
	weapon_data = null
	_clear_visuals()
	return prev_data

func _clear_visuals() -> void:
	if weapon_sprite:
		weapon_sprite.visible = false
		weapon_sprite.texture = null
	if muzzle_flash:
		muzzle_flash.visible = false

## Actualiza la orientación del arma a partir de un vector de dirección (ej. WASD o flechas).
## Si dir es Vector2.ZERO, conserva la última dirección activa.
func set_aim_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	
	aim_direction = dir.normalized()
	rotation = aim_direction.angle()
	
	# Volteo vertical: si el personaje apunta a la izquierda, invertimos el eje Y
	# para que el sprite del arma no quede invertido de cabeza
	if aim_direction.x < 0.0:
		scale.y = -1.0
	else:
		scale.y = 1.0

## Verifica si el arma está en condiciones de disparar
func can_shoot() -> bool:
	if weapon_data == null:
		return false
	if not cooldown_timer.is_stopped():
		return false
	if weapon_data.max_ammo != -1 and weapon_data.current_ammo <= 0:
		return false
	return true

## Ejecuta la lógica de disparo (instancia proyectiles, fogonazo y cooldown)
func shoot() -> bool:
	if not can_shoot():
		return false
	
	# Reducir munición si no es infinita
	if weapon_data.max_ammo != -1:
		weapon_data.current_ammo -= 1
		ammo_changed.emit(weapon_data.current_ammo, weapon_data.max_ammo)
	
	# Iniciar cooldown de cadencia
	cooldown_timer.start(weapon_data.fire_rate)

	# Sonido del disparo (usa el fire_sound propio de cada arma)
	_play_fire_sound()

	# Mostrar fogonazo
	if muzzle_flash:
		muzzle_flash.visible = true
		flash_timer.start()
	
	# Instanciar proyectiles según bullets_per_shot
	var scene_to_spawn: PackedScene = weapon_data.bullet_scene
	if scene_to_spawn:
		for i in range(weapon_data.bullets_per_shot):
			var bullet_instance = scene_to_spawn.instantiate()
			if bullet_instance is Bullet:
				# Aplicar dispersión aleatoria si está configurada
				var spread_rad: float = deg_to_rad(randf_range(-weapon_data.spread_degrees, weapon_data.spread_degrees))
				var final_dir: Vector2 = aim_direction.rotated(spread_rad)
				
				bullet_instance.global_position = muzzle.global_position
				bullet_instance.setup(final_dir, weapon_data.bullet_speed, weapon_data.damage, is_enemy)
				
				# Agregar la bala al árbol principal para que su movimiento sea independiente del arma
				var spawn_root: Node = get_tree().current_scene
				if spawn_root:
					spawn_root.add_child(bullet_instance)
				else:
					get_tree().root.add_child(bullet_instance)
	
	weapon_fired.emit(weapon_data)
	return true

## Maneja la pulsación del gatillo según si el arma es automática o semiautomática
func handle_trigger(is_pressed: bool, is_just_pressed: bool) -> bool:
	if weapon_data == null:
		return false
	
	if weapon_data.is_automatic:
		if is_pressed:
			return shoot()
	else:
		if is_just_pressed:
			return shoot()
	return false

func _on_flash_timer_timeout() -> void:
	if muzzle_flash:
		muzzle_flash.visible = false

## Reproduce el sonido de disparo del arma equipada.
## Si el recurso no trae `fire_sound`, no hace nada (disparo silencioso).
func _play_fire_sound() -> void:
	if weapon_data == null or weapon_data.fire_sound == null:
		return
	if fire_sound_player == null:
		return
	fire_sound_player.stream = weapon_data.fire_sound
	fire_sound_player.volume_db = weapon_data.fire_volume_db
	fire_sound_player.pitch_scale = 1.0 + randf_range(-weapon_data.fire_pitch_variation, weapon_data.fire_pitch_variation)
	fire_sound_player.play()
