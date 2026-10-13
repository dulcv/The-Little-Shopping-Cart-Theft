# 05 — IA NPCs Centro: peatones + tráfico + reacciones (Agente-IA)

## Inventario Centro (levantar en editor)

- `Centro.tscn` hoy: Background+Houses+Player+Vehicle. Sin RoadNetwork.
- Tarea 1: pintar con `carretera.png` el óvalo principal, marcar `RoadPath: Path2D` con `Curve2D` siguiendo carriles.
- Tarea 2: `NavigationRegion2D` en aceras (bake).
- Reutilizar muros de `test_vehicles.tscn:42-57` como referencia de colisión.

## `scenes/characters/npc/npc.tscn` + `scripts/systems/npcs/npc.gd`

```
NPC (CharacterBody2D, layer3 Enemigos, mask 1+2+7)
 ├ CollisionShape 18x19 (igual player)
 ├ AnimatedSprite2D (mismo frames + chicken_variant material)
 ├ NavigationAgent2D (peatón)
 ├ Perception (Area2D radio 120: detecta disparos/crímenes)
 ├ Weapon (slot, mismo weapon.tscn)
 └ StateLabel (debug)
```

Estados: `IDLE/WANDER/FLEE/CHASE_MELEE/ATTACK/FLEE_CAR/ENTER_CAR/DRIVE/WITNESS/DEAD`.

- `WANDER`: `NavigationAgent2D.target = PedSpawn aleatorio`, `walk 100*speed_mult`, anim `walk/walk_up/down`.
- `DRIVE`: delega a `vehicle.enter(self)` + implementa `get_drive_input()` persiguiendo `RoadPath` (reemplaza óvalo demo `npc_driver.gd`).
- Reutilizar movimiento 4-dir de `player.gd:171-180` para anims compatibles.

## Reacciones NPC-NPC / coche

| Evento | Detección | Reacción |
|---|---|---|
| Choque coche-coche | `vehicle.gd:386 _detect_crash()` señal `crashed` | conductor sale, discute (`dialogue_id=discusion_choque`), 20% pelea |
| Atropello | `RamArea speed>80` (`vehicle.gd:408`) | víctima `FLEE`+grita, testigos `WITNESS`+`WantedSystem.add_heat(1)` |
| Golpe puño/bala | `take_damage()` + `Perception.body_entered` | `FLEE` si hp<30%, `CHASE` si facción hostil |
| Muerte | `died` | dropea dinero (ver `08`), cadáver 10s + `die` anim loop0 |

Facciones (`faction: String`): `civil, gallos_negros, guardia_corral, policia`. Tabla hostilidad 4x4 en `npc_factions.gd`.

## `npc_spawner.gd`

Pool: máx 10 peds + 4 coches en radio 300px del player, respawn en `PedSpawns/CarSpawns`. Usa `pick_random_paint()` (`sistema_vehiculos.md:26`) + `apply_variant()`.

## Aceptación

- 8 NPCs caminan sin atravesar muros, 2 conducen por carretera, al atropellar uno los demás huyen y sube 1 huevo.
