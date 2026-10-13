# 02 — Shader Pollos NPC (Agente-Shader) — v2 sin manchas

> Clonar patrón de `assets/shaders/vehicle_paint.gdshader:1-68` para pollos. Reutilizar `player1_sprite_frames.tres`, NO duplicar sprites.
> NOTA v2: se eliminaron las manchas procedurales a petición de diseño; el shader SOLO tiñe la pluma (igual que los coches). Los campos `spot_*` de `NPCVariant` quedan reservados sin uso.

> Clonar patrón de `assets/shaders/vehicle_paint.gdshader:1-68` para pollos. Reutilizar `player1_sprite_frames.tres`, NO duplicar sprites.

## Objetivo

Un `chicken_variant.gdshader` que tiña la pluma blanca del pollo + añada manchas procedurales, dejando pico/patas/cresta intactos.

## Análisis previo (verificado)

- Base: `ChickenIdle-Sheet.png` etc. 20x21px, pluma blanca/gris clara (alta luminancia, baja saturación).
- Coches usan máscara `blueness = b-max(r,g)` + `saturation_min`. Para pollo invertir: `whiteness = min(r,g,b)` alto + saturación baja.
- `BODY_BOB` en `player.gd:28-38` no se toca; el shader es solo visual.

## Spec del shader `assets/shaders/chicken_variant.gdshader`

```glsl
shader_type canvas_item;
uniform vec4 plume_color : source_color = vec4(1,1,1,1);
uniform float plume_amount : hint_range(0,1) = 1.0;
// excluir pico/naranja: si r domina y g medio -> mask=0
```

- Máscara pluma: `lum>0.75 && sat<0.25`.
- Manchas: `hash(floor(UV*spot_scale)) > (1-spot_amount)` solo donde mask pluma =1.
- Sombreado: mismo truco HSV que `vehicle_paint.gdshader:55-63` (escala S/V relativos).
- Exclusión pico: `if (r>0.8 && g>0.4 && g<0.75 && b<0.4) mask=0`.

## Datos `scripts/systems/npcs/npc_variant.gd` + `resources/npc_data/*.tres`

```gdscript
class_name NPCVariant extends Resource
@export var id: String
@export var plume_color: Color = Color.WHITE
@export var spot_color: Color
@export var spot_amount: float = 0.4
@export var scale_mult: float = 1.0
@export var speed_mult: float = 1.0
@export var max_hp: int = 30
@export var money_min: int = 5
@export var money_max: int = 20
@export var dialogue_pool: Array[String] = []
```

## Escena `scenes/characters/npc/npc.tscn`

Duplicar `player.tscn`, cambiar script a `npc.gd`, en `_ready()`: crear `ShaderMaterial` único, `set_shader_parameter`, `apply_variant(variant)`.

## Aceptación

- 5 variantes en pantalla con mismo `.tres` base y colores/manchas distintos, pico intacto, a 480x270 legible.
- `set_variant()` en runtime sin duplicar textura.
