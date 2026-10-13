# Plan Maestro — The Little Shopping Cart Theft

> Documento índice para repartir trabajo entre varios agentes IA en paralelo.
> Stack: Godot 4.7 Forward Plus, 480x270 / 1280x720 `canvas_items/expand`, filtro Nearest (`project.godot:75-77`).
> Escena principal actual: `scenes/main/escena_principal.tscn` -> instancia `scenes/world/el_centro/Centro.tscn`.
> Sin Autoloads, sin UI/HUD, sin colisión/nav en Centro. Ver `docs/sistema_armas.md`, `docs/sistema_vehiculos.md`.

## Grafo de dependencias

```
[00 Base] colisiones + nav + autoloads + spawners markers
   ├─> [01 Shader pollo] ─┐
   ├─> [07 Salud base] ───┼─> [04 IA NPCs] ──> [05 Policía huevos] 
   │                       ├─> [06 Diálogos] ─┤
   │                       └─> [02 Selección pj] + [03 Flujo GTA]
   └─> [08 Economía + pickups + drops] (al final, depende de 04+07)
```

## Reparto por agentes (5 carriles paralelizables)

| Carril | Agente | Docs | Requiere | Entrega |
|---|---|---|---|---|
| A Base | Agente-Base | `01-base-bloqueante.md` | nada | Autoloads + Centro con colisión/nav + markers |
| B Visual | Agente-Shader-PJ | `02-shader-pollos.md`, `03-seleccion-personajes.md` | A (parcial) | `chicken_variant.gdshader` + `npc.tscn` + `CharacterData` |
| C Mundo | Agente-IA | `05-ia-npcs-centro.md` | A | `npc.gd` + `npc_spawner.gd` + RoadNetwork |
| D Sistemas | Agente-Sistemas | `06-dialogos.md`, `07-policia-huevos.md`, `08-salud-economia-drops.md` | A, contratos | Dialogue, Wanted, Health, Money, Pickups |
| E Flujo | Agente-UI | `04-flujo-gta.md` | A + contratos | boot/loading/menu/select/pause/hud |

Regla anti-choque: cada agente solo toca su carpeta + su doc. Contratos fijos en `09-contratos-interfaces.md`. No cambiar firmas sin actualizar ese archivo.

## Orden de ejecución

1. A entrega Base (bloqueante, 1-2 sesiones).
2. B+C+D+E arrancan en paralelo leyendo `09-contratos-interfaces.md`.
3. Integración final: spawner + wanted + diálogo + HUD en `Centro.tscn`.

## Definiciones globales

- Capas física `project.godot:61-69`: 1 Mundo, 2 Player, 3 Enemigos, 4 Balas_Player, 5 Balas_Enemigos, 6 Pickups, 7 Vehículos.
- Daño polimórfico: todo lo dañable implementa `take_damage(amount:int)`. Ya lo usan `bullet.gd:69-87` y `vehicle.gd:369`.
- Tamaño pollo 20x21, colisión 18x19 (`player.tscn:13-14`). Coche 30x20 capa7 (`vehicle.tscn:22-24`).
- Ver respuesta historia en `10-historia-vs-base.md`: NO historia completa ahora, SÍ biblia mínima.
