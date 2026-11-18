class_name Accesorio
extends Sprite2D
## Accesorio (sombrero, gorra, lentes...) pegado a la cabeza de un pollo.
## Debe ser hijo de un AnimatedSprite2D con los frames del pollo.
## Sigue el volteo (flip_h), las vistas arriba/abajo y el balanceo de 1 px
## del cuerpo (mismos valores que BODY_BOB de player.gd).

## Posición relativa al centro del sprite cuando mira de lado (hacia la derecha).
@export var lado: Vector2 = Vector2(3, -8)
## Vista de espaldas (animaciones *_up): cabeza arriba al centro.
@export var arriba: Vector2 = Vector2(-1, -8)
## Vista de frente (animaciones *_down): cabeza abajo al centro.
@export var abajo: Vector2 = Vector2(0, 6)
## Lentes, cadena...: solo tienen sentido de lado.
@export var solo_de_lado: bool = false

const BOB := {
	&"idle": [0, 0, 1, 1, 1], &"idle_up": [0, 0, 1, 1], &"idle_down": [0, 0, -1, -1],
	&"walk": [0, -1, -1, 0], &"run": [0, -1, -1, 0],
	&"walk_up": [0, -1, 0, -1], &"run_up": [0, -1, 0, -1],
	&"walk_down": [0, 1, 0, 1], &"run_down": [0, 1, 0, 1],
}

var _padre: AnimatedSprite2D

const CARPETA := "res://assets/sprites/generado/accesorios/"

## Crea y pega un accesorio a un AnimatedSprite2D de pollo.
## Ej: Accesorio.poner($AnimatedSprite2D, "sombrero_detective", Vector2(3, -8))
static func poner(sprite: AnimatedSprite2D, nombre: String, p_lado: Vector2,
		p_solo_de_lado: bool = false) -> Accesorio:
	var ruta := CARPETA + nombre + ".png"
	if sprite == null or not ResourceLoader.exists(ruta):
		return null
	var a := Accesorio.new()
	a.name = nombre.to_pascal_case()
	a.texture = load(ruta)
	a.lado = p_lado
	a.solo_de_lado = p_solo_de_lado
	sprite.add_child(a)
	return a

func _ready() -> void:
	_padre = get_parent() as AnimatedSprite2D
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_actualizar()

func _process(_delta: float) -> void:
	_actualizar()

func _actualizar() -> void:
	if _padre == null:
		return
	var anim := String(_padre.animation)
	var bob := 0
	var tabla: Array = BOB.get(_padre.animation, [])
	if not tabla.is_empty():
		bob = tabla[_padre.frame % tabla.size()]
	if anim.ends_with("_up"):
		visible = not solo_de_lado
		flip_h = false
		position = arriba + Vector2(0, bob)
	elif anim.ends_with("_down"):
		visible = not solo_de_lado
		flip_h = false
		position = abajo + Vector2(0, bob)
	elif anim == "die":
		visible = false
	else:
		visible = true
		flip_h = _padre.flip_h
		position = Vector2(-lado.x if flip_h else lado.x, lado.y + bob)
