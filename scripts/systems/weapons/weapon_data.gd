class_name WeaponData
extends Resource

## Recurso que define las propiedades y estadísticas de un arma.
## Permite crear diferentes tipos de armas mediante archivos .tres reutilizables.

@export_group("Identificación")
@export var id: String = "weapon"
@export var weapon_name: String = "Arma"
@export_multiline var description: String = ""

@export_group("Visuales")
@export var sprite: Texture2D
## Región rectangular del sprite para recortar el lienzo transparente si es necesario
@export var sprite_region: Rect2 = Rect2(0, 0, 32, 16)
## Punto de agarre (empuñadura/gatillo) donde el personaje sujeta el arma.
## Se aplica como Sprite2D.offset (desplaza la textura, no el pivote):
## si el agarre está a `grip` px del borde trasero/izquierdo de la región
## (w,h) y a `gy` px desde arriba, usar offset = (w/2 - grip, h/2 - gy).
## La culata (lo que queda DETRÁS de la mano) mide `grip` px: grande en
## rifles (culata apoyada en el ala) y pequeño en pistola.
## Ej. pistola 10x6, agarre a 2px del fondo: Vector2(3, 2).
@export var hold_offset: Vector2 = Vector2(3, 2)
## Punto de salida del cañón (bala y fogonazo), relativo al punto de agarre:
## muzzle.x = ancho - grip + 1, muzzle.y = 0 (línea de la mano).
## Ej. pistola 10px con agarre a 2px: Vector2(9, 0).
@export var muzzle_offset: Vector2 = Vector2(9, 0)
## Textura opcional para el proyectil
@export var bullet_texture: Texture2D
## Escena del proyectil que dispara este arma
@export var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

@export_group("Estadísticas de Combate")
@export var damage: int = 10
@export var bullet_speed: float = 400.0
## Tiempo de espera entre disparos (en segundos)
@export var fire_rate: float = 0.2
## Si es verdadero, dispara continuamente al mantener presionada la tecla/botón
@export var is_automatic: bool = false
## Dispersión máxima aleatoria del proyectil en grados
@export var spread_degrees: float = 2.0
## Cantidad de proyectiles disparados simultáneamente por cada disparo
@export var bullets_per_shot: int = 1
## Tiempo máximo de vida de la bala en segundos
@export var bullet_lifetime: float = 2.0

@export_group("Munición")
## -1 indica munición infinita
@export var max_ammo: int = -1
@export var current_ammo: int = -1

@export_group("Audio")
## Sonido del disparo, uno por arma (ej. "Pistola" usa pistol.mp3)
@export var fire_sound: AudioStream
## Volumen del disparo en dB
@export var fire_volume_db: float = 0.0
## Variación aleatoria del pitch en cada disparo para que las ráfagas
## automáticas no suenen robóticas (0.04 = ±4%)
@export var fire_pitch_variation: float = 0.04
