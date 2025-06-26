# res://scripts/TraumaSystem.gd
extends Node

var collective_traumas: Dictionary = {}

class CollectiveTrauma:
	var event_name: String
	var trauma_type: String # "political", "economic", "social"
	var intensity: float = 1.0 # O quão forte é o trauma
	var affected_groups: Array
	var trigger_keywords: Array # Palavras que ativam o trauma
	var decay_rate: float = 0.95 # Trauma diminui 5% por ano
	var creation_year: int
	
	func _init(data: Dictionary):
		event_name = data.get("name", "Trauma Desconhecido")
		trauma_type = data.get("type", "political")
		intensity = data.get("intensity", 1.0)
		affected_groups = data.get("affected_groups", [])
		trigger_keywords = data.get("triggers", [])
		creation_year = data.get("year", 1973)

# Cria um novo trauma coletivo
func create_trauma(trauma_name: String, trauma_data: Dictionary):
	if collective_traumas.has(trauma_name):
		return # Não cria o mesmo trauma duas vezes

	var trauma = CollectiveTrauma.new(trauma_data)
	collective_traumas[trauma_name] = trauma
	print("TRAUMA COLETIVO CRIADO: %s" % trauma_name)

# Verifica se uma ação ativa algum trauma e retorna o fator de amplificação
func check_trauma_activation(action_description: String) -> float:
	var total_amplification = 1.0
	for trauma in collective_traumas.values():
		for keyword in trauma.trigger_keywords:
			if keyword in action_description.to_lower():
				var amplification = 1.0 + (trauma.intensity * 0.5)
				total_amplification *= amplification
				print("TRAUMA ATIVADO: '%s' amplificou a reação em %.1fx" % [trauma.event_name, amplification])
	return total_amplification

# Reduz a intensidade dos traumas com o passar dos anos
func process_trauma_decay(current_year: int):
	for trauma_name in collective_traumas:
		var trauma = collective_traumas[trauma_name]
		var years_passed = current_year - trauma.creation_year
		trauma.intensity = pow(trauma.decay_rate, years_passed)
		
		# Remove o trauma se ele ficar muito fraco
		if trauma.intensity < 0.1:
			collective_traumas.erase(trauma_name)
			print("TRAUMA CURADO: %s" % trauma_name)
