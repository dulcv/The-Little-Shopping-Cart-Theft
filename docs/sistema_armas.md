# Documentación del Sistema de Armas y Combate

Este documento describe la arquitectura, especificaciones técnicas y estado de implementación del sistema modular de armas para **The Little Shopping Cart Theft**.

---

## 1. Visión General y Decisiones de Diseño

El sistema de combate está diseñado bajo los siguientes pilares:
1. **Completamente Modular:** El manejo del arma y los proyectiles está desacoplado del script del jugador, permitiendo que cualquier entidad ([Player](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scenes/characters/player/player.tscn), guardias del corral, miembros de bandas enemigas, etc.) use el mismo sistema de armas.
2. **Movimiento y apuntado en 4 direcciones:** el personaje solo se mueve en cruz (arriba/abajo/izquierda/derecha, sin diagonales: si se pulsan dos ejes gana el dominante) y la dirección de disparo se alinea con la dirección de movimiento del teclado (WASD / flechas), manteniendo la memoria del último vector de dirección cuando el personaje se detiene.
3. **Recogida del Suelo (Pickups):** Las armas existen en el mundo como entidades recogibles e intercambiables mediante interacción.
4. **Data-Driven (Recursos Custom):** Nuevas armas pueden crearse simplemente instanciando recursos `.tres` derivados de [`WeaponData`](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scripts/systems/weapons/weapon_data.gd), sin tocar código.

---

## 2. Estructura de Archivos

```
res://
├── assets/sprites/guns/
│   ├── Pistol.png
│   ├── AssaultRifle2.png
│   ├── MachineGun.png
│   └── Extras/
│       ├── Bullet.png
│       ├── Shot.png
│       └── Shell.png
├── docs/
│   └── sistema_armas.md
├── resources/weapons/
│   ├── pistol.tres
│   ├── assault_rifle.tres
│   └── machine_gun.tres
├── scenes/weapons/
│   ├── bullet.tscn
│   ├── weapon.tscn            (Fase 3)
│   └── weapon_pickup.tscn     (Fase 5)
└── scripts/systems/weapons/
    ├── bullet.gd
    ├── weapon_data.gd
    ├── weapon.gd              (Fase 3)
    └── weapon_pickup.gd       (Fase 5)
```

---

## 3. Matriz de Colisiones y Capas de Física 2D

Configuradas en [project.godot](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/project.godot):

| Capa (Layer) | Nombre | Descripción |
| :--- | :--- | :--- |
| **1** | `Mundo` | Paredes, edificios, colisiones del mapa y obstáculos. |
| **2** | `Player` | Personaje controlado por el jugador. |
| **3** | `Enemigos` | NPCs hostiles, guardias del corral, bandas. |
| **4** | `Balas_Player` | Proyectiles disparados por el jugador. Colisionan con `Mundo` y `Enemigos`. |
| **5** | `Balas_Enemigos` | Proyectiles disparados por NPCs/enemigos. Colisionan con `Mundo` y `Player`. |
| **6** | `Pickups` | Armas e ítems interactuables en el suelo. |

---

## 4. Estado de Implementación por Fases

### Fase 1: Capas de Física y Proyectiles (Completada)
* **Archivo de script:** [scripts/systems/weapons/bullet.gd](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scripts/systems/weapons/bullet.gd)
* **Escena del proyectil:** [scenes/weapons/bullet.tscn](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scenes/weapons/bullet.tscn)
* **Características:**
  * Nodo `Area2D` con `Sprite2D` recortado a la región exacta del proyectil (`3x1 px` con textura [Bullet.png](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/assets/sprites/guns/Extras/Bullet.png)).
  * Método `setup(direction, speed, damage, is_enemy)` que inicializa la trayectoria y conmuta las capas de colisión automáticamente para evitar fuego amigo.
  * Interfaz de daño polimórfica: detecta si el cuerpo o área impactada contiene el método `take_damage(amount: int)` y aplica el daño antes de destruirse con `queue_free()`.
  * Límite de tiempo de vida (`max_lifetime`) para evitar proyectiles huérfanos fuera del mapa.

---

