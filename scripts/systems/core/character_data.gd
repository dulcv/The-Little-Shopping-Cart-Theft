class_name CharacterData
extends Resource

## Ficha de personaje jugable (docs 03-seleccion-personajes, 09-contratos-interfaces,
## biblia-minima). Fuente de verdad para sprite, vida, velocidad y arma inicial.
## GameManager.selected_character / selected_ids + is_duo la consumen (ver reporte).

@export var id: String = ""
@export var display_name: String = ""
## Como te llaman NPCs y dialogos ("Orale {alias}").
@export var alias_llamado: String = ""
@export var sprite_frames: SpriteFrames
@export var max_hp: int = 100
## Multiplica SPEED 100 / RUN_SPEED 150 de player.gd.
@export var speed_mult: float = 1.0
## pistol.tres por defecto; Edgar arranca con rifle (doc 03).
@export var starting_weapon: WeaponData
@export_multiline var description: String = ""
