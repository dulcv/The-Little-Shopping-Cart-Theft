# 09 — Contratos / Interfaces (LEER TODOS LOS AGENTES)

> Firmas congeladas. Si un agente necesita cambiarlas, actualiza este archivo primero.

## Daño / Salud

```gdscript
func take_damage(amount: int) -> void
func heal(amount: int) -> void
func is_dead() -> bool
signal health_changed(current: int, maximum: int)
signal died(who: Node2D, killer: Node)
```

Ya existe en `vehicle.gd:369` y stub en `player.gd:368`. NPC y Player deben implementarlo igual. `bullet.gd` ya llama `take_damage` si existe.

## Vehículos

```gdscript
# vehicle.gd (existente, no romper)
func enter(body: Node2D) -> bool
func exit() -> void
func can_be_entered() -> bool
func get_drive_input() -> Vector2  # x=steer, y=throttle (NPC lo implementa)
signal driver_entered(vehicle, driver)
signal driver_exited(vehicle, driver)
```

NPC conductor debe tener `on_enter_vehicle/on_exit_vehicle/get_drive_input/take_damage` (ver `npc_driver.gd` plantilla).

## Diálogos

```gdscript
# dialogue_system.gd (Autoload o singleton escena)
func start_dialogue(id: String, talker_name: String) -> void
signal dialogue_finished(id: String)
# Uso en NPC: DialogueSystem.start_dialogue(npc.dialogue_id, npc.display_name)
```

Texto con placeholder `{alias}` = `GameManager.selected_character.alias_llamado`.

## Policía / Wanted

```gdscript
# wanted_system.gd (Autoload)
signal wanted_changed(level: int)  # 0..5 huevos
var wanted_level: int
func add_heat(amount: int, reason: String) -> void
func clear_heat() -> void
```

Crimen reporta: `WantedSystem.add_heat(1, "asesinato")`, `add_heat(1, "robo_coche")`.

## Economía / Pickups

```gdscript
# money_manager (en GameManager o Autoload propio)
signal money_changed(amount: int)
func add_money(n: int) -> void
# WeaponPickup capa 6 (como Fase 5 de sistema_armas.md:150)
func equip_weapon(data: WeaponData) -> void  # ya existe en player.gd
```

`money_pickup.tscn: Area2D capa6 + sprite moneda/huevo + colision + _on_body_entered -> MoneyManager.add_money(value)`.

## Personajes

```gdscript
# character_data.gd extends Resource, class_name CharacterData
@export var id: String
@export var display_name: String
@export var alias_llamado: String  # como te llaman NPCs/diálogos
@export var sprite_frames: SpriteFrames
@export var max_hp: int = 100
@export var speed_mult: float = 1.0
@export var starting_weapon: WeaponData
@export var description: String
```

`GameManager.selected_character: CharacterData` es la única fuente de verdad.

## Grupos Godot

- `"vehicles"` (ya usado por `npc_driver.gd`), `"npcs"`, `"enemies"`, `"police"`, `"pickups"`.

## Añadido trama v1 (Dúo + Evidencias + Doble alerta)

```gdscript
# GameManager amplía (sin romper selected_character):
var selected_ids: Array[String] = ["edgar"]
var is_duo: bool = false  # true = Edgar+Dulce juntos
signal duo_changed(is_duo: bool)
# Evidencias:
signal evidence_added(id: String)
func add_evidence(ev: EvidenceData) -> void
func has_evidence(id: String) -> bool
# Doble notoriedad (guardia = huevos existentes, federacion = nuevo):
signal federacion_changed(level: int)
func add_federacion(n: int, reason: String) -> void
```

`EvidenceData.Kind`: `CASSETTE, LEDGER, PHOTO, FLIGHT_LOG` (ver doc 11). Diálogos usan `PLACEHOLDER_*`.
