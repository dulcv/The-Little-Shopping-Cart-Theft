class_name NPCFactions
extends RefCounted

## Tabla de hostilidad 4x4 (doc 05). PLACEHOLDER: solo gallos_negros son
## agresivos; guardia_corral/policia responden si los atacan (vía on_damaged).
## Filas = atacante, columnas = víctima. true = el de la fila ataca al de la columna.

const FACTIONS: Array[String] = ["civil", "gallos_negros", "guardia_corral", "policia"]

# Orden: civil, gallos_negros, guardia_corral, policia
const HOSTILITY: Array = [
	[false, false, false, false],  # civil no ataca a nadie
	[true,  false, true,  true ],  # gallos_negros vs civil/guardia/policia
	[false, true,  false, false],  # guardia_corral responde a gallos
	[false, true,  false, false],  # policia responde a gallos
]

static func _idx(f: String) -> int:
	return maxi(FACTIONS.find(f), 0)

static func is_hostile_to(a: String, b: String) -> bool:
	var row: Array = HOSTILITY[clampi(_idx(a), 0, 3)]
	return bool(row[clampi(_idx(b), 0, 3)])

static func is_law(f: String) -> bool:
	return f == "guardia_corral" or f == "policia"
