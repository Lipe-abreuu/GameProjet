# res://scripts/PartyResource.gd
class_name PartyResource
extends Resource

# DADOS DO PARTIDO
@export var party_name: String = "Frente Popular"
@export var ideology: String = "Socialista"
@export var country: String = "Chile"

# RECURSOS E INFLUÊNCIA
@export var militants: int = 50
@export var treasury: int = 500
@export var influence: float = 5.0

# FASE DE DESENVOLVIMENTO
var _phase: int = 0
var phase_hierarchy = [
	"Grupo Político Informal", "Movimento Político Local", "Partido Emergente",
	"Partido Relevante", "Partido Grande", "Partido Dominante"
]

# APOIO NOS GRUPOS DE INTERESSE
@export var group_support: Dictionary = {
	"military": 0, "business": 0, "intellectuals": 10,
	"workers": 15, "students": 10, "church": 5
}

# FUNÇÕES AUXILIARES
func get_phase_name() -> String:
	if _phase >= 0 and _phase < phase_hierarchy.size():
		return phase_hierarchy[_phase]
	return "Fase Desconhecida"

func get_average_support() -> float:
	if group_support.is_empty(): return 0.0
	var total_support = 0.0
	for support_value in group_support.values():
		total_support += support_value
	return total_support / group_support.size()

func advance_phase():
	if _phase < phase_hierarchy.size() - 1:
		_phase += 1
		print("PARTIDO AVANÇOU PARA A FASE: ", get_phase_name())
