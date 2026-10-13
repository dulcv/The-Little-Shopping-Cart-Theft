# 03 — Selección de Personajes (Agente-Shader-PJ)

## Archivos a crear

- `scripts/systems/core/character_data.gd` (`class_name CharacterData`, ver contrato `09`).
- `resources/characters/edgar.tres, dulce.tres, jessi.tres, pollo_base.tres` (usar sprites existentes `assets/sprites/characters/Edgar/*`, `Dulce/*`, `player/*`).
- `scenes/ui/menus/character_select.tscn` (grid + preview `AnimatedSprite2D` + stats + botón Elegir).
- Modificar `player.gd`: en `_ready()`, si `GameManager.selected_character != null`, `animated_sprite.sprite_frames = selected.sprite_frames`, `max_hp/speed`, `equip_weapon(starting_weapon)`.

## Efectos en juego (diseño)

| Campo | Efecto |
|---|---|
| `alias_llamado` | `DialogueSystem` sustituye `{alias}` ("Órale {alias}"). |
| `speed_mult / max_hp` | Multiplica `SPEED 100 / RUN_SPEED 150` de `player.gd:3-4`. |
| `starting_weapon` | `pistol.tres` por defecto, Edgar arranca con rifle, etc. |
| `radio_fav` | `VehicleRadio` arranca en su estación. |

## Guardado

`SaveManager`: `selected_character_id` en `user://save.cfg`. `character_select` escribe + `GameManager.character_changed.emit()`.

## Aceptación

- Elegir Edgar cambia sprite, nombre en diálogos y arma inicial tras reload.