### Fase 2: Definición de Armas con Custom Resource (Completada)
* **Archivo de script:** [scripts/systems/weapons/weapon_data.gd](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scripts/systems/weapons/weapon_data.gd)
* **Clase exportable:** `class_name WeaponData extends Resource`
* **Campos configurables:**
  * `id`: Identificador interno (ej. `"pistol"`).
  * `weapon_name`: Nombre visible en pantalla.
  * `sprite` y `sprite_region`: Textura y recorte del arma.
  * `hold_offset`: Punto de sujeción relativo a la mano del personaje.
  * `muzzle_offset`: Punto de salida del cañón donde se instancian balas y fogonazos.
  * `fire_sound`, `fire_volume_db`, `fire_pitch_variation`: Sonido de disparo propio del arma, volumen y variación aleatoria de pitch.
  * `damage`: Daño infligido por impacto.
  * `bullet_speed`: Velocidad lineal del proyectil.
  * `fire_rate`: Intervalo en segundos entre cada disparo.
  * `is_automatic`: Determina si dispara continuo mientras se mantiene presionado el botón.
  * `spread_degrees`: Ángulo de dispersión aleatorio de las balas.
  * `bullets_per_shot`: Cantidad de balas simultáneas (útil para escopetas o ráfagas).
  * `bullet_lifetime`: Duración máxima del proyectil.
  * `max_ammo` y `current_ammo`: Gestión de munición (`-1` = infinita).

#### Catálogo de Armas Iniciales

| Recurso | Tipo | Daño | Cadencia | Automática | Dispersión | Velocidad Bala |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| [pistol.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/pistol.tres) | Semiautomática | 15 | 0.28 s | No | 1.5° | 420 px/s |
| [assault_rifle.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/assault_rifle.tres) | Automática | 10 | 0.14 s | Sí | 3.5° | 460 px/s |
| [machine_gun.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/machine_gun.tres) | Automática Pesada | 8 | 0.08 s | Sí | 7.0° | 490 px/s |

---

### Fase 3: Componente de Arma (`Weapon.tscn` / `weapon.gd`) (Completada)
* **Archivo de script:** [scripts/systems/weapons/weapon.gd](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scripts/systems/weapons/weapon.gd)
* **Escena del componente:** [scenes/weapons/weapon.tscn](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scenes/weapons/weapon.tscn)
* **Características:**
  * **Nodo desacoplado:** Puede agregarse al [Player](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scenes/characters/player/player.tscn) o a cualquier enemigo/NPC sin acoplamiento.
  * **Apuntado por teclado en 4 u 8 direcciones (`set_aim_direction`):** Rota hacia la dirección de movimiento o última dirección registrada.
  * **Corrección de volteo vertical (Flip Y):** Al apuntar hacia la izquierda (`aim_direction.x < 0`), invierte `scale.y = -1.0` para que el sprite del arma y el cañón nunca queden de cabeza.
  * **Fogonazo (`MuzzleFlash`):** Utiliza [Shot.png](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/assets/sprites/guns/Extras/Shot.png) y un `FlashTimer` de 0.05 segundos para retroalimentación visual al disparar.
  * **Sonido de disparo (`FireSound`):** `AudioStreamPlayer2D` con `max_polyphony = 3` para que las ráfagas automáticas se solapen sin cortarse. Cada arma trae su propio `fire_sound` en el `.tres` (`pistol.mp3`, `assaultrifle.mp3`, `machinegun.mp3` en `assets/audio/sfx/guns/`) más `fire_volume_db` y `fire_pitch_variation` (±4 % aleatorio) definidos en [`WeaponData`](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scripts/systems/weapons/weapon_data.gd).
  * **Cadencia y ráfagas:** `CooldownTimer` respeta el `fire_rate` de cada recurso. Permite tanto disparo semiautomático como automático continuo mediante `handle_trigger(is_pressed, is_just_pressed)`.
  * **Control de munición:** Soporta munición infinita (`max_ammo = -1`) o cargadores finitos emitiendo señales reactivas.

---

### Fase 4: Integración en el Jugador y Controles (Completada)
* **Punto de montaje:** Instanciado en [player.tscn](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scenes/characters/player/player.tscn) bajo el nodo `Weapon`.
* **Profundidad Visual Top-Down (`_update_weapon_visual_depth`):**
  * Al caminar/apuntar hacia **arriba** (`last_facing_dir.y < -0.4`), el arma se renderiza detrás de la cabeza y cuerpo del pollo (`weapon.show_behind_parent = true`).
  * Al caminar/apuntar hacia **abajo o los lados**, el arma se dibuja al frente (`show_behind_parent = false`).
* **Alineación dinámica de sujeción (8 direcciones):**
  * Derecha/izquierda: `weapon.position = Vector2(±6.0, 2.0)` (ala/pecho del pollo de 20x21 px, por debajo del pico para no tapar la cara).
  * Arriba: `Vector2(0.0, -3.0)` + `show_behind_parent = true`; Abajo: `Vector2(0.0, 3.0)` al frente.
  * Diagonales: combinan ambos ejes (ej. arriba-derecha = `Vector2(6, -3)`).
