class_name NPCVariant
extends Resource

@export var id: String
@export var plume_color: Color = Color.WHITE
@export var spot_color: Color = Color(0.4, 0.25, 0.15, 1.0)
@export var spot_amount: float = 0.4
@export var scale_mult: float = 1.0
@export var speed_mult: float = 1.0
@export var max_hp: int = 30
@export var money_min: int = 5
@export var money_max: int = 20
@export var dialogue_pool: Array[String] = []
