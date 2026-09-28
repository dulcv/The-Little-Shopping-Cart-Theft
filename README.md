# The Little Shopping Cart Theft

Juego 2D Top-Down en **Godot 4.7 (Forward Plus)**. Controlas a un pollo en un mundo abierto por zonas (`El Centro`, `Las Lomas`, `La Federal`, `Granja Industrial`) con combate con armas de fuego, cuerpo a cuerpo y, próximamente, vehículos conducibles, NPCs y sistema de daño.

Escena principal: `scenes/main/escena_principal.tscn`.

## Requisitos

- Godot 4.7+ (renderer Forward Plus, `rendering_device/driver.windows="d3d12"`).
- Resolución: viewport `480x270`, ventana `1280x720`, stretch `canvas_items / expand`.
- Filtro de texturas: `Nearest` (`default_texture_filter=0`) para pixel-art.
- Export actual: solo PC. `export_presets.cfg` sí se versiona (ver `.gitignore`).

## Estructura del proyecto

```
res://
├── assets/
│   ├── audio/sfx/guns/      # pistol.mp3, assaultrifle.mp3, machinegun.mp3, hit.mp3
│   ├── audio/music/         # (reservado)
│   ├── audio/radio/         # (reservado, para vehículos)
│   ├── sprites/characters/player/  # ChickenIdle/Walking/Attack/Damage/Die/Jumping
│   ├── sprites/guns/        # Pistol.png, AssaultRifle2.png, MachineGun.png, Extras/
│   ├── sprites/tiles/el_centro/    # carretera.png, piedra.png, tierra.png
│   ├── sprites/vehicles/    # (reservado, vacío)
│   └── sprites/props, ui/   # (reservados)
├── data/                    # (reservado, partidas/guardado)
├── docs/
│   └── sistema_armas.md     # especificación técnica del combate
├── resources/
│   ├── weapons/             # pistol.tres, assault_rifle.tres, machine_gun.tres
│   ├── items, npc_data, dialogos/  # (reservados)
├── scenes/
│   ├── characters/player/   # player.tscn, player.gd, player1_sprite_frames.tres
│   ├── characters/npc, guardia_corral/  # (reservados)
│   ├── weapons/             # weapon.tscn, bullet.tscn
│   ├── vehicles/            # (reservado, vacío - sistema planificado)
│   ├── world/el_centro/Centro.tscn  # único mapa funcional actual
│   ├── world/las_lomas, la_federal, granja_industrial/  # (reservados)
│   ├── ui, minijuegos, main/escena_principal.tscn
└── scripts/systems/weapons/ # weapon_data.gd, weapon.gd, bullet.gd
```

## Controles

| Acción | Input | Notas |
| :--- | :--- | :--- |
| Moverse | WASD / Flechas (`ui_*`) | 4 direcciones, sin diagonales (gana eje dominante, empate = horizontal) |
| Correr | Doble-tap dirección (< 0.3 s) | `SPEED 100`, `RUN_SPEED 150` |
| Atacar / Disparar | Espacio (`attack` + `shoot`) o Click izq. (`shoot`) | Sin arma: melee. Con arma: gatillo (`handle_trigger`) |
| Interactuar | `E` (`interact`) | Reservado para pickups (Fase 5) y entrar a vehículos |
| Debug armas | `1` Pistola, `2` Rifle, `3` Ametralladora, `0` Desarmar | En `player.gd::_unhandled_input` |

## Capas de física 2D (`project.godot`)

| Capa | Nombre | Colisiona con |
| :--- | :--- | :--- |
| 1 | `Mundo` | Paredes, TileMap, obstáculos |
| 2 | `Player` | Personaje (`CharacterBody2D` 18x19) |
| 3 | `Enemigos` | NPCs hostiles (reservado) |
| 4 | `Balas_Player` | Mundo + Enemigos |
| 5 | `Balas_Enemigos` | Mundo + Player |
| 6 | `Pickups` | Armas/items del suelo (Fase 5) |
| 7 | `Vehiculos` | **Planificada**: Mundo + Player + Enemigos + Vehiculos |

## Sistema de combate (Fases 1-4 completadas)

Arquitectura modular, desacoplada del jugador. Ver detalle en `docs/sistema_armas.md`.

