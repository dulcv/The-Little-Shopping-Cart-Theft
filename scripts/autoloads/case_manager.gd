extends Node
## Autoload "CaseManager": progreso del caso (niveles + pistas).
## No toca salud, dinero ni wanted (eso es de GameManager/WantedSystem).

signal pista_obtenida(pista_id: String, texto: String)
signal nivel_iniciado(nivel: LevelData)
signal nivel_completado(nivel: LevelData)
signal caso_resuelto

## Orden de los niveles del caso.
const NIVELES: Array[String] = [
	"res://resources/niveles/nivel_01_centro.tres",
	"res://resources/niveles/nivel_02_lomas.tres",
	"res://resources/niveles/nivel_03_granja.tres",
	"res://resources/niveles/nivel_04_federal.tres",
	"res://resources/niveles/nivel_05_jefe.tres",
]

## Texto que se muestra al recoger cada pista (expediente del detective).
const TEXTO_PISTAS := {
	"pluma_dorada": "Una pluma dorada. Solo un gallo en la ciudad tiene plumas así...",
	"ticket_maiz": "Ticket: 4 toneladas de maíz pagadas en efectivo. ¿Quién compra tanto?",
	"foto_kiko": "Foto del agente Kiko Cacareña. Fue visto por última vez en Las Lomas.",
	"invitacion_fiesta": "Invitación a la fiesta de Don Crestón. Código de vestimenta: plumas.",
	"grabacion_microfono": "Grabación: Kiko está en el Rancho Maizal... y un comandante cobra cada viernes.",
	"mapa_rancho": "Mapa del Rancho Maizal, escondido detrás de la Granja Industrial.",
	"foto_plantio": "Fotos del plantío: toneladas de maíz ilegal... y la placa del agente Kiko tirada en el suelo.",
	"escape_rancho": "¡Escapaste del Rancho Maizal con las pruebas!",
	"placa_policia": "Placa del corral tirada junto a la camioneta de los Gallos Negros. El número está rayado...",
	"libreta_pagos": "Libreta de sobornos: 'Viernes: sobre para el comandante'. No dice cuál...",
	"soplon_acusado": "¡El comandante Espolón confesó! Don Crestón se esconde en su bodega del puerto.",
	"confesion_creston": "Don Crestón confesó. ¡Caso cerrado!",
}

var nivel_index: int = 0
var nivel_actual: LevelData = null
var pistas: Array[String] = []

func _ready() -> void:
	nivel_actual = _cargar(nivel_index)

func tiene_pista(pista_id: String) -> bool:
	return pista_id in pistas

func agregar_pista(pista_id: String) -> void:
	if tiene_pista(pista_id):
		return
	pistas.append(pista_id)
	guardar()
	pista_obtenida.emit(pista_id, TEXTO_PISTAS.get(pista_id, pista_id))
	if _nivel_cumplido():
		completar_nivel()

## Pistas del nivel actual que faltan.
func pistas_faltantes() -> Array[String]:
	var faltan: Array[String] = []
	if nivel_actual:
		for p in nivel_actual.pistas_requeridas:
			if not tiene_pista(p):
				faltan.append(p)
	return faltan

func completar_nivel() -> void:
	if nivel_actual == null:
		return
	nivel_completado.emit(nivel_actual)
	if nivel_index >= NIVELES.size() - 1:
		caso_resuelto.emit()
		return
	# Entre nivel y nivel, el detective vuelve a su cochera a ordenar el caso.
	nivel_index += 1
	nivel_actual = _cargar(nivel_index)
	guardar()
	nivel_iniciado.emit(nivel_actual)
	ir_a_cochera()

## La cochera secreta del detective: cuartel entre niveles.
func ir_a_cochera() -> void:
	var juego := get_node_or_null("/root/Juego")
	if juego == null:
		ir_a_nivel(nivel_index)
		return
	var sub := "Siguiente: Nivel %d - %s" % [nivel_index + 1, nivel_actual.titulo] if nivel_actual else ""
	juego.ir_a_escena(juego.COCHERA, "La Cochera", sub)

func ir_a_nivel(index: int) -> void:
	var data := _cargar(index)
	if data == null:
		return
	nivel_index = index
	nivel_actual = data
	guardar()
	nivel_iniciado.emit(data)
	if data.escena.is_empty() or not ResourceLoader.exists(data.escena):
		push_warning("CaseManager: el nivel '%s' aún no tiene escena (%s)" % [data.id, data.escena])
		return
	var juego := get_node_or_null("/root/Juego")
	if juego:
		juego.ir_a_escena(data.escena, "Nivel %d: %s" % [index + 1, data.titulo], data.objetivo)
	else:
		get_tree().call_deferred("change_scene_to_file", data.escena)

func reiniciar_caso() -> void:
	pistas.clear()
	nivel_index = 0
	nivel_actual = _cargar(0)
	guardar()
	ir_a_cochera()

# --- Guardado (user://partida.json) -------------------------------------------

const RUTA_GUARDADO := "user://partida.json"

func guardar() -> void:
	var f := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if f:
		var juego := get_node_or_null("/root/Juego")
		var pj_id: String = juego.personaje.id if juego and juego.personaje else "detective"
		f.store_string(JSON.stringify({"nivel_index": nivel_index, "pistas": pistas, "personaje": pj_id}))

func hay_partida() -> bool:
	return FileAccess.file_exists(RUTA_GUARDADO)

## Carga la partida guardada y abre su nivel. Devuelve false si no había.
func continuar() -> bool:
	if not hay_partida():
		return false
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_GUARDADO))
	if typeof(datos) != TYPE_DICTIONARY:
		return false
	pistas.clear()
	for p in datos.get("pistas", []):
		pistas.append(str(p))
	var juego := get_node_or_null("/root/Juego")
	if juego:
		juego.set_personaje_por_id(str(datos.get("personaje", "detective")))
	nivel_index = clampi(int(datos.get("nivel_index", 0)), 0, NIVELES.size() - 1)
	nivel_actual = _cargar(nivel_index)
	ir_a_cochera()
	return true

func borrar_partida() -> void:
	if hay_partida():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_GUARDADO))

func _nivel_cumplido() -> bool:
	return nivel_actual != null and not nivel_actual.pistas_requeridas.is_empty() \
		and pistas_faltantes().is_empty()

func _cargar(index: int) -> LevelData:
	if index < 0 or index >= NIVELES.size():
		return null
	return load(NIVELES[index]) as LevelData

## Llamar desde el _ready() de cada escena de nivel. Si la escena se abrió
## directo (F6 en el editor), alinea el progreso con esa zona sin recargarla.
func sincronizar_con_zona(zona_id: String) -> void:
	if nivel_actual and nivel_actual.zona_id == zona_id:
		return
	for i in NIVELES.size():
		var data := _cargar(i)
		if data and data.zona_id == zona_id:
			nivel_index = i
			nivel_actual = data
			nivel_iniciado.emit(data)
			return
