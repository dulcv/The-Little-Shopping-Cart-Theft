class_name CharacterData
extends Resource
## Personaje jugable (contrato de docs/09-contratos-interfaces.md).
## Se elige en la pantalla de selección; player.gd lo aplica en _ready().

@export var id: String = ""
@export var display_name: String = ""
## Cómo te llaman los vecinos en los diálogos: "{alias}" en el texto.
@export var alias_llamado: String = "detective"
@export var sprite_frames: SpriteFrames
## Tinte del sprite (para variantes del pollo base mientras no tengan arte propio).
@export var color: Color = Color.WHITE
## Accesorio de la cabeza (nombre en assets/sprites/generado/accesorios/), "" = ninguno.
@export var accesorio: String = ""
@export var accesorio_lado: Vector2 = Vector2(3, -8)
@export var max_hp: int = 100
@export var speed_mult: float = 1.0
@export var starting_weapon: WeaponData
@export_multiline var description: String = ""