- **`WeaponData` (`scripts/systems/weapons/weapon_data.gd`, `class_name WeaponData extends Resource`):** define cada arma por `.tres` sin tocar código: `sprite/sprite_region/hold_offset/muzzle_offset`, `damage/bullet_speed/fire_rate/is_automatic/spread/bullets_per_shot/bullet_lifetime`, `max_ammo/current_ammo (-1=infinita)`, `fire_sound/fire_volume_db/fire_pitch_variation`.
- **`Weapon` (`weapon.gd` + `scenes/weapons/weapon.tscn`):** nodo `Node2D` reutilizable en jugador/NPCs. `set_aim_direction()`, flip vertical, `CooldownTimer` por cadencia, `MuzzleFlash` 0.05 s, `FireSound` (`max_polyphony=3`, pitch aleatorio ±4%).
- **`Bullet` (`bullet.gd` + `bullet.tscn`):** `Area2D` 4x2, `setup(dir, speed, damage, is_enemy)` que conmuta capas para evitar fuego amigo, daño polimórfico vía `take_damage(amount)`, `max_lifetime` anti-huérfanos.
- **Integración jugador (`player.gd`):** `starting_weapon` exportable (Pistola por defecto), anclaje por dirección + `BODY_BOB` por frame para que el arma no flote, `show_behind_parent=true` al mirar arriba, API `equip_weapon()/unequip_weapon()/has_weapon()`, `take_damage()` como stub para Fase 6.

### Catálogo actual

| Arma | Daño | Cadencia | Auto | Dispersión | Bala |
| :--- | :---: | :---: | :---: | :---: | :--- |
| Pistola | 15 | 0.28 s | No | 1.5° | 420 px/s |
| Rifle de Asalto | 10 | 0.14 s | Sí | 3.5° | 460 px/s |
| Ametralladora | 8 | 0.08 s | Sí | 7.0° | 490 px/s |

Añadir un arma = duplicar un `.tres`, cambiar sprite/stats/sonido, medir `grip` (px del borde trasero a la empuñadura) -> `hold_offset=(w/2-grip, h/2-gy)`, `muzzle=(w-grip+1, 0)`.

## Jugador

`CharacterBody2D` + `AnimatedSprite2D` (pollo 20x21 px aprox) + `Weapon` + `MeleeSound (hit.mp3)` + `Camera2D` (smoothing 8.0).
Animaciones en `player1_sprite_frames.tres`: `idle (5f), walk (4f), run (4f), attack (3f, no loop), damage, die`.

## Mundos

Solo `world/el_centro/Centro.tscn` es funcional: `TileMapLayer Background` (carretera/piedra/tierra) + `Player` instanciado. `las_lomas, la_federal, granja_industrial` reservados con `.gitkeep`.

## Audio actual

`assets/audio/sfx/guns/`: `pistol.mp3, assaultrifle.mp3, machinegun.mp3, hit.mp3` ya cableados a sus `.tres` / `MeleeSound`.
`assets/audio/sfx/auto/`: `abrir_puerta, choque, claxon, pip_pip, encendido, encendido2, reversa, sirena_policias` cableados a `vehicle.tscn` + `resources/vehicles/*.tres`.
`assets/audio/radio/`: 4 estaciones (`anita_radio, dulce_radio, edgar_radio, jessi_radio`), cada carpeta = una estación; `VehicleRadio` las escanea en runtime. `music/` reservado.

## Roadmap

- [x] Fase 1-4: balas, `WeaponData`, `Weapon`, integración jugador.
- [ ] Fase 5: `WeaponPickup` (Area2D capa 6, sprite flotante, `E` para equipar/soltar).
- [ ] Fase 6: `take_damage()` + vida en jugador/NPCs, `Weapon` en enemigos.
- [ ] **Vehículos (en curso):** `VehicleData.tres` + `vehicle.tscn/gd` (`CharacterBody2D`, sprite `AnimatedSprite2D` con `coche_azul_sprite_frames`: avanzar/retroceder/humo/crítico/explosión; patrulla/camioneta reutilizan la azul teñida hasta tener textura propia), entrar/salir con `E`, conductor jugador/NPC, daño por choques (`velocity` + `get_slide_collision`) y por armas (`take_damage`), niveles (OK/Humo/Crítico/Destruido), sonidos reales (`sfx/auto/`) + claxon (`H`) + sirena en patrulla, radio de 4 estaciones (`R` cambia estación, ver `vehicle_radio.gd`). Controles de prueba en `test_vehicles.tscn`.

## Cómo ejecutar y probar

1. Abrir en Godot 4.7, escena principal `escena_principal.tscn`, `F5`.
2. Moverse con WASD, correr con doble-tap, Espacio para atacar/disparar, `1/2/3/0` para cambiar de arma.
