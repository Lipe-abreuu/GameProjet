# =====================================
#  PLAYERAGENT.GD - SISTEMA DE PERSONAGEM
#  Fase 1: De agente político a presidente
# =====================================
class_name PlayerAgent
extends Resource

# =====================================
#  DADOS BÁSICOS DO PERSONAGEM
# =====================================
@export var name: String = ""
@export var age: int = 30  # 25-45 em 1973
@export var photo: Texture2D
@export var country: String = ""

# =====================================
#  BACKGROUND E IDEOLOGIA
# =====================================
@export var background: String = "Estudante"  # "Militar", "Intelectual", "Sindicalista", "Empresário", "Estudante"
@export var ideology: String = "Social-Democrata"  # "DSN", "Neoliberal", "Social-Democrata", "Marxista", "Populista"

# =====================================
#  STATUS POLÍTICO ATUAL
# =====================================
@export var current_position: String = "Cidadão"  # "Cidadão" → "Ativista" → "Deputado" → "Senador" → "Ministro" → "Presidente"
@export var in_power: bool = false  # Controla transição Fase 1 → Fase 2
@export var years_in_position: int = 0
@export var political_experience: int = 0  # Acumula ao longo do tempo

# =====================================
#  ATRIBUTOS PESSOAIS (0-100)
# =====================================
@export var charisma: int = 50          # Sucesso em discursos e comícios
@export var intelligence: int = 50      # Eficiência em conspirações e negociações
@export var connections: int = 50       # Rede de contatos políticos
@export var wealth: int = 50           # Recursos financeiros pessoais
@export var military_knowledge: int = 50 # Conhecimento militar (golpes)

# =====================================
#  APOIO POR GRUPOS (0-100)
# =====================================
@export var support: Dictionary = {
	"military": 0,      # Forças Armadas
	"business": 0,      # Empresários/Tecnocratas
	"intellectuals": 0, # Intelectuais/Classe Média
	"workers": 0,       # Sindicatos/Operários
	"students": 0,      # Movimento Estudantil
	"church": 0,        # Igreja Católica
	"peasants": 0       # Camponeses (relevante para alguns países)
}

# =====================================
#  INFLUÊNCIA DAS SUPERPOTÊNCIAS (0-100)
# =====================================
@export var usa_influence: int = 0
@export var ussr_influence: int = 0

# =====================================
#  STATUS ESPECIAIS
# =====================================
@export var is_in_exile: bool = false
@export var is_underground: bool = false
@export var is_imprisoned: bool = false
@export var condor_target_level: int = 0  # 0-100, quão visado pela Operação Condor
@export var has_diplomatic_immunity: bool = false

# =====================================
#  HISTÓRICO E EVENTOS
# =====================================
@export var major_events: Array[String] = []  # Eventos importantes na carreira
@export var allies: Array[String] = []        # Nomes de aliados importantes
@export var enemies: Array[String] = []       # Nomes de inimigos importantes

# =====================================
#  CONSTRUTOR E INICIALIZAÇÃO
# =====================================
func _init(p_name: String = "", p_country: String = "", p_background: String = "", p_ideology: String = ""):
	if p_name != "":
		name = p_name
	if p_country != "":
		country = p_country
	if p_background != "":
		background = p_background
	if p_ideology != "":
		ideology = p_ideology
	
	_apply_background_modifiers()
	_apply_ideology_modifiers()

# =====================================
#  MODIFICADORES POR BACKGROUND
# =====================================
func _apply_background_modifiers():
	match background:
		"Militar":
			military_knowledge += 30
			connections += 15
			support["military"] += 25
			support["business"] += 10
			support["workers"] -= 15
			support["students"] -= 10
			
		"Intelectual":
			intelligence += 25
			charisma += 15
			support["intellectuals"] += 30
			support["students"] += 15
			support["military"] -= 10
			support["business"] += 5
			
		"Sindicalista":
			charisma += 20
			connections += 10
			support["workers"] += 35
			support["peasants"] += 15
			support["business"] -= 25
			support["military"] -= 15
			
		"Empresário":
			wealth += 30
			intelligence += 15
			support["business"] += 30
			connections += 10
			support["workers"] -= 20
			support["students"] -= 10
			
		"Estudante":
			charisma += 15
			intelligence += 10
			support["students"] += 25
			support["intellectuals"] += 15
			support["workers"] += 10
			wealth -= 15
	
	_clamp_all_values()