* **Arma fijada al cuerpo (`BODY_BOB` + `_apply_weapon_bob`):**
  * El balanceo está dibujado dentro del sprite (idle baja 1 px en frames 2-4, walk/run alternan ±1 px), así que el arma suma el mismo offset Y del frame actual cada tick en `_process` en vez de quedarse en un punto fijo.
  * Tabla medida del arte en `player.gd`: `idle [0,0,1,1,1]`, `walk/run [0,-1,-1,0]`.
* **Agarre según el tamaño del arma (`hold_offset` = empuñadura, no culata):**
  * Pistola (10x6, agarre a 2 px del fondo): `hold_offset = Vector2(3, 2)`, `muzzle = Vector2(9, 0)` → culata de 2 px apenas solapa el borde del ala, punta de 8 px por delante.
  * Rifle (26x6, agarre a 9 px): `hold_offset = Vector2(4, 2)`, `muzzle = Vector2(18, 0)` → culata de 9 px apoyada dentro del cuerpo, punta de 17 px.
  * Ametralladora (26x8, agarre a 10 px): `hold_offset = Vector2(3, 2)`, `muzzle = Vector2(17, 0)`.
  * Fórmula general: `offset = (w/2 - grip, h/2 - gy)`, `muzzle = (w - grip + 1, 0)`. Para añadir un arma nueva, mide a cuántos px del borde trasero está su empuñadura y usa ese `grip`.
* **Lógica unificada de combate (Tecla Espacio):**
  * **Sin arma equipada:** Presionar `Espacio` ejecuta el ataque cuerpo a cuerpo original (`attack`) bloqueando el movimiento temporalmente.
  * **Con arma equipada:** Presionar o mantener `Espacio` acciona el gatillo del arma sin congelar al personaje, permitiendo correr y disparar a la vez.
* **Arma inicial configurable (`starting_weapon`):**
  * Campo exportado en el inspector del [Player](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scenes/characters/player/player.tscn) que inicializa con [pistol.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/pistol.tres) para pruebas inmediatas.
* **Atajos de teclado para pruebas (Debug Hotkeys):**
  * Tecla `1`: Equipa Pistola ([pistol.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/pistol.tres)).
  * Tecla `2`: Equipa Rifle de Asalto ([assault_rifle.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/assault_rifle.tres)).
  * Tecla `3`: Equipa Ametralladora ([machine_gun.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/machine_gun.tres)).
  * Tecla `0`: Desequipa el arma (vuelve a combate melee desarmado).
* **API de intercambio:** Se implementaron los métodos `equip_weapon(data: WeaponData)`, `unequip_weapon() -> WeaponData` y `has_weapon() -> bool` listos para la interacción con los pickups del suelo en la Fase 5.

---

### Fase 5: Sistema de Recogida del Suelo (`WeaponPickup`) (Siguiente fase)
* Escena `WeaponPickup.tscn` (`Area2D` en capa 6: `Pickups`):
  * Muestra el sprite del arma en el suelo con efecto flotante ligero (animación senoidal o tween).
  * Detección por proximidad con el jugador.
  * Al presionar la acción `interact` (tecla `E`), equipa el arma en el jugador y suelta la anterior si existía una equipada.

---

### Fase 6: Sistema de Daño y Reutilización en Enemigos (Pendiente)
* Implementación de método `take_damage(amount)` y barra/contador de vida en personajes.
* Integración del componente `Weapon` en NPCs hostiles ([guardia_corral](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scenes/characters/guardia_corral), etc.).

---

## 5. Registro de Cambios (Changelog)

* **2026-09-18 (Movimiento en 4 direcciones, sin diagonales):**
  * `player.gd` filtra el input a cruz: con dos ejes pulsados se queda el dominante (en empate gana el horizontal). El apuntado del arma hereda las 4 direcciones automáticamente vía `last_facing_dir`.
* **2026-09-18 (Sonido de golpe cuerpo a cuerpo):**
  * Nuevo nodo `MeleeSound` (`AudioStreamPlayer2D` con `hit.mp3`, `max_polyphony = 2`) en `player.tscn`; `player.gd` lo reproduce con pitch aleatorio (±4 %) al iniciar el ataque desarmado.
* **2026-09-18 (Sonidos de disparo por arma):**
  * Se conectaron los mp3 existentes en `assets/audio/sfx/guns/` (`pistol.mp3`, `assaultrifle.mp3`, `machinegun.mp3`) a sus `.tres` vía el nuevo campo `fire_sound` de `WeaponData`.
  * Nuevo nodo `FireSound` (`AudioStreamPlayer2D`, `max_polyphony = 3`) en `weapon.tscn`; `weapon.gd` lo reproduce en cada `shoot()` con volumen y variación de pitch propios del recurso.
