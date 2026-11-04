# 07 — Policía Huevos Rotos (Agente-Sistemas)

> Sistema estrellas GTA pero con huevos rotos 0-5.

## `scripts/systems/police/wanted_system.gd` (Autoload)

```gdscript
var wanted_level: int = 0  # 0..5
signal wanted_changed(level)
func add_heat(n, reason): wanted_level=clamp(+n); timer decaimiento 30s sin crimen
func clear_heat(): wanted_level=0  # en WantedClearZone
```

Causas: asesinato +2, disparo visto +1, robo coche +1, atropello +1, golpe +1. Testigos = `Perception` NPC con línea de vista.

## `scenes/characters/police/policia_npc.tscn` + `patrulla`

- Hereda `npc.tscn`, `faction=policia`, `max_hp=80`, arma `pistol.tres`.
- Patrulla usa `resources/vehicles/patrulla.tres` (`siren_enabled=true`, `max_speed 280`). Sirena ya funciona en `vehicle.gd:536-561` con `G`.
- IA: `CHASE` player si `wanted>0` en radio 400, `DRIVE` persiguiendo `player.global_position`, a pie `ATTACK` melee + disparo a >60px.

## Niveles

| Huevos | Respuesta |
|---|---|
| 1 | 1 patrulla persigue, diálogo `alto_policia` |
| 2 | 2 patrullas + 1 a pie |
| 3 | Bloqueo con coche cruzado + gallos huyen |
| 4-5 | Guardia_corral ayuda, interceptores rápidos |

HUD: 5 sprites huevo (entero/roto) en `hud.tscn`, escucha `wanted_changed`.

## Aceptación

- Matar civil a la vista sube a 2 huevos, patrulla llega con sirena, esconderse 30s baja a 0.