# =====================================
#  MODIFICADORES POR IDEOLOGIA
# =====================================
func _apply_ideology_modifiers():
	match ideology:
		"DSN":  # Doutrina de Segurança Nacional
			military_knowledge += 20
			usa_influence += 15
			support["military"] += 20
			support["business"] += 15
			support["workers"] -= 25
			support["students"] -= 20
			condor_target_level -= 10
			
		"Neoliberal":
			intelligence += 15
			wealth += 20
			usa_influence += 10
			support["business"] += 25
			support["intellectuals"] += 10
			support["workers"] -= 15
			support["peasants"] -= 10
			
		"Social-Democrata":
			charisma += 15
			connections += 10
			support["intellectuals"] += 15
			support["workers"] += 15
			support["church"] += 5
			# Moderado, sem grandes penalidades
			
		"Marxista":
			intelligence += 15
			charisma += 10
			ussr_influence += 20
			support["workers"] += 30
			support["students"] += 20
			support["peasants"] += 15
			support["business"] -= 30
			support["military"] -= 25
			condor_target_level += 25
			
		"Populista":
			charisma += 25
			connections += 15
			support["workers"] += 20
			support["peasants"] += 20
			support["church"] += 10
			support["business"] -= 10
			# Volátil, pode ganhar ou perder apoio rapidamente
	
	_clamp_all_values()

# =====================================
#  SISTEMA DE PROGRESSÃO POLÍTICA
# =====================================
func get_total_support() -> int:
	var total = 0
	for group in support.values():
		total += group
	return total

func get_required_support_for_next_position() -> int:
	match current_position:
		"Cidadão": return 10      # Ativista
		"Ativista": return 25     # Líder Local
		"Líder Local": return 40  # Deputado
		"Deputado": return 60     # Senador
		"Senador": return 75      # Ministro
		"Ministro": return 85     # Presidente
		_: return 999

func can_advance_position() -> bool:
	var required = get_required_support_for_next_position()
	var current = get_total_support()
	return current >= required and not is_imprisoned and not is_in_exile

func get_next_position() -> String:
	match current_position:
		"Cidadão": return "Ativista"
		"Ativista": return "Líder Local"
		"Líder Local": return "Deputado"
		"Deputado": return "Senador"
		"Senador": return "Ministro"
		"Ministro": return "Presidente"
		_: return current_position

func advance_position() -> bool:
	if can_advance_position():
		var old_position = current_position
		current_position = get_next_position()
		years_in_position = 0
		political_experience += 10
		
		# Presidente = transição para Fase 2
		if current_position == "Presidente":
			in_power = true
		
		# Evento histórico
		var event_text = "Avançou de %s para %s" % [old_position, current_position]
		major_events.append(event_text)
		
		print("🎖️ %s avançou de %s para %s!" % [name, old_position, current_position])
		return true
	return false

# =====================================
#  CAMINHOS PARA O PODER
# =====================================
enum PowerPath {
	DEMOCRATIC,   # Via eleições
	MILITARY,     # Via golpe militar
	REVOLUTION    # Via revolução popular
}

func can_attempt_democratic_path() -> bool:
	return (support["intellectuals"] >= 40 and 
			support["workers"] >= 30 and 
			not is_underground and 
			not is_imprisoned)

func can_attempt_military_coup() -> bool:
	return (support["military"] >= 70 and 
			usa_influence >= 60 and 
			military_knowledge >= 60 and
			not is_imprisoned)

func can_attempt_popular_revolution() -> bool:
	return (support["workers"] >= 80 and 
			support["students"] >= 70 and 
			ussr_influence >= 50 and
			current_position != "Cidadão")

