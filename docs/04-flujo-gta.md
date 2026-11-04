# 04 — Flujo GTA: Boot / Carga / Menús (Agente-UI)

## Flujo

```
boot.tscn (1.5s logo) -> main_menu.tscn -> character_select.tscn -> loading_game.tscn -> escena_principal.tscn (Centro)
                                                              └─> Continuar (SaveManager.load)
pause.tscn (ESC) + wanted_dead.tscn (busted) + hud.tscn (siempre encima)
```

## Archivos

```
scenes/ui/menus/boot.tscn, main_menu.tscn, character_select.tscn, loading_game.tscn, pause.tscn, wanted_dead.tscn
scenes/ui/hud/hud.tscn (CanvasLayer: HP bar, dinero, huevos 0-5, arma actual, mensaje diálogo)
scenes/system/boot_root.tscn (nuevo main_scene, hoy es escena_principal)
scripts/systems/core/scene_loader.gd + ui_manager.gd
```

Cambiar `project.godot:14 run/main_scene` a `boot_root.tscn`. `escena_principal.tscn` pasa a ser nivel cargado async.

## Detalles técnicos

- `loading_game.tscn`: `ResourceLoader.load_threaded_request("res://scenes/main/escena_principal.tscn")` + `progress` -> ProgressBar. Tips rotando.
- Estilo: fondo negro + letras `BoldPixels.ttf` (`assets/fonts/` ya existe), 480x270 escalado.
- `pause.tscn`: `get_tree().paused=true`, `process_mode=ALWAYS` en UI.
- `hud.tscn`: escucha `health_changed, money_changed, wanted_changed` (contratos `09`).

## Aceptación

- F5 abre boot, eliges pj, ves carga con %, apareces en Centro con HUD. ESC pausa.
