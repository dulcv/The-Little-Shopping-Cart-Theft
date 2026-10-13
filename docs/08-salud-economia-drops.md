# 08 — Salud + Economía + Armas en mapa + Drops (Agente-Sistemas)

## Salud (cerrar Fase 6 de `sistema_armas.md:158`)

Implementar contrato `09` en `player.gd` (hoy `take_damage: pass`) y `npc.gd`:

```gdscript
@export var max_hp:=100
var hp: int
func take_damage(n): hp-=n; play("damage"); health_changed.emit; if hp<=0: die()
func die(): play("die"); collision off; drop; queue_free tras 2s / wanted_dead si es player
```

HUD barra + flash rojo. `damage/die` anims ya existen en `player1_sprite_frames.tres:213-239`.

## Economía

- `GameManager.money: int` + `money_changed` (contrato `09`), guardado en `save.cfg`.
- HUD label maíz + tienda stub `shop.tscn` (comprar munición luego; hoy solo mostrar).
- Nombres fijos: moneda = `maíz`, wanted = `huevos rotos` (no renombrar luego).

## Armas en mapa (Fase 5 pendiente `sistema_armas.md:150`)

- `scripts/systems/weapons/weapon_pickup.gd` + `scenes/weapons/weapon_pickup.tscn` (`Area2D` capa6 Pickups + Sprite + bob senoidal).
- `E` cerca: `player.equip_weapon(pickup.data)` + dropea anterior como nuevo pickup.
- Spawns: `WeaponSpawns/` de la base, respawn 60s. Catálogo inicial `pistol/assault_rifle/machine_gun.tres`.

## Drops dinero

- `scenes/pickups/money_pickup.tscn` (`Area2D` capa6 + valor).
- `npc.die(killer)`: `spawn_money(randi_range(variant.money_min, variant.money_max))` + `WantedSystem.add_heat(2,"asesinato")` si hay testigos.
- Bala ya daña vehículos y NPCs por igual (`bullet.gd` máscara incluye Vehículos).

## Aceptación

- NPC muerto suelta 1-3 monedas recogibles con E/pisar, HUD suma, rifle del suelo equipable, muerte player muestra `wanted_dead.tscn`.