# =====================================
#  AÇÕES POLÍTICAS DISPONÍVEIS
# =====================================
func get_available_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	
	# Ações básicas sempre disponíveis
	if not is_imprisoned:
		actions.append({
			"name": "Fazer Discurso Público",
			"cost": {"connections": 5},
			"effects": {"charisma": 2, "support_boost": "random_group"},
			"risk": 5
		})
		
		actions.append({
			"name": "Construir Rede de Contatos",
			"cost": {"wealth": 10},
			"effects": {"connections": 5},
			"risk": 0
		})
	
	# Ações por posição
	match current_position:
		"Cidadão", "Ativista":
			if not is_underground:
				actions.append({
					"name": "Organizar Manifestação",
					"cost": {"connections": 10},
					"effects": {"support_workers": 5, "support_students": 5},
					"risk": 15
				})
		
		"Líder Local", "Deputado":
			actions.append({
				"name": "Propor Legislação",
				"cost": {"intelligence": 10},
				"effects": {"political_experience": 5, "support_intellectuals": 5},
				"risk": 5
			})
		
		"Senador", "Ministro":
			actions.append({
				"name": "Negociar Coalizão",
				"cost": {"connections": 15, "wealth": 20},
				"effects": {"support_boost": "multiple_groups"},
				"risk": 10
			})
			
			if support["military"] >= 50:
				actions.append({
					"name": "Conspirar Golpe Militar",
					"cost": {"military_knowledge": 20, "connections": 25},
					"effects": {"path_to_presidency": true},
					"risk": 40
				})
	
	# Ações por ideologia
	if ideology == "Marxista" and ussr_influence >= 30:
		actions.append({
			"name": "Receber Apoio Soviético",
			"cost": {},
			"effects": {"ussr_influence": 10, "wealth": 15},
			"risk": 20
		})
	
	if ideology == "DSN" and usa_influence >= 30:
		actions.append({
			"name": "Colaborar com CIA",
			"cost": {},
			"effects": {"usa_influence": 10, "military_knowledge": 5},
			"risk": 15
		})
	
	return actions

# =====================================
#  EXECUTAR AÇÃO POLÍTICA
# =====================================
func execute_action(action: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"events": []
	}
	
	# Verificar se pode pagar custos
	for cost_type in action.get("cost", {}):
		var cost_value = action["cost"][cost_type]
		match cost_type:
			"wealth":
				if wealth < cost_value:
					result["message"] = "Recursos insuficientes!"
					return result
			"connections":
				if connections < cost_value:
					result["message"] = "Contatos insuficientes!"
					return result
			"intelligence":
				if intelligence < cost_value:
					result["message"] = "Conhecimento insuficiente!"
					return result
			"military_knowledge":
				if military_knowledge < cost_value:
					result["message"] = "Conhecimento militar insuficiente!"
					return result
	
	# Calcular chance de sucesso
	var base_success = 70
	var risk_modifier = action.get("risk", 0)
	var charisma_bonus = charisma / 10
	var success_chance = base_success - risk_modifier + charisma_bonus
	
	# Roll de sucesso
	var roll = randi() % 100
	var success = roll < success_chance
	
	if success:
		# Aplicar custos
		for cost_type in action.get("cost", {}):
			var cost_value = action["cost"][cost_type]
			match cost_type:
				"wealth": wealth -= cost_value
				"connections": connections -= cost_value
				"intelligence": intelligence -= cost_value
				"military_knowledge": military_knowledge -= cost_value
		
		# Aplicar efeitos
		for effect_type in action.get("effects", {}):
			var effect_value = action["effects"][effect_type]
			match effect_type:
				"charisma": charisma += effect_value
				"intelligence": intelligence += effect_value
				"connections": connections += effect_value
				"wealth": wealth += effect_value
				"military_knowledge": military_knowledge += effect_value
				"political_experience": political_experience += effect_value
				"usa_influence": usa_influence += effect_value
				"ussr_influence": ussr_influence += effect_value
				"support_workers": support["workers"] += effect_value
				"support_students": support["students"] += effect_value
				"support_intellectuals": support["intellectuals"] += effect_value
				"support_boost":
					if effect_value == "random_group":
						var groups = support.keys()
						var random_group = groups[randi() % groups.size()]
						support[random_group] += randi_range(3, 8)
					elif effect_value == "multiple_groups":
						for group in support:
							support[group] += randi_range(1, 4)
		
		result["success"] = true
		result["message"] = "Ação executada com sucesso!"
		
		# Eventos especiais
		if action.get("effects", {}).has("path_to_presidency"):
			if can_attempt_military_coup():
				result["events"].append("Golpe militar planejado!")
				# Lógica de golpe seria implementada no sistema principal
		
	else:
		result["message"] = "Ação falhou!"
		
		# Consequências do fracasso
		if action.get("risk", 0) > 20:
			condor_target_level += randi_range(5, 15)
			result["events"].append("Atenção das forças de segurança aumentou!")
		
		if action.get("risk", 0) > 30 and randi() % 100 < 20:
			is_imprisoned = true
			result["events"].append("Foi preso pelas autoridades!")
	
	_clamp_all_values()
	return result

