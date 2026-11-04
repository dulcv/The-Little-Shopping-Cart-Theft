# 01 — Base Bloqueante (Agente-Base)

> Hacer PRIMERO. Sin esto nada de IA/policía/tráfico funciona.

## 1. Autoloads (ProjectSettings -> Autoload)

Crear en `scripts/systems/core/`:

- `game_manager.gd` (`class_name GameManager`): `selected_character: CharacterData`, `current_zone: String`, `is_paused: bool`, señales `character_changed, zone_changed`.
- `save_manager.gd`: `save_game()/load_game()` con `ConfigFile` en `user://save.cfg` (dinero, personaje, armas, wanted histórico).
- `scene_loader.gd`: `goto_scene(path)` + `load_threaded()` con señal `progress(ratio)` para barras de carga.
- `audio_manager.gd`: bus música/sfx, `play_sfx(stream, pos)`.
- `ui_manager.gd`: abre/cierra menús, guarda referencia a `HUD`.

Registrar en `project.godot` sección `[autoload]`. Hoy no existe ninguno.

## 2. Centro: colisiones + navegación

Archivo: `scenes/world/el_centro/Centro.tscn` (~782 líneas, hoy 6 nodos, sin física).

Tareas:
1. En TileSet (`TileSet_enuon`): añadir `physics_layer_0` a tiles de `edificios.png` y `ed.png` (sólidos), y a `piedra` bordes. `Background` (carretera/tierra) sin colisión.
2. Añadir `StaticBody2D` por manzana si el autotile no basta (rápido para prototipo).
3. Añadir `NavigationRegion2D` + `NavigationLink2D` en aceras. Bakear `navigation_polygon` para peatones. Carretera = capa separada para coches.
4. Verificar máscaras: Player `layer2 mask69` debe chocar con Mundo(1)+Vehículos(64). Vehicle `layer64 mask71` ya OK (`vehicle.tscn:22-24`, `docs/sistema_vehiculos.md:44`).

## 3. Markers obligatorios (todos `Marker2D`)

```
Centro/
  Spawns/PlayerSpawn (0,0 actual)
  Spawns/CarSpawns/CarSpawn_01..06 (en carretera)
  Spawns/PedSpawns/PedSpawn_01..10 (en acera)
  Spawns/WeaponSpawns/WeaponSpawn_01..04
  Spawns/PoliceSpawn (comisaría/corral)
  Zones/WantedClearZone (para bajar huevos)
```

## 4. Criterio de aceptación

- Player ya no atraviesa edificios.
- `NavigationServer2D.map_get_path()` devuelve ruta entre 2 PedSpawns.
- Coche spawneado en CarSpawn no colisiona con edificio al arrancar.
