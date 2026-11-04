class_name VehicleData
extends Resource

## Recurso data-driven que define un tipo de coche.
## Clona el patrón de WeaponData: crear un .tres por tipo sin tocar código.
## Placeholder visual = color (hasta tener sprites).

@export_group("Identificación")
@export var id: String = "sedan"
@export var vehicle_name: String = "Sedán"
@export_multiline var description: String = ""

@export_group("Conducción (arcade top-down)")
## Velocidad máxima hacia adelante (px/s)
@export var max_speed: float = 220.0
## Velocidad marcha atrás (px/s, positiva, se aplica en negativo)
@export var reverse_speed: float = 90.0
## Aceleración (px/s²)
@export var accel: float = 260.0
## Frenado / fricción al soltar (px/s²)
@export var brake: float = 320.0
## Velocidad de giro (rad/s a máxima velocidad)
@export var turn_speed: float = 2.6
## Agarre: 1.0 = sin derrape, 0.0 = hielo. Se interpola velocidad lateral.
@export var grip: float = 6.0

@export_group("Daño y resistencia")
@export var max_hp: int = 100
## Daño por embestida a peatones (a velocidad alta)
@export var ram_damage: int = 25
## Velocidad mínima para que el choque haga daño al coche (px/s)
@export var crash_min_speed: float = 120.0
## Multiplicador de daño por choque: daño = (speed - min) / 100 * factor
@export var crash_factor: float = 12.0
## Umbrales de estado (fracción de HP): humo / crítico
@export var smoke_threshold: float = 0.7
@export var critical_threshold: float = 0.35
## Penalización de velocidad cuando está en crítico (0.0-1.0)
@export var critical_speed_mult: float = 0.55

@export_group("Visual (texturas)")
## SpriteFrames del coche. Animaciones esperadas (todas de 32x32 por frame):
## avanzar, retroceder, avanzar_humo, retroceder_humo,
## avanzar_critico, retroceder_critico, explosion.
## Si es null se usa el fallback de color (coches sin textura todavía).
@export var sprite_frames: SpriteFrames
## Tinte legacy (modulate). Se mantiene por compatibilidad, pero el
## repintado principal lo hace el shader vehicle_paint.gdshader.
@export var sprite_tint: Color = Color.WHITE
@export var sprite_speed_scale: float = 1.0

@export_group("Pintura (shader vehicle_paint)")
## Si false, no se aplica shader (coches con librea propia, ej. patrulla).
@export var enable_paint_shader: bool = true
## Color de carrocería aplicado por shader (solo píxeles azules).
## Vidrios/llantas/humo/explosión no se tiñen.
@export var paint_color: Color = Color(0.3, 0.55, 0.9)
## Si true, cada instancia elige un color aleatorio de paint_palette al spawnear.
@export var use_random_paint: bool = false
## Paleta para variedad de tráfico. Si está vacía se usa la default de vehicle.gd.
@export var paint_palette: Array[Color] = []

@export_group("Audio")
## Todos opcionales: si es null, vehicle.gd usa el default de sfx/auto/.
## engine_sound es un loop de motor (si no hay, el coche no suena a motor,
## solo encendido/reversa/choque). crash = choque.mp3, etc.
@export var engine_sound: AudioStream
@export var crash_sound: AudioStream
@export var explosion_sound: AudioStream
@export var door_sound: AudioStream
@export var horn_sound: AudioStream
@export var ignition_sound: AudioStream
@export var ignition_alt_sound: AudioStream
@export var reverse_sound: AudioStream
@export var siren_sound: AudioStream
## Interruptor de sirena: si true, suena en loop mientras hay conductor y no está destruido.
@export var siren_enabled: bool = false

@export_group("Fallback (coches sin textura)")
@export var body_color: Color = Color(0.3, 0.55, 0.9)
@export var body_size: Vector2 = Vector2(36, 18)