* **2026-09-18 (Arma fijada al cuerpo en idle):**
  * El pollo se balancea 1 px dentro de sus propios frames (medido del arte) mientras el arma estaba en posición fija: de ahí la sensación de flotación.
  * `BODY_BOB` en `player.gd` + `_apply_weapon_bob()` cada tick en `_process`: el arma hereda el offset Y del frame actual (`idle [0,0,1,1,1]`, `walk/run [0,-1,-1,0]`).
* **2026-09-18 (Agarre por tamaño: el pollo sujeta cada arma):**
  * El origen de `Weapon` pasa de la culata trasera al punto de empuñadura: cada `.tres` define su `grip` (px desde el borde trasero) según su tamaño, así la culata de los rifles queda apoyada dentro del ala y la pistola apenas solapa el borde.
  * Valores: pistola `hold (3, 2)` / `muzzle (9, 0)`; rifle `hold (4, 2)` / `muzzle (18, 0)`; ametralladora `hold (3, 2)` / `muzzle (17, 0)`.
  * Anclaje lateral bajado a `Y = 2.0` (pecho/ala, verificado con mockup: a `Y = 0` el cañón tapaba el pico y la barbilla).
* **2026-09-18 (Fix alineación de armas en el personaje):**
  * Causa: `hold_offset` se usaba como `Sprite2D.offset` pero con valores que ponían la culata a -7/-21/-23 px del origen en vez de 0, y el `muzzle_offset` quedaba flotando 5-13 px por delante de la punta del cañón (balas y fogonazo aparecían en el aire).
  * Fix en `pistol.tres` (10x6): `hold_offset = Vector2(5, 2)`, `muzzle_offset = Vector2(11, 0)` → arma dibujada en x[0,10], cañón sobre la línea de la mano.
  * Fix en `assault_rifle.tres` (26x6): `hold_offset = Vector2(13, 2)`, `muzzle_offset = Vector2(27, 0)`.
  * Fix en `machine_gun.tres` (26x8): `hold_offset = Vector2(13, 2)`, `muzzle_offset = Vector2(27, 0)`.
  * Regla general documentada en `weapon_data.gd`: con sprite centrado, `offset.x = ancho/2` (culata al origen) y `muzzle = (ancho+1, 0)`; `weapon.gd` ahora fuerza `centered = true`.
  * Anclaje 8-direcciones en `player.gd` (`_update_weapon_visual_depth`): el pollo mide 20x21 px, así que el agarre va en el borde del cuerpo — X: ±6 (lados) / 0 (vertical), Y: -2 (arriba) / 3 (abajo) / 1 (lados) — en vez del fijo `Vector2(±2, 2)`. Default de `player.tscn` actualizado a `Vector2(6, 1)` (mirando derecha).
* **2026-09-16 (Fase 4 - Integración y Pulido del Player):**
  * Se implementó `@export var starting_weapon: WeaponData` y se asignó [pistol.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/pistol.tres) por defecto en [player.tscn](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scenes/characters/player/player.tscn).
  * Se implementó la profundidad visual top-down (`show_behind_parent = true` al mirar arriba, `false` al mirar abajo/lados).
  * Se ajustó el anclaje del arma según la orientación en las alas del pollo (`Vector2(2, 2)` / `Vector2(-2, 2)`).
  * Se añadieron atajos de prueba (`1`, `2`, `3`, `0`) en `_unhandled_input` para probar el cambio de armas y combate desarmado al instante en Godot.
* **2026-09-16 (Fase 3 - Componente de Arma):**
  * Se unificó el control de combate: la tecla **Espacio** ahora ataca cuerpo a cuerpo cuando se está desarmado y dispara proyectiles cuando se tiene un arma equipada.
  * Se creó el script [weapon.gd](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scripts/systems/weapons/weapon.gd) y la escena [weapon.tscn](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scenes/weapons/weapon.tscn).
  * Se implementó el volteo vertical automático para apuntado a la izquierda sin invertir el sprite de cabeza.
* **2026-09-16 (Fases 1 y 2 - Proyectil y Recursos):**
  * Se definieron los nombres oficiales de las capas de física 2D en [project.godot](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/project.godot).
  * Se configuraron las acciones de entrada `shoot` e `interact`.
  * Se implementó el script de proyectil [bullet.gd](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scripts/systems/weapons/bullet.gd) y su escena [bullet.tscn](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scenes/weapons/bullet.tscn).
  * Se implementó el recurso de datos [weapon_data.gd](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/scripts/systems/weapons/weapon_data.gd).
  * Se crearon los recursos iniciales de armas: [pistol.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/pistol.tres), [assault_rifle.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/assault_rifle.tres) y [machine_gun.tres](file:///home/edgarcray/Proyectos/The-Little-Shopping-Cart-Theft/resources/weapons/machine_gun.tres).
  * Se creó la documentación técnica inicial.