# =====================================
#  PASSAGEM DE TEMPO
# =====================================
func advance_month():
	years_in_position += 1/12.0
	
	# Eventos baseados em tempo
	if years_in_position >= 2.0 and current_position != "Presidente":
		# Pressão para avançar
		for group in support:
			support[group] += randi_range(-2, 1)  # Leve declínio se estagnar
	
	# Idade e experiência
	if randi() % 12 == 0:  # Uma vez por ano
		age += 1
		political_experience += 2
	
	# Eventos de risco
	if condor_target_level > 50 and randi() % 100 < 10:
		_handle_condor_risk()
	
	_clamp_all_values()

func _handle_condor_risk():
	var risk_roll = randi() % 100
	
	if risk_roll < 30:
		is_in_exile = true
		major_events.append("Forçado ao exílio pela Operação Condor")
		print("⚠️ %s foi forçado ao exílio!" % name)
	elif risk_roll < 60:
		is_imprisoned = true
		major_events.append("Preso por atividades subversivas")
		print("⚠️ %s foi preso!" % name)
	else:
		condor_target_level += randi_range(10, 20)
		major_events.append("Escapou de operação de segurança")
		print("⚠️ %s escapou de uma operação!" % name)

# =====================================
#  UTILIDADES
# =====================================
func _clamp_all_values():
	# Atributos pessoais
	charisma = clamp(charisma, 0, 100)
	intelligence = clamp(intelligence, 0, 100)
	connections = clamp(connections, 0, 100)
	wealth = clamp(wealth, 0, 100)
	military_knowledge = clamp(military_knowledge, 0, 100)
	
	# Apoio por grupos
	for group in support:
		support[group] = clamp(support[group], 0, 100)
	
	# Influência das superpotências
	usa_influence = clamp(usa_influence, 0, 100)
	ussr_influence = clamp(ussr_influence, 0, 100)
	
	# Status especiais
	condor_target_level = clamp(condor_target_level, 0, 100)

func get_summary() -> String:
	var summary = "=== %s ===\n" % name.to_upper()
	summary += "Posição: %s (%d anos)\n" % [current_position, int(years_in_position)]
	summary += "País: %s | Idade: %d\n" % [country, age]
	summary += "Background: %s | Ideologia: %s\n" % [background, ideology]
	summary += "\nAtributos:\n"
	summary += "Carisma: %d | Inteligência: %d\n" % [charisma, intelligence]
	summary += "Contatos: %d | Riqueza: %d\n" % [connections, wealth]
	summary += "Conhecimento Militar: %d\n" % military_knowledge
	summary += "\nApoio Total: %d/700\n" % get_total_support()
	summary += "Influência EUA: %d | URSS: %d\n" % [usa_influence, ussr_influence]
	
	if is_in_exile:
		summary += "\n⚠️ EXILADO"
	if is_imprisoned:
		summary += "\n⚠️ PRESO"
	if is_underground:
		summary += "\n⚠️ CLANDESTINO"
	
	return summary

# =====================================
#  CRIAÇÃO RÁPIDA DE PERSONAGENS
# =====================================
static func create_preset_character(preset: String, p_country: String) -> PlayerAgent:
	var agent = PlayerAgent.new()
	agent.country = p_country
	
	match preset:
		"militar_conservador":
			agent.name = "Coronel Martinez"
			agent.background = "Militar"
			agent.ideology = "DSN"
			agent.age = 45
			
		"intelectual_democrata":
			agent.name = "Dr. Rodriguez"
			agent.background = "Intelectual"
			agent.ideology = "Social-Democrata"
			agent.age = 38
			
		"sindicalista_marxista":
			agent.name = "Carlos Herrera"
			agent.background = "Sindicalista"
			agent.ideology = "Marxista"
			agent.age = 35
			
		"empresario_neoliberal":
			agent.name = "Antonio Silva"
			agent.background = "Empresário"
			agent.ideology = "Neoliberal"
			agent.age = 42
			
		"estudante_populista":
			agent.name = "Maria Santos"
			agent.background = "Estudante"
			agent.ideology = "Populista"
			agent.age = 28
		
		_:
			agent.name = "Agente Desconhecido"
			agent.background = "Estudante"
			agent.ideology = "Social-Democrata"
			agent.age = 30
	
	return agent
