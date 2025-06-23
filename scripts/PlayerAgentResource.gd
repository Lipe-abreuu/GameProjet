# =====================================
#  PLAYERAGENTRESOURCE.GD - DADOS DO AGENTE
# =====================================
# IMPORTANTE: Este arquivo deve ser salvo como PlayerAgentResource.gd
class_name PlayerAgentResource
extends Resource

# --- SINAIS ---
signal property_changed(property_name: String, old_value, new_value)

# --- DADOS ---
@export var agent_name: String = "Lautaro Silva"
@export var age: int = 35
@export var ideology: String = "Socialista Reformista"
@export var country: String = "Chile"
@export_range(0, 100) var charisma: int = 50
@export_range(0, 100) var intelligence: int = 50
@export_range(0, 100) var connections: int = 50
@export var wealth: int = 300
@export var political_experience: int = 0
@export var position_level: int = 0

@export var personal_support: Dictionary = {
	"military": 10, "business": 10, "intellectual": 10,
	"worker": 10, "student": 10, "church": 10, "peasant": 10
}

var position_hierarchy = ["Cidadão", "Ativista", "Deputado", "Senador", "Ministro", "Presidente"]

func get_position_name() -> String:
	if position_level >= 0 and position_level < position_hierarchy.size():
		return position_hierarchy[position_level]
	return "Desconhecido"

func get_total_support() -> int:
	var total = 0
	for value in personal_support.values():
		total += value
	return total

func get_average_support() -> float:
	return float(get_total_support()) / personal_support.size()
