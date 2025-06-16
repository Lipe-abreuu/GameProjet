# =====================================
#  PLAYERAGENT.GD - VERSÃO SIMPLES FUNCIONAL
#  Sistema de agente político sem erros
# =====================================
class_name PlayerAgent
extends Resource

# =====================================
#  SINAIS
# =====================================
signal support_changed(group: String, old_value: int, new_value: int)
signal position_advanced(old_position: String, new_position: String)

# =====================================
#  ENUM (NOVA ADIÇÃO!)
# =====================================
enum Position {
	CITIZEN = 0,
	ACTIVIST = 1,
	LOCAL_LEADER = 2,
	DEPUTY = 3,
	SENATOR = 4,
	MINISTER = 5,
	PRESIDENT = 6
}

# =====================================
#  CONSTANTES
# =====================================
const POSITION_NAMES = ["Cidadão", "Ativista", "Líder Local", "Deputado", "Senador", "Ministro", "Presidente"]
const SUPPORT_REQUIREMENTS = [0, 50, 100, 150, 200, 250, 300]

# =====================================
#  DADOS BÁSICOS
# =====================================
@export var agent_name: String = ""
@export var age: int = 30
@export var country: String = ""
@export var background: String = ""
@export var ideology: String = ""

# Status político (agora usando o ENUM Position)
@export var current_position: Position = Position.CITIZEN # Usando o enum agora
@export var months_in_position: float = 0.0
@export var political_experience: int = 0
@export var in_power: bool = false

# Atributos pessoais (0-100)
@export var charisma: int = 50
@export var intelligence: int = 50
@export var connections: int = 50
@export var wealth: int = 50
@export var military_knowledge: int = 50

# Apoio por grupos (0-100)
@export var military_support: int = 0
@export var business_support: int = 0
@export var intellectual_support: int = 0
@export var worker_support: int = 0
@export var student_support: int = 0
@export var church_support: int = 0
@export var peasant_support: int = 0

# Influências internacionais (0-100)
@export var usa_influence: int = 0
@export var ussr_influence: int = 0

# Status especiais
@export var is_in_exile: bool = false
@export var is_underground: bool = false
@export var is_imprisoned: bool = false
@export var condor_threat_level: int = 0

# Dados históricos
@export var major_events: Array[String] = []

# =====================================
#  PROPRIEDADES COMPUTADAS
# =====================================
var total_support: int:
	get:
		return (military_support + business_support + intellectual_support +
				worker_support + student_support + church_support + peasant_support)

var position_name: String:
	get:
		# Garante que o índice é válido para POSITION_NAMES
		if current_position >= 0 and current_position < POSITION_NAMES.size():
			return POSITION_NAMES[current_position]
		return "Desconhecido"

var can_advance: bool:
	get:
		var next_pos_index = current_position + 1
		if next_pos_index >= SUPPORT_REQUIREMENTS.size():
			return false # Já está na última posição ou índice inválido
		return total_support >= SUPPORT_REQUIREMENTS[next_pos_index]

# =====================================
#  INICIALIZAÇÃO
# =====================================
func _init(p_name: String = "", p_country: String = "", p_background: String = "", p_ideology: String = ""):
	if not p_name.is_empty():
		agent_name = p_name
	if not p_country.is_empty():
		country = p_country
	if not p_background.is_empty():
		background = p_background
		apply_background_modifiers()
	if not p_ideology.is_empty():
		ideology = p_ideology
		apply_ideology_modifiers()

# =====================================
#  MODIFICADORES
# =====================================
func apply_background_modifiers() -> void:
	match background:
		"Militar":
			military_knowledge += 30
			connections += 15
			military_support += 25
			business_support += 10
			worker_support = max(0, worker_support - 15)
			student_support = max(0, student_support - 10)
			
		"Intelectual":
			intelligence += 25
			charisma += 15
			intellectual_support += 30
			student_support += 15
			military_support = max(0, military_support - 10)
			business_support += 5
			
		"Sindicalista":
			charisma += 20
			connections += 10
			worker_support += 35
			peasant_support += 15
			business_support = max(0, business_support - 25)
			military_support = max(0, military_support - 15)
			
		"Empresário":
			wealth += 30
			intelligence += 15
			connections += 10
			business_support += 30
			worker_support = max(0, worker_support - 20)
			student_support = max(0, student_support - 10)
			
		"Estudante":
			charisma += 15
			intelligence += 10
			wealth = max(0, wealth - 15)
			student_support += 25
			intellectual_support += 15
			worker_support += 10
	
	_clamp_all_values()

