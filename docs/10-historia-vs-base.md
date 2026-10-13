# 10 — Historia vs Base (respuesta a tu duda)

## Respuesta corta

**No hagas la historia completa ahora. Haz la base + una biblia mínima de 1 página.**

Si haces historia completa (misiones, guion, cinemáticas) antes de la base, la reescribirás cuando choques con límites reales (mapa 480x270, sprites 20x21, sin nav, sin save). Si haces base sin nada de historia, programarás sistemas genéricos que luego no sirven al tono (ej. diálogo sin `{alias}`, policía sin facciones).

## Lo mínimo de historia que SÍ debes fijar ahora

1. **Tono y pilar:** parodia GTA con pollos (ej. "huevos rotos" = estrellas). Fija 3 reglas: humor absurdo, sin gore real, respeto pixel-art.
2. **Protagonistas jugables:** lista cerrada (ej. Edgar, Dulce, Jessi... ya tienes carpetas `Edgar/`, `Dulce/` + radios `dulce/edgar/jessi`). Cada uno: `display_name + alias_llamado + rasgo` (ej. Edgar corre +10% pero lo llaman "El Pelón").
3. **Facciones:** `gallos_negros, guardia_corral, policia_corral` (carpetas ya reservadas). Define hostilidad base entre ellas en tabla 3x3.
4. **Zonas:** El Centro (actual) + Las Lomas + La Federal + Granja Industrial (carpetas ya reservadas). 1 frase por zona.
5. **Economía narrativa:** dinero = maíz/semillas, huevos rotos = wanted. Fija nombres ahora para no renombrar HUD luego.

Eso cabe en `docs/biblia-minima.md` (créalo, 30 líneas). Todo lo demás (misiones, arcos, finales) va después de Fase IA+Policía.

## Por qué este orden

- `CharacterData.alias_llamado` y `DialogueSystem {alias}` necesitan los nombres ya (Fase 2-5).
- `WantedSystem` necesita saber quién es policía vs guardia (Fase 6).
- `npc_variant.dialogue_pool` necesita tono (insultos vs piropos).
- Misiones con triggers necesitan `Zones/` de la base (Fase 0).

## Plan

1. Ahora: crea `biblia-minima.md` (15 min).
2. Luego: base + sistemas con hooks `{alias}`, `faction`, `zone_id` (ya previstos en `09-contratos`).
3. Al final: misiones leen esos hooks, sin reprogramar.
