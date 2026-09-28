# Sistema de Vehículos

Patrón clonado de armas: `VehicleData (.tres)` + `Vehicle (CharacterBody2D)` + conductor intercambiable.

## Archivos

- `scripts/systems/vehicles/vehicle_data.gd` (Resource): `max_speed, reverse_speed, accel, brake, turn_speed, grip, max_hp, ram_damage, crash_min_speed, crash_factor, smoke/critical_threshold`, visual (`sprite_frames, sprite_tint, sprite_speed_scale` + `body_color/size` como fallback), sonidos (`engine/crash/explosion/door/horn/ignition/ignition_alt/reverse/siren_sound`, todos opcionales).
- `resources/vehicles/sedan.tres, patrulla.tres, camioneta.tres` (los 3 usan `coche_azul_sprite_frames.tres`; patrulla/camioneta con `sprite_tint` hasta tener textura propia) + `resources/vehicles/coche_azul_sprite_frames.tres` (7 animaciones de 8 frames 32x32: `avanzar, retroceder, avanzar_humo, retroceder_humo, avanzar_critico, retroceder_critico, explosion`).
- `scripts/systems/vehicles/vehicle.gd` + `scenes/vehicles/vehicle.tscn` (`AnimatedSprite2D` CarSprite + `CPUParticles2D` humo/fuego + 9 `AudioStreamPlayer2D`: motor/choque/explosión/puerta/claxon/encendido/reversa/sirena/radio + nodo `Radio`).
- `scripts/systems/vehicles/vehicle_radio.gd` (`class_name VehicleRadio`): 4 estaciones = carpetas de `assets/audio/radio/` (`anita_radio, dulce_radio, edgar_radio, jessi_radio`); escanea `.mp3/.ogg/.wav` en runtime, tolera estaciones vacías ("Sin señal"), avanza de canción sola. Temporal sin UI: `R` (`radio_next`) cambia de estación, el `DebugLabel` muestra `estación - canción` al conducir.
- `scripts/systems/vehicles/npc_driver.gd` (plantilla IA: `get_drive_input() -> Vector2(steer, throttle)`)
- `scenes/vehicles/test_vehicles.tscn` (3 tipos para probar)

## Uso

1. Instancia `vehicle.tscn`, asigna su `vehicle_data`.
2. Jugador: acércate (<44 px) + `E` para entrar (suena puerta + encendido y arranca la radio), `WASD/flechas` para conducir (acelerar + girar), `Espacio/Click` = drive-by oculto desde la ventanilla izquierda en dirección del coche, `H` (`horn`) = claxon, `R` (`radio_next`) = cambiar de estación, `E` para salir (busca lateral libre, suena puerta y se apaga la radio). La patrulla lleva la sirena sonando mientras está en servicio. A pie y sin arma, los puños abollan coches (`MELEE_DAMAGE 8`, alcance 36 px). El `Camera2D` del jugador sigue al coche.
3. NPC: cualquier `Node2D` con `on_enter_vehicle/on_exit_vehicle/get_drive_input/take_damage` puede conducir vía `vehicle.enter(body)`.
4. Nuevo tipo: duplica un `.tres`, ajusta stats y asigna su `sprite_frames` (animaciones `avanzar/retroceder`, variantes `_humo/_critico` y `explosion`; si falta alguna variante hay fallback a `avanzar/retroceder`). Nueva canción: suelta el `.mp3` en la carpeta de la estación, sin tocar código.

## Daño

- Armas: `take_damage(amount)` (las balas ya incluyen capa 7 Vehiculos en su máscara).
- Choques: `move_and_slide` + `speed > crash_min_speed` -> `daño = (speed-min)/100*factor+1`, rebote, cooldown 0.5 s, suena `CrashSound`.
- Atropello: `RamArea` daña a `take_damage` si `speed > 80`, cooldown 0.6 s.
- Drive-by: las balas ignoran al vehículo propio (`Weapon.ignore_root` -> `Bullet.ignore_root`, atraviesa cuerpo + `EnterArea/RamArea` sin daño). Si el drive-by dañara al coche, revisar ese campo.
- Estados: `PRISTINE > SMOKING (animación *_humo + humo) > CRITICAL (animación *_critico + fuego, -45% velocidad) > WRECKED (animación explosion congelada en el último frame, expulsa conductor, inmóvil)`. `repair()` solo si no wrecked.
- Señales: `hp_changed, state_changed, driver_entered/exited, crashed, exploded`.

## Audio real (`assets/audio/sfx/auto/`, el nombre describe el sonido)

Puerta (`abrir_puerta`) al entrar/salir, encendido (`encendido`, alterna con `encendido2`) al arrancar, choque (`choque`, pitch/volumen por impacto), claxon (`claxon`, sedán/patrulla) / `pip_pip` (camioneta) con `H`, reversa (`reversa` en loop marcha atrás), sirena (`sirena_policias` en loop solo en patrulla en servicio), explosión (reutiliza `choque` grave hasta tener `explosion.mp3`), radio (`RadioPlayer` + `VehicleRadio`). Sin loop de motor grabado: `EngineSound` solo suena si el `.tres` trae `engine_sound`.

## Física

Capa 7 `Vehiculos` (64), máscara `Mundo+Player+Enemigos+Vehiculos` (71). Jugador a pie: máscara 69 (`Mundo+Enemigos+Vehiculos`) para chocar con coches aparcados. Coche sin conductor = freno de mano (clavado, no se puede empujar). Balas jugador: `Mundo+Enemigos+Vehiculos`; enemigas: `Mundo+Player+Vehiculos`.

## Probar daño por choques (`test_vehicles.tscn`)

- Muro en U a la derecha: acelera a fondo contra él. Cada coche muestra `HP/estado/velocidad` encima.
- `F1` = +15 de daño al coche enfocado, `F2` = repara 30 (prueba niveles HUMO/CRITICO/DESTRUIDO sin chocar).
