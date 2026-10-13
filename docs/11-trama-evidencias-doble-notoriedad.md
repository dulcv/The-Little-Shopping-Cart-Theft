# 11 — Trama: Evidencias + Muro + Doble Notoriedad (NO cambia objetivos 00-10)

> Traduce tu resumen a datos/sistemas. Todo texto visible = `PLACEHOLDER_*` hasta que escribas diálogos.

## 1. Gameplay Loop (ya compatible con plan 00-10)

Exploración (radio Ana/AIA) -> Evidencia (infiltración/persecución/sigilo) -> Muro de Pruebas (grafo) -> Intervención Táctica (captura). Repetir por distrito.

## 2. Sistema de Evidencias (`EvidenceData`)

```gdscript
# scripts/systems/evidence/evidence_data.gd, class_name EvidenceData extends Resource
enum Kind { CASSETTE, LEDGER, PHOTO, FLIGHT_LOG }
@export var id: String
@export var kind: int
@export var title: String = "PLACEHOLDER_titulo"
@export var description: String = "PLACEHOLDER_descripcion"
@export var district: String = "el_centro"
@export var unlocks_mission: String = ""  # mission_id que habilita
```

Efectos por tipo (contrato para Agente-Sistemas):

| Tipo | Efecto al conseguirla |
|---|---|
| `CASSETTE` | Reproduce audio + revela `SafehouseMarker` en mapa (.coords) |
| `LEDGER` | Minijuego descifrado numérico (v1: mantener E 3s) -> `Guardia.agresividad[distrito] -= 1` |
| `PHOTO` | Quita `inmunidad` a `target_id` -> habilita misión captura |
| `FLIGHT_LOG` | Muestra `TruckRoute` (Path2D + horarios) para emboscada |

Escena: `evidence_pickup.tscn` (`Area2D` capa6, como `weapon_pickup` del doc 08). Inventario: `EvidenceWall` (`Dictionary id->EvidenceData` en `GameManager` + UI grafo simple con nodos conectados).

## 3. Doble Notoriedad (extiende doc 07 sin romperlo)

```gdscript
# wanted_system.gd amplía:
var guardia_level: int = 0  # huevos rotos 0-5 (existente wanted_level -> renombrar)
var federacion_level: int = 0  # plumas negras 0-5 (nuevo)
signal guardia_changed(n); signal federacion_changed(n)
func add_guardia(n, reason)  # tránsito, disparos vía pública, invadir comisaría
func add_federacion(n, reason)  # robar camión pienso, atacar granero
```

- Guardia: patrullas `patrulla.tres` + bloqueos (doc 07 tal cual).
- Federación: `blindado.tres` (nuevo, más HP/lento) + matones armados. En v1 reutilizar `sedan` con `paint negro + HPx2` como placeholder.
- Decaimiento independiente por variable. `WantedClearZone` solo baja guardia; federación baja con soborno (tienda) o tiempo largo.

## 4. Misiones mínimas v1 (sin cinemáticas)

`mission_id`: `tutorial_radio` (escucha cassette) -> `ledger_centro` -> `photo_gallo` -> `emboscada_pienso` -> `captura_intervencion`. Cada una: `requisito_evidencia + zona + objetivo (llega/roba/foto) + recompensa maíz`. Datos en `resources/missions/*.tres`, lógica en `mission_manager.gd` (señales `mission_unlocked/completed`).

## 5. Qué NO hacer aún

Nada de guion final, cinemáticas ni voces. Todo `PLACEHOLDER`. No modificar objetivos 00-10: evidencias y doble alerta se montan SOBRE salud/economía/IA/policía ya planeados.
