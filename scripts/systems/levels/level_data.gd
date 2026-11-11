class_name LevelData
extends Resource
## Un nivel del caso "Operación Mazorca".
## El nivel se completa cuando el jugador junta TODAS las pistas_requeridas
## (o cuando la escena llama CaseManager.completar_nivel(), p.ej. al vencer al jefe).

@export var id: String = ""
@export var titulo: String = ""
@export_multiline var objetivo: String = ""
@export var zona_id: String = ""
## Ruta a la escena del nivel. Se usa String (no PackedScene) para que un
## nivel cuya zona aún no existe no rompa la carga del recurso.
@export_file("*.tscn") var escena: String = ""
@export var pistas_requeridas: Array[String] = []
