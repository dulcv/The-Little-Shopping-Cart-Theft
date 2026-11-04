# Sistema de Vehículos

Patrón clonado de armas: `VehicleData (.tres)` + `Vehicle (CharacterBody2D)` + conductor intercambiable.

## Archivos

- `scripts/systems/vehicles/vehicle_data.gd` (Resource): `max_speed, reverse_speed, accel, brake, turn_speed, grip, max_hp, ram_damage, crash_min_speed, crash_factor, smoke/critical_threshold`, visual (`sprite_frames, sprite_tint` legacy, `sprite_speed_scale` + `body_color/size` como fallback), pintura por shader (`enable_paint_shader, paint_color, use_random_paint, paint_palette`), sonidos (`engine/crash/explosion/door/horn/ignition/ignition_alt/reverse/siren_sound`, todos opcionales + interruptor `siren_enabled`).
- `resources/vehicles/sedan.tres, patrulla.tres, camioneta.tres` + `coche_azul_sprite_frames.tres` (sedán/camioneta, 7 animaciones) y `patrulla_sprite_frames.tres` (librea propia de patrulla, mismo layout 256x32 de 4 frames 64x32). Sedán/camioneta usan pintura aleatoria del shader; patrulla lleva `enable_paint_shader = false` para no alterar su librea.
- `scripts/systems/vehicles/vehicle.gd` + `scenes/vehicles/vehicle.tscn` (`AnimatedSprite2D` CarSprite + `CPUParticles2D` humo/fuego + 9 `AudioStreamPlayer2D`: motor/choque/explosión/puerta/claxon/encendido/reversa/sirena/radio + nodo `Radio`).
- `scripts/systems/vehicles/vehicle_radio.gd` (`class_name VehicleRadio`): 4 estaciones = carpetas de `assets/audio/radio/` (`anita_radio, dulce_radio, edgar_radio, jessi_radio`); escanea `.mp3/.ogg/.wav` en runtime, tolera estaciones vacías ("Sin señal"), avanza de canción sola. Temporal sin UI: `R` (`radio_next`) cambia de estación, el `DebugLabel` muestra `estación - canción` al conducir.
- `scripts/systems/vehicles/npc_driver.gd` (plantilla IA: `get_drive_input() -> Vector2(steer, throttle)`)
- `scenes/vehicles/test_vehicles.tscn` (3 tipos para probar)

## Uso

1. Instancia `vehicle.tscn`, asigna su `vehicle_data`.
2. Jugador: acércate (<44 px) + `E` para entrar (suena puerta + encendido y arranca la radio), `WASD/flechas` para conducir (acelerar + girar), `Espacio/Click` = drive-by oculto desde la ventanilla izquierda en dirección del coche, `H` (`horn`) = claxon, `G` (`siren`) = activar/silenciar sirena (solo patrulla), `R` (`radio_next`) = cambiar de estación, `E` para salir (busca lateral libre, suena puerta y se apaga la radio). La sirena suena en loop mientras hay conductor y no está destruido, solo si el `.tres` trae `siren_enabled = true` (patrulla). En runtime: `set_siren_enabled(bool)` / `is_siren_enabled()` (variable por instancia, no muta el `.tres` compartido) y tecla `G` (`siren`, `toggle_siren()`, solo si el `.tres` la equipa). A pie y sin arma, los puños abollan coches (`MELEE_DAMAGE 8`, alcance 36 px). El `Camera2D` del jugador sigue al coche.
3. NPC: cualquier `Node2D` con `on_enter_vehicle/on_exit_vehicle/get_drive_input/take_damage` puede conducir vía `vehicle.enter(body)`.
4. Nuevo tipo: duplica un `.tres`, ajusta stats y asigna su `sprite_frames` (animaciones `avanzar/retroceder`, variantes `_humo/_critico` y `explosion`; si falta alguna variante hay fallback a `avanzar/retroceder`). Nueva canción: suelta el `.mp3` en la carpeta de la estación, sin tocar código.

## Pintura por shader (`assets/shaders/vehicle_paint.gdshader`, opción A)

Reutiliza la textura azul en varios coches sin teñir vidrios/llantas/humo/explosión: el shader solo recolorea píxeles donde el azul domina (`b - max(r,g) > mask_threshold` + saturación mínima) y transfiere el sombreado pixel-art vía HSV (escala S/V relativos a la carrocería original). La explosión (naranja) y el humo (gris) quedan fuera de la máscara por construcción.

- `.tres`: `enable_paint_shader` (false = librea propia, ej. patrulla), `paint_color` (fijo), `use_random_paint = true` + `paint_palette` (cada instancia elige color al spawnear; si la paleta está vacía usa la default de `vehicle.gd` con 9 colores).
- Runtime: `set_paint_color(Color)` (crea `ShaderMaterial` único por instancia), `pick_random_paint()`, `current_paint`. Ideal para spawner de tráfico: `coche.set_paint_color(coche.pick_random_paint())`.
- Compat: `sprite_tint` (modulate) se mantiene como legacy; si un `.tres` viejo lo trae, se usa como color de pintura.

## Daño

- Armas: `take_damage(amount)` (las balas ya incluyen capa 7 Vehiculos en su máscara).
- Choques: `move_and_slide` + `speed > crash_min_speed` -> `daño = (speed-min)/100*factor+1`, rebote, cooldown 0.5 s, suena `CrashSound`.
- Atropello: `RamArea` daña a `take_damage` si `speed > 80`, cooldown 0.6 s.
- Drive-by: las balas ignoran al vehículo propio (`Weapon.ignore_root` -> `Bullet.ignore_root`, atraviesa cuerpo + `EnterArea/RamArea` sin daño). Si el drive-by dañara al coche, revisar ese campo.
- Estados: `PRISTINE > SMOKING (animación *_humo + humo) > CRITICAL (animación *_critico + fuego, -45% velocidad) > WRECKED (animación explosion congelada en el último frame, expulsa conductor, inmóvil)`. `repair()` solo si no wrecked.
- Señales: `hp_changed, state_changed, driver_entered/exited, crashed, exploded`.

## Audio real (`assets/audio/sfx/auto/`, el nombre describe el sonido)

Puerta (`abrir_puerta`) al entrar/salir, encendido (`encendido`, alterna con `encendido2`) al arrancar, choque (`choque`, pitch/volumen por impacto), claxon (`claxon`, sedán/patrulla) / `pip_pip` (camioneta) con `H`, reversa (`reversa` en loop marcha atrás), sirena (`sirena_policias` en loop si `siren_enabled`, solo con conductor y sin destruir), explosión (reutiliza `choque` grave hasta tener `explosion.mp3`), radio (`RadioPlayer` + `VehicleRadio`). Sin loop de motor grabado: `EngineSound` solo suena si el `.tres` trae `engine_sound`.

## Física

Capa 7 `Vehiculos` (64), máscara `Mundo+Player+Enemigos+Vehiculos` (71). Jugador a pie: máscara 69 (`Mundo+Enemigos+Vehiculos`) para chocar con coches aparcados. Coche sin conductor = freno de mano (clavado, no se puede empujar). Balas jugador: `Mundo+Enemigos+Vehiculos`; enemigas: `Mundo+Player+Vehiculos`.

## Probar daño por choques (`test_vehicles.tscn`)

- Muro en U a la derecha: acelera a fondo contra él. Cada coche muestra `HP/estado/velocidad` encima.
- `F1` = +15 de daño al coche enfocado, `F2` = repara 30 (prueba niveles HUMO/CRITICO/DESTRUIDO sin chocar).