func apply_ideology_modifiers() -> void:
	match ideology:
		"DSN": # Doutrina de Segurança Nacional
			military_knowledge += 20
			usa_influence += 15
			military_support += 20
			business_support += 15
			worker_support = max(0, worker_support - 25)
			student_support = max(0, student_support - 20)
			condor_threat_level = max(0, condor_threat_level - 10)
			
		"Neoliberal":
			intelligence += 15
			wealth += 20
			usa_influence += 10
			business_support += 25
			intellectual_support += 10
			worker_support = max(0, worker_support - 15)
			peasant_support = max(0, peasant_support - 10)
			
		"Social-Democrata":
			charisma += 15
			connections += 10
			intellectual_support += 15
			worker_support += 15
			church_support += 5
			
		"Marxista":
			intelligence += 15
			charisma += 10
			ussr_influence += 20
			worker_support += 30
			student_support += 20
			peasant_support += 15
			business_support = max(0, business_support - 30)
			military_support = max(0, military_support - 25)
			condor_threat_level = min(100, condor_threat_level + 25)
			
		"Populista":
			charisma += 25
			connections += 15
			worker_support += 20
			peasant_support += 20
			church_support += 10
			business_support = max(0, business_support - 10)
	
	_clamp_all_values()

func _clamp_all_values() -> void:
	charisma = clamp(charisma, 0, 100)
	intelligence = clamp(intelligence, 0, 100)
	connections = clamp(connections, 0, 100)
	wealth = clamp(wealth, 0, 100)
	military_knowledge = clamp(military_knowledge, 0, 100)
	
	military_support = clamp(military_support, 0, 100)
	business_support = clamp(business_support, 0, 100)
	intellectual_support = clamp(intellectual_support, 0, 100)
	worker_support = clamp(worker_support, 0, 100)
	student_support = clamp(student_support, 0, 100)
	church_support = clamp(church_support, 0, 100)
	peasant_support = clamp(peasant_support, 0, 100)
	
	usa_influence = clamp(usa_influence, 0, 100)
	ussr_influence = clamp(ussr_influence, 0, 100)
	condor_threat_level = clamp(condor_threat_level, 0, 100)

# =====================================
#  PROGRESSÃO POLÍTICA
# =====================================
func attempt_advancement() -> bool:
	if not can_advance:
		return false
		
	if is_imprisoned or is_in_exile:
		return false
		
	var old_position_name = position_name
	current_position = Position.PRESIDENT
	months_in_position = 0.0
	political_experience += 10
	
	if current_position == Position.PRESIDENT: # Usando o enum agora
		in_power = true
		
	var event_text = "Avançou de %s para %s" % [old_position_name, position_name]
	major_events.append(event_text)
	
	position_advanced.emit(old_position_name, position_name)
	return true

# =====================================
#  AÇÕES POLÍTICAS
# =====================================
func get_available_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	
	if is_imprisoned or is_in_exile:
		return actions
	
	# Ações básicas sempre disponíveis
	actions.append({
		"id": "public_speech",
		"name": "Fazer Discurso Público",
		"description": "Aumenta carisma e apoio",
		"costs": {"connections": 5},
		"effects": {"charisma": 2, "random_support": 3},
		"risk": 5,
		"available": connections >= 5
	})
	
	actions.append({
		"id": "build_network",
		"name": "Construir Rede de Contatos",
		"description": "Investe para expandir conexões",
		"costs": {"wealth": 10},
		"effects": {"connections": 5},
		"risk": 0,
		"available": wealth >= 10
	})
	
	# Ações por posição
	if current_position <= Position.ACTIVIST: # Cidadão ou Ativista
		actions.append({
			"id": "organize_rally",
			"name": "Organizar Manifestação",
			"description": "Mobiliza trabalhadores e estudantes",
			"costs": {"connections": 10, "wealth": 5},
			"effects": {"worker_support": 5, "student_support": 5},
			"risk": 15,
			"available": connections >= 10 and wealth >= 5
		})
	
	if current_position >= Position.LOCAL_LEADER: # Líder Local ou superior
		actions.append({
			"id": "propose_bill",
			"name": "Propor Legislação",
			"description": "Ganha experiência e apoio intelectual",
			"costs": {"intelligence": 10},
			"effects": {"political_experience": 5, "intellectual_support": 5},
			"risk": 5,
			"available": intelligence >= 10
		})
	
	if current_position >= Position.SENATOR: # Senador ou Ministro
		actions.append({
			"id": "negotiate_coalition",
			"name": "Negociar Coalizão",
			"description": "Aumenta apoio de múltiplos grupos",
			"costs": {"connections": 15, "wealth": 20},
			"effects": {"multi_support": 3},
			"risk": 10,
			"available": connections >= 15 and wealth >= 20
		})
		
		if military_support >= 50:
			actions.append({
				"id": "military_conspiracy",
				"name": "Conspirar Golpe Militar",
				"description": "Tentativa arriscada de tomar o poder",
				"costs": {"military_knowledge": 20, "connections": 25},
				"effects": {"instant_presidency": true},
				"risk": 40,
				"available": military_knowledge >= 20 and connections >= 25
			})
	
	return actions

