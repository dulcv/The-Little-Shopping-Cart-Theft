extends Node2D
## Genera colisión de Mundo (capa 1) para cada celda pintada en Houses.
## Por qué existe: el TileSet de Centro define physics_layer_0 en capa 1,
## pero ningún tile de edificios trae polígono de física, así que el
## Vehicle (capa 7, máscara 1+2+4+64) los atraviesa y _detect_crash()
## nunca se dispara. Este nodo crea un StaticBody2D con un rectángulo
## por celda usada, como hijo de Houses para heredar su transform.
## El daño ya lo aplica vehicle.gd: si speed > crash_min_speed hace
## daño, rebote y sonido; aquí solo garantizamos el choque.

@export var houses_path: NodePath = ^"../TilemapLayers/Houses"
## Capa Mundo = bit 0 -> valor 1. El coche la incluye en su mask (71).
@export var mundo_layer: int = 1

func _ready() -> void:
	_build()

func _build() -> void:
	var houses := get_node_or_null(houses_path) as TileMapLayer
	if houses == null:
		push_warning("EdificiosColision: no encontré %s desde %s" % [houses_path, get_path()])
		return
	# Limpia builds previos (por si se reinstancia la escena en caliente).
	var old := houses.get_node_or_null("EdificiosBody")
	if old != null:
		old.queue_free()
	var cells := houses.get_used_cells()
	if cells.is_empty():
		return
	var tile_size := Vector2(16, 16)
	if houses.tile_set != null:
		tile_size = Vector2(houses.tile_set.tile_size)
	var body := StaticBody2D.new()
	body.name = "EdificiosBody"
	body.collision_layer = mundo_layer
	body.collision_mask = 0
	houses.add_child(body)
	for cell in cells:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = tile_size
		shape.shape = rect
		shape.position = houses.map_to_local(cell)
		body.add_child(shape)
