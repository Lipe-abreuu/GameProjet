# =====================================
# ARQUIVO 1: Globals.gd - VERSÃO COMPLETA
# =====================================

extends Node

# Sinais
signal country_value_changed(country_name, value_name, old_value, new_value)
var party_controller: Node = null
# Variáveis globais de tempo
var current_month: int = 9
var current_year: int = 1973

# Player info
var player_country: String = "Chile"

# OPERAÇÃO CONDOR - NOVAS VARIÁVEIS
var condor_active: bool = false
var condor_start_year: int = 0
var condor_threat_level: int = 0

# Dados dos países
var country_data: Dictionary = {
	"Argentina": {
		"stability": 50,
		"economy": 60,
		"population": 45000000,
		"exile_risk": 0,
		"surveillance": 10
	},
	"Uruguay": {
		"stability": 45,
		"economy": 55,
		"population": 3500000,
		"exile_risk": 0,
		"surveillance": 15
	},
	"Chile": {
		"stability": 30,
		"economy": 65,
		"population": 11000000,
		"repression": 40,
		"exile_risk": 0,
		"surveillance": 20,
		"international_pressure": 0
	},
	"Paraguay": {
		"stability": 40,
		"economy": 45,
		"population": 6000000,
		"exile_risk": 0,
		"surveillance": 25
	},
	"Bolivia": {
		"stability": 35,
		"economy": 40,
		"population": 8000000,
		"exile_risk": 0,
		"surveillance": 10
	},
	"Brasil": {
		"stability": 55,
		"economy": 70,
		"population": 120000000,
		"exile_risk": 0,
		"surveillance": 15
	}
}

func _ready():
	print("=== GLOBALS INICIALIZADO ===")
	print("Países disponíveis: ", country_data.keys())
	print("País do jogador: ", player_country)

# =====================================
# FUNÇÕES BÁSICAS
# =====================================

func get_country(country_name: String) -> Dictionary:
	return country_data.get(country_name, {})

func get_country_value(country_name: String, value_name: String, default_value = 0):
	var country = get_country(country_name)
	return country.get(value_name, default_value)

func adjust_country_value(country_name: String, value_name: String, change: int):
	if not country_data.has(country_name):
		print("ERRO: País '%s' não encontrado" % country_name)
		return
	
	var old_value = get_country_value(country_name, value_name, 0)
	var new_value = old_value + change
	
	country_data[country_name][value_name] = new_value
	
	print("GLOBALS: %s de %s agora é %d" % [value_name, country_name, new_value])
	emit_signal("country_value_changed", country_name, value_name, old_value, new_value)

# =====================================
# OPERAÇÃO CONDOR - FUNÇÕES PRINCIPAIS
# =====================================

func activate_condor():
	"""Ativa a Operação Condor com todos os seus efeitos"""
	condor_active = true
	condor_start_year = current_year
	condor_threat_level = 1
	
	print("🕸️ OPERAÇÃO CONDOR ATIVADA - Cooperação repressiva entre ditaduras do Cone Sul")
	
	# Efeitos imediatos nos países participantes
	var condor_countries = ["Chile", "Argentina", "Uruguay", "Paraguay", "Bolivia"]
	for country in condor_countries:
		adjust_country_value(country, "exile_risk", 40)
		adjust_country_value(country, "surveillance", 30)
	
	# Efeitos especiais
	adjust_country_value("Chile", "international_pressure", 15)

func is_condor_active() -> bool:
	"""Verifica se a Operação Condor está ativa"""
	return condor_active

func get_condor_exile_risk() -> int:
	"""Retorna o nível de risco para exilados"""
	if not condor_active:
		return 0
	return 40 + (condor_threat_level * 10)

func get_condor_action_penalty() -> float:
	"""Retorna penalidade para ações internacionais"""
	if not condor_active:
		return 0.0
	return 0.2 + (condor_threat_level * 0.1)  # 20-50% de penalidade

func increase_condor_threat():
	"""Aumenta o nível de ameaça da Operação Condor"""
	if condor_active and condor_threat_level < 3:
		condor_threat_level += 1
		print("🔺 Operação Condor intensifica atividades (Nível %d)" % condor_threat_level)

func process_condor_monthly():
	"""Efeitos mensais da Operação Condor"""
	if not condor_active:
		return
	
	# Aumenta gradualmente a vigilância
	var condor_countries = ["Chile", "Argentina", "Uruguay", "Paraguay", "Bolivia"]
	for country in condor_countries:
		var current_surveillance = get_country_value(country, "surveillance", 0)
		if current_surveillance < 80:  # Limite máximo
			adjust_country_value(country, "surveillance", 2)
	
	# 10% chance de aumentar nível de ameaça por mês
	if randi() % 100 < 10:
		increase_condor_threat()
	
	# 5% chance de evento especial de perseguição
	if randi() % 100 < 5:
		trigger_condor_persecution_event()

func trigger_condor_persecution_event():
	"""Evento especial de perseguição da Operação Condor"""
	var target_countries = ["França", "México", "Suécia", "EUA", "Itália"]
	var target = target_countries[randi() % target_countries.size()]
	
	print("🎯 EVENTO CONDOR: Operação de perseguição em %s" % target)
	
	# TODO: Conectar com sistema de notificações
	# NotificationSystem.show_notification(
	#     "Operação Condor", 
	#     "Agentes perseguem exilados em %s" % target,
	#     NotificationSystem.NotificationType.ERROR
	# )

func get_condor_status_text() -> String:
	"""Retorna texto descritivo do status da Operação Condor"""
	if not condor_active:
		return "Inativa"
	
	var threat_names = ["Baixa", "Média", "Alta", "Crítica"]
	var threat_name = threat_names[condor_threat_level - 1] if condor_threat_level <= 4 else "Máxima"
	
	return "Ativa (Ameaça: %s)" % threat_name

# =====================================
# FUNÇÕES AUXILIARES
# =====================================

func simulate_monthly_changes():
	"""Simula mudanças mensais nos países"""
	for country_name in country_data.keys():
		var _country = country_data[country_name]
		
		# Flutuações naturais na estabilidade
		var stability_change = randi_range(-2, 2)
		adjust_country_value(country_name, "stability", stability_change)
		
		# Limita valores
		var stability = get_country_value(country_name, "stability", 50)
		country_data[country_name]["stability"] = clamp(stability, 0, 100)
	
	# Processa efeitos mensais da Operação Condor
	process_condor_monthly()

func get_player_data() -> Dictionary:
	"""Retorna dados específicos do jogador"""
	return {
		"country": player_country,
		"money": 1000,  # Placeholder
		"stability": get_country_value(player_country, "stability", 50)
	}
