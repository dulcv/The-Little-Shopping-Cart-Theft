# 06 — Diálogos (Agente-Sistemas)

## Archivos

- `scripts/systems/dialogue/dialogue_data.gd` (`class_name DialogueData extends Resource`: `id, lines: Array[DialogueLine]` con `speaker/text/emotion`).
- `resources/dialogos/saludo_civil.json`, `insulto_gallos.json`, `alto_policia.json`, `discusion_choque.json` (empieza con 4).
- `scenes/ui/hud/dialogue_box.tscn` (`Panel + NameLabel + TextLabel typewriter + Hint "E"`).
- `scripts/systems/dialogue/dialogue_system.gd` (CanvasLayer singleton o Autoload): `start_dialogue(id, talker_name)`, cola, `E` avanza, congela NPC (`npc.frozen=true`) y player input mientras activo. Señal `dialogue_finished`.

## Integración

- NPC: `E` cerca + `IDLE/WANDER` -> `DialogueSystem.start_dialogue(npc.dialogue_id, npc.display_name)`.
- Sustitución: `{alias}` -> `GameManager.selected_character.alias_llamado`, `{zona}` -> `GameManager.current_zone`.
- Ejemplo línea: `"¿Qué haces por El Centro, {alias}?"`.

## Aceptación

- Acercarte + E abre caja, texto letra por letra con BoldPixels, E cierra, emite `dialogue_finished`.
