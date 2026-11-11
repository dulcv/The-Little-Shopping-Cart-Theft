extends Area2D
## NPC con el que se puede hablar: acércate y pulsa E.
## Muestra sus líneas en el ExpedienteHUD (una tras otra) y emite `hablado`.
## Sencillo a propósito: cuando exista el DialogueSystem (docs/06-dialogos.md)
## se puede cambiar _hablar() por DialogueSystem.start_dialogue().

signal hablado(npc_id: String)

@export var npc_id: String = ""
@export var nombre: String = "Vecino"
@export_multiline var lineas: PackedStringArray = PackedStringArray()
@export var segundos_por_linea: float = 3.2

var dentro: bool = false
var ya_hablo: bool = false

@onready var ayuda: Label = $Ayuda

func _ready() -> void:
	body_entered.connect(func(b): if b.is_in_group("player"): dentro = true)
	body_exited.connect(func(b): if b.is_in_group("player"): dentro = false)
	ayuda.visible = false

func _process(_delta: float) -> void:
	ayuda.visible = dentro
	if dentro and Input.is_action_just_pressed("interact"):
		_hablar()

func _hablar() -> void:
	var hud := get_tree().get_first_node_in_group("expediente_hud")
	if hud == null:
		return
	var texto := PackedStringArray()
	for l in lineas:
		texto.append("%s: %s" % [nombre, l])
	hud.mostrar_lineas(texto, segundos_por_linea)
	ya_hablo = true
	hablado.emit(npc_id)