func execute_action(action: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"events": []
	}
	
	# Verificar disponibilidade
	if not action.get("available", false):
		result["message"] = "Ação não disponível"
		return result
	
	# Verificar custos
	var costs = action.get("costs", {})
	for cost_type in costs:
		var cost_value = costs[cost_type]
		var current_value = get(cost_type)
		if current_value < cost_value:
			result["message"] = "Recursos insuficientes"
			return result
	
	# Calcular sucesso
	var base_chance = 70.0
	var risk = action.get("risk", 0)
	var charisma_bonus = float(charisma) / 10.0
	var success_chance = clamp(base_chance - float(risk) + charisma_bonus, 10.0, 95.0)
	
	var success = randf() * 100.0 < success_chance
	
	if success:
		# Aplicar custos
		for cost_type in costs:
			var cost_value = costs[cost_type]
			var current_value = get(cost_type)
			set(cost_type, clamp(current_value - cost_value, 0, 100))
		
		# Aplicar efeitos
		var effects = action.get("effects", {})
		for effect_type in effects:
			var effect_value = effects[effect_type]
			
			match effect_type:
				"charisma", "intelligence", "connections", "wealth", "military_knowledge", "political_experience":
					var old_value = get(effect_type)
					var new_value = clamp(old_value + effect_value, 0, 100)
					set(effect_type, new_value)
					
				"random_support":
					var groups = ["military", "business", "intellectual", "worker", "student", "church", "peasant"]
					var random_group = groups[randi() % groups.size()]
					var support_attr = random_group + "_support"
					var old_value = get(support_attr)
					var new_value = clamp(old_value + effect_value, 0, 100)
					set(support_attr, new_value)
					result["events"].append("Ganhou %d apoio com %s" % [effect_value, random_group])
					
				"multi_support":
					for group in ["military", "business", "intellectual", "worker", "student", "church", "peasant"]:
						var support_attr = group + "_support"
						var old_value = get(support_attr)
						var new_value = clamp(old_value + effect_value, 0, 100)
						set(support_attr, new_value)
					result["events"].append("Ganhou apoio de todos os grupos")
					
				"instant_presidency":
					if effect_value:
						current_position = Position.PRESIDENT # Usando o enum agora
						in_power = true
						result["events"].append("Golpe militar bem-sucedido!")
				
				_:
					# Apoio específico
					if effect_type.ends_with("_support"):
						var old_value = get(effect_type)
						var new_value = clamp(old_value + effect_value, 0, 100)
						set(effect_type, new_value)
		
		result["success"] = true
		result["message"] = "Ação bem-sucedida!"
		
	else:
		result["message"] = "Ação falhou!"
		
		# Consequências do fracasso
		if risk > 20:
			condor_threat_level = clamp(condor_threat_level + randi_range(5, 15), 0, 100)
			result["events"].append("Atenção das forças de segurança aumentou")
		
		if risk > 30 and randf() < 0.2:
			is_imprisoned = true
			result["events"].append("Foi preso pelas autoridades!")
	
	return result

# =====================================
#  PASSAGEM DE TEMPO
# =====================================
func advance_month() -> void:
	months_in_position += 1.0
	
	# Ganho natural de experiência
	if current_position > 0:
		political_experience += 1
		
	# Eventos baseados em tempo
	if months_in_position >= 24.0 and current_position < Position.PRESIDENT: # Usando o enum
		_handle_stagnation()
		
	# Envelhecimento
	if randi() % 12 == 0:
		age += 1
		
	# Eventos de risco
	if condor_threat_level > 50:
		_handle_condor_risk()
		
	# Tentativa automática de avanço
	if can_advance and randf() < 0.1:
		attempt_advancement()

func _handle_stagnation() -> void:
	# Perda gradual de apoio por estagnar
	var groups = ["military", "business", "intellectual", "worker", "student", "church", "peasant"]
	for group in groups:
		var support_attr = group + "_support"
		var current_value = get(support_attr)
		var new_value = clamp(current_value + randi_range(-3, 1), 0, 100)
		set(support_attr, new_value)

func _handle_condor_risk() -> void:
	if randf() < 0.05: # 5% chance
		var risk_roll = randf()
		
		if risk_roll < 0.3:
			is_in_exile = true
			major_events.append("Forçado ao exílio pela Operação Condor")
		elif risk_roll < 0.6:
			is_imprisoned = true
			major_events.append("Preso por atividades subversivas")
		else:
			condor_threat_level = clamp(condor_threat_level + randi_range(10, 20), 0, 100)
			major_events.append("Escapou de operação de segurança")

