# Avance de Coches — hecho y pendiente

> Técnico de referencia: `docs/sistema_vehiculos.md`.
> Actualizado: 2026-10-01.

## ✅ Hecho

- [x] `VehicleData` data-driven + 3 tipos (`sedan`, `patrulla`, `camioneta` en `resources/vehicles/`).
- [x] `Vehicle` (`CharacterBody2D`, capa 7 `Vehiculos`): física arcade (acelerar, reversa, giro por velocidad, derrape por `grip`), placeholder `Polygon2D` por color.
- [x] Entrar/salir con `E` (<44 px), salida en lateral libre (`test_move`), cámara del jugador sigue al coche.
- [x] Conductor intercambiable: jugador (WASD/flechas) o NPC (`get_drive_input()`; plantilla `npc_driver.gd`).
- [x] Daño por armas (`take_damage`, balas con capa 7 en máscara) y por choques (fórmula por velocidad + rebote + cooldown + sonido).
- [x] Niveles OK → HUMO → CRÍTICO (-45% velocidad) → DESTRUIDO (explosión, expulsa conductor, freno de mano).
- [x] Atropellos (`RamArea`, `speed > 80`).
- [x] Drive-by oculto desde la ventanilla izquierda; balas ignoran al coche propio (`ignore_root`).
- [x] Puños dañan coches (`MELEE_DAMAGE 8`, alcance 36).
- [x] Coche aparcado clavado (no se empuja); jugador a pie choca con coches (máscara 69).
- [x] Escena de pruebas (`scenes/vehicles/test_vehicles.tscn`): 3 coches + muro en U + cartel + etiqueta `HP/estado/velocidad` + `F1` daño / `F2` reparar.
- [x] Audio placeholder (motor/choque/explosión con mp3 existentes).
- [x] Sprites reales del coche azul (`coche_azul_sprite_frames.tres`: avanzar/retroceder/humo/crítico/explosión, 8 frames 32x32); `Polygon2D` eliminados. Camioneta reutiliza la azul con pintura del shader; patrulla tiene sprites propios (`patrulla_sprite_frames.tres`, mismo layout).
- [x] Pintura por shader (`assets/shaders/vehicle_paint.gdshader`): recolorea solo la carrocería azul (vidrios/llantas/humo/explosión intactos), color aleatorio por instancia en sedán/camioneta (`use_random_paint` + `paint_palette`), `set_paint_color()` para tráfico/garaje en runtime.
- [x] Interruptor de sirena data-driven (`siren_enabled` en el `.tres` + `set_siren_enabled()/is_siren_enabled()` en runtime, por instancia); patrulla lo trae activado.
- [x] Sonidos propios (`assets/audio/sfx/auto/`): puerta, encendido (x2), choque, claxon/pip_pip (`H`), reversa en loop, sirena en patrulla. Falta: loop de motor limpio y `explosion.mp3` (temporalmente reutiliza `choque` grave).
- [x] Radio de 4 estaciones (`vehicle_radio.gd`, escaneo en runtime, tolera carpetas vacías): suena al subir al coche, `R` cambia de estación, estación/canción visible en el `DebugLabel`. Falta UI dedicada.

## ❌ Falta

### Corto plazo
- [ ] Texturas propias de camioneta (solo crear PNGs + `.tres` de frames y asignar en su `.tres`; la patrulla ya tiene las suyas).
- [ ] `explosion.mp3` + loop de motor limpio (el código ya los espera: `explosion_sound`, `engine_sound`).
- [ ] Canciones de `anita_radio`/`dulce_radio` (carpetas vacías → "Sin señal").
- [ ] UI de radio (la lógica `station_changed/track_changed` ya emite señales para conectarla).
- [ ] Integrar coches en `Centro` (spawns aparcados + circulando).
- [ ] HUD de vida del coche al conducir.
- [ ] `NPCDriver` conectado a facciones reales (`guardia_corral`, bandas): perseguir/huir, atropellar, drive-by enemigo.
- [ ] Daño del coche al jugador/NPC a pie al explotar cerca (área de explosión).
- [ ] Probar en mapa real que no hay arrastres al entrar/salir junto a muros.

### Medio plazo
- [ ] Más tipos (moto, camión, carrito de compras temático) solo con `.tres`.
- [ ] Pasajeros / varios asientos.
- [ ] Persecuciones y nivel de búsqueda (policía `patrulla`).
- [ ] Talleres/pickups de reparación (`repair()` ya existe).
- [ ] Guardado de estado de vehículos (`data/`).

## Cómo probar

1. Abrir `scenes/vehicles/test_vehicles.tscn`, `F5`.
2. `E` entrar → `WASD` conducir → `Espacio` drive-by → `R` radio → `H` claxon → `E` salir.
3. Estrellarse contra el muro en U (ver HP encima) o `F1`/`F2`.
4. Sin arma, `Espacio` junto al coche = puños (8 de daño).
