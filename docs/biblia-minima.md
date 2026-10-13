# Biblia Mínima (v1 — texto relleno, no final)

> Fijar nombres ahora para no reprogramar. Diálogos reales pendientes: usar `PLACEHOLDER`.

## Agentes (jugables / mencionados)

| ID | Nombre | Rol trama | Alias (como te llaman) | Estado |
|---|---|---|---|---|
| `edgar` | Edgar | Novio, infiltrador | "Gallo" | Jugable |
| `dulce` | Dulce | Novia, hacker muro | "Gallina" | Jugable |
| `ana` | Ana | Contacto AIA (radio) | "Voz" | NPC radio, no jugable v1 |
| `jessi` | Jessi | Soplón Federación | "Pluma" | NPC, no jugable v1 |

Sus radios ya existen: `assets/audio/radio/dulce_radio, edgar_radio, jessi_radio` (falta `anita_radio` que `vehicle_radio.gd` espera — crear carpeta vacía o renombrar a `ana_radio` en Fase Base).

## Modo Dúo Edgar+Dulce (obligatorio v1)

- Selección permite `Edgar`, `Dulce` o `Dúo Edgar+Dulce juntos`.
- Dúo = juegas como Edgar a pie/coche, Dulce como compañera IA que te sigue (`FOLLOW`), hackea libretas (minijuego auto 3s en v1) y comenta por radio con `PLACEHOLDER`.
- Si uno cae, el otro lo levanta en 5s (revivir). Sin Game Over hasta que caen los dos.
- `GameManager`: `selected_ids: Array[String]`, `is_duo: bool`, `companion_id`.

## Facciones (tabla hostilidad v1)

- `civil`, `guardia_corral` (policía local), `federacion` (blindados), `gallos_negros` (banda).
- Guardia vs Federación: se toleran salvo que el player suba ambas alertas (entonces colaboran).
- Gallos vs todos menos civiles.

## Zonas (1 frase)

- El Centro (actual, funcional), Las Lomas (residencial), La Federal (cuarteles), Granja Industrial (repartos/emboscadas).

## Economía narrativa

- Dinero = `maíz`. Wanted policial = `huevos rotos` (0-5). Alerta Federación = `plumas negras` (0-5). Evidencia = `pruebas`.