# =====================================
#  MÉTODOS DE CONVENIÊNCIA
# =====================================
func get_status_summary() -> String:
	var summary = "=== %s ===\n" % agent_name.to_upper()
	summary += "Posição: %s (%.1f meses)\n" % [position_name, months_in_position]
	summary += "País: %s | Idade: %d\n" % [country, age]
	summary += "Background: %s | Ideologia: %s\n" % [background, ideology]
	summary += "Apoio Total: %d/700\n" % total_support
	summary += "Experiência: %d pontos\n" % political_experience
	
	if can_advance:
		var next_pos_index = current_position + 1
		var required = SUPPORT_REQUIREMENTS[next_pos_index] if next_pos_index < SUPPORT_REQUIREMENTS.size() else 999
		summary += "Precisa de +%d apoio para avançar\n" % (required - total_support)
		
	return summary

# =====================================
#  SERIALIZAÇÃO
# =====================================
func serialize() -> Dictionary:
	return {
		"agent_name": agent_name,
		"age": age,
		"country": country,
		"background": background,
		"ideology": ideology,
		"current_position": current_position,
		"months_in_position": months_in_position,
		"political_experience": political_experience,
		"in_power": in_power,
		"charisma": charisma,
		"intelligence": intelligence,
		"connections": connections,
		"wealth": wealth,
		"military_knowledge": military_knowledge,
		"military_support": military_support,
		"business_support": business_support,
		"intellectual_support": intellectual_support,
		"worker_support": worker_support,
		"student_support": student_support,
		"church_support": church_support,
		"peasant_support": peasant_support,
		"usa_influence": usa_influence,
		"ussr_influence": ussr_influence,
		"is_in_exile": is_in_exile,
		"is_underground": is_underground,
		"is_imprisoned": is_imprisoned,
		"condor_threat_level": condor_threat_level,
		"major_events": major_events
	}

func deserialize(data: Dictionary) -> void:
	agent_name = data.get("agent_name", "")
	age = data.get("age", 30)
	country = data.get("country", "")
	background = data.get("background", "")
	ideology = data.get("ideology", "")
	current_position = data.get("current_position", Position.CITIZEN) # Usando o enum no deserialize
	months_in_position = data.get("months_in_position", 0.0)
	political_experience = data.get("political_experience", 0)
	in_power = data.get("in_power", false)
	charisma = data.get("charisma", 50)
	intelligence = data.get("intelligence", 50)
	connections = data.get("connections", 50)
	wealth = data.get("wealth", 50)
	military_knowledge = data.get("military_knowledge", 50)
	military_support = data.get("military_support", 0)
	business_support = data.get("business_support", 0)
	intellectual_support = data.get("intellectual_support", 0)
	worker_support = data.get("worker_support", 0)
	student_support = data.get("student_support", 0)
	church_support = data.get("church_support", 0)
	peasant_support = data.get("peasant_support", 0)
	usa_influence = data.get("usa_influence", 0)
	ussr_influence = data.get("ussr_influence", 0)
	is_in_exile = data.get("is_in_exile", false)
	is_underground = data.get("is_underground", false)
	is_imprisoned = data.get("is_imprisoned", false)
	condor_threat_level = data.get("condor_threat_level", 0)
	major_events = data.get("major_events", [])

# =====================================
#  FACTORY METHODS
# =====================================
static func create_preset(preset_name: String, country_name: String) -> PlayerAgent:
	var agent = PlayerAgent.new()
	agent.country = country_name
	
	match preset_name:
		"coronel_conservador":
			agent.agent_name = "Coronel Martinez"
			agent.background = "Militar"
			agent.ideology = "DSN"
			agent.age = 45
			
		"intelectual_democrata":
			agent.agent_name = "Dr. Rodriguez"
			agent.background = "Intelectual"
			agent.ideology = "Social-Democrata"
			agent.age = 38
			
		"sindicalista_marxista":
			agent.agent_name = "Carlos Herrera"
			agent.background = "Sindicalista"
			agent.ideology = "Marxista"
			agent.age = 35
			
		"empresario_neoliberal":
			agent.agent_name = "Antonio Silva"
			agent.background = "Empresário"
			agent.ideology = "Neoliberal"
			agent.age = 42
			
		"estudante_populista":
			agent.agent_name = "Maria Santos"
			agent.background = "Estudante"
			agent.ideology = "Populista"
			agent.age = 28
			
		_:
			agent.agent_name = "Agente Político"
			agent.background = "Intelectual"
			agent.ideology = "Social-Democrata"
			agent.age = 35
	
	return agent
