# 12 — Juego completo: flujo, arte, música y exportación

## Flujo

`menu_principal.tscn` (escena de inicio) → **Nuevo caso** → `seleccion_personaje.tscn` → **La Cochera** → nivel 1 →
Cochera → nivel 2 → … → jefe → `final.tscn` (créditos). **Continuar caso** te deja en la Cochera con tu personaje.

> Si el juego arranca directo en el Centro, el editor sobrescribió `run/main_scene`. Usa **Proyecto → Recargar proyecto
> actual** (o cierra y abre Godot) después de hacer pull, y revisa *Proyecto → Configuración → Run → Main Scene*.

| Autoload | Qué hace |
|---|---|
| `CaseManager` | Pistas, niveles y guardado en `user://partida.json` |
| `Juego` | Fundidos con cartel de nivel, pausa (Esc), game over (Enter = reintentar), créditos al resolver el caso |
| `Musica` | Una pista por escena con fundido; baja el volumen al ir en coche para que se oiga la radio |

El jugador ya tiene vida (`player.gd`: `take_damage`, `heal`, `is_dead`, señales `health_changed` y `died`), que se ve en la barra del HUD.

## Arte

- `tools/generar_arte.py` (Python + Pillow) genera `assets/sprites/generado/`:
  - `tiles/`: recortes de los atlas del Centro (pasto, tierra, asfalto, piedra, banqueta) y tiles nuevos (madera, mosaico, alfombras, ladrillo, lámina, maíz, surcos, cerca, arena...).
  - `props/`: muebles y objetos (mesa, escritorio, planta, granero, silo, tractor, tablero, lupa...).
  - `accesorios/`: sombrero del detective, gorras, pañuelo y lentes, sombrero y cadena de oro, gorritos de fiesta, moño.
  - Para cambiar un color o un dibujo, edita el script y vuelve a correrlo: `python tools/generar_arte.py`.
- `scripts/characters/accesorio.gd`: `Accesorio.poner(sprite, "gorra_policia", Vector2(3, -7))` pega un accesorio a la cabeza
  de un pollo. Sigue el volteo, las vistas arriba y abajo y el balanceo del cuerpo.
- Para reemplazar el arte generado por arte hecho a mano, sobrescribe el `.png` con el mismo nombre y tamaño.

## Personajes (`resources/characters/*.tres`, clase `CharacterData`)

Detective Pollo, Edgar (sprites propios en `resources/characters/edgar_sprite_frames.tres`), Dulce, Jess y Ana.
Dulce, Jess y Ana usan el pollo base con color y accesorio propios **hasta que tengan sus sprites**: para ponerlos, crea un
SpriteFrames como el de Edgar (mismas animaciones: idle, walk, run, *_up, *_down, attack, damage, die) y asígnalo en
`sprite_frames` de su `.tres`; pon `color` en blanco y `accesorio` vacío si su arte ya trae su look.
Cada uno cambia vida, velocidad y arma inicial. En los diálogos, `{alias}` se reemplaza por su nombre.

## La Cochera (`scenes/world/cochera/Cochera.tscn`)

Cuartel secreto del detective encubierto. El tablero muestra los niveles resueltos (E = leer el expediente con todas las
pistas) y la cortina del garage (mantén E) lleva al siguiente nivel. Tiene su propio coche con radio.

## Armas y jefe

Teclas: 1 Pistola, 2 Rifle, 3 Ametralladora, **4 Lanzahuevos** (arma del detective: dispara huevos). Don Crestón solo recibe
hasta un 25% de su vida por cada aturdimiento (`dano_max_por_aturdimiento`): hay que estrellarlo al menos 4 veces con
cualquier arma. La radio del coche se muestra en pequeño en la esquina del HUD mientras manejas.

## Vida del Centro (nivel 1)

`scenes/world/el_centro/VidaCentro.tscn` (instanciada en `Centro.tscn`) agrega lo que el nivel necesitaba para seguir el mismo
estándar que los demás: vecinos con los que se habla con E (Doña Pechuga, Don Elotero, Panadero Bolillo, Jardinero Pasto y
Sra. Cocorota; cada uno guía hacia una pista), peatones que también platican, macetas, bancas y el puesto de elotes.
El jugador ahora aparece en la calle de las tiendas, con su coche estacionado al lado.

## Música

Juhani Junkala, CC0 (ver `CREDITOS_MUSICA.txt`). Archivos en `assets/audio/music/`; el mapeo de escena a pista está en
`scripts/autoloads/musica.gd` (`POR_ESCENA`).

## Exportar a Windows (.exe)

1. En Godot: **Editor → Administrar plantillas de exportación → Descargar e instalar** (solo una vez, ~1 GB).
2. **Proyecto → Exportar → "Windows Desktop" → Exportar proyecto**. El preset ya está en `export_presets.cfg`
   y genera `builds/OperacionMazorca.exe` (un solo archivo, con el .pck incluido; `builds/` está en .gitignore).

Desde la terminal: `godot --headless --path . --export-release "Windows Desktop" builds/OperacionMazorca.exe`
