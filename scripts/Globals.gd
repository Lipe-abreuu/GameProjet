# Globals.gd - Sistema centralizado de dados dos países
# Adicionar como Autoload: Project → Autoload → Name: Globals, Path: res://scripts/Globals.gd

extends Node
# Referência à classe PlayerAgent
var current_player_agent: PlayerAgent
# =====================================
#  DADOS CENTRALIZADOS DOS PAÍSES
# =====================================
var country_data := {
	"Argentina": {
		"money": 10_000,
		"stability": 60,
		"gov_power": 60,
		"rebel_power": 40,
		"population": 45_000_000,
		"gdp": 380_000_000_000,
		"industry": 35,
		"agriculture": 25,
		"defense": 15,
		"relations": {},
		"last_update": 0
	},
	"Uruguay": {
		"money": 3_500,
		"stability": 75,
		"gov_power": 75,
		"rebel_power": 25,
		"population": 3_500_000,
		"gdp": 55_000_000_000,
		"industry": 20,
		"agriculture": 45,
		"defense": 10,
		"relations": {},
		"last_update": 0
	},
	"Chile": {
		"money": 8_200,
		"stability": 68,
		"gov_power": 68,
		"rebel_power": 32,
		"population": 19_000_000,
		"gdp": 250_000_000_000,
		"industry": 42,
		"agriculture": 18,
		"defense": 22,
		"relations": {},
		"last_update": 0
	},
	"Paraguay": {
		"money": 2_800,
		"stability": 45,
		"gov_power": 45,
		"rebel_power": 55,
		"population": 7_000_000,
		"gdp": 35_000_000_000,
		"industry": 15,
		"agriculture": 60,
		"defense": 8,
		"relations": {},
		"last_update": 0
	},
	"Bolivia": {
		"money": 2_200,
		"stability": 40,
		"gov_power": 40,
		"rebel_power": 60,
		"population": 11_500_000,
		"gdp": 38_000_000_000,
		"industry": 18,
		"agriculture": 55,
		"defense": 12,
		"relations": {},
		"last_update": 0
	},
	"Brasil": {
		"money": 8_500,
		"stability": 65,
		"gov_power": 65,
		"rebel_power": 35,
		"population": 110_000_000,
		"gdp": 450_000_000_000,
		"industry": 40,
		"agriculture": 30,
		"defense": 20,
		"relations": {},
		"last_update": 0,
		"is_player": true
	}
}

# País do jogador (padrão Argentina - Cone Sul)
var player_country := "Argentina"

# Tempo de jogo global
var current_month := 1
var current_year := 1973

# Sistema de relações diplomáticas (variável estava faltando)
var country_relations := {}

# =====================================
#  API DE ACESSO AOS DADOS
# =====================================

# Retorna dados completos de um país
func get_country(country_name: String) -> Dictionary:
	return country_data.get(country_name, {})

# Define um valor específico para um país
func set_country_value(country: String, field: String, value) -> void:
	if country_data.has(country):
		country_data[country][field] = value
		country_data[country]["last_update"] = Time.get_ticks_msec()
		
		# Aplicar limites para certos campos
		_apply_field_limits(country, field)
	else:
		print("Aviso: País '%s' não encontrado" % country)

# Ajusta um valor (soma/subtrai delta)
func adjust_country_value(country: String, field: String, delta: float) -> void:
	if country_data.has(country):
		var current_value = country_data[country].get(field, 0)
		country_data[country][field] = current_value + delta
		country_data[country]["last_update"] = Time.get_ticks_msec()
		
		# Aplicar limites para certos campos
		_apply_field_limits(country, field)
	else:
		print("Aviso: País '%s' não encontrado" % country)

# Aplica limites aos campos (ex: estabilidade 0-100)
func _apply_field_limits(country: String, field: String) -> void:
	var value = country_data[country][field]
	
	match field:
		"stability", "gov_power", "rebel_power", "industry", "agriculture", "defense":
			country_data[country][field] = clamp(value, 0, 100)
		"money":
			country_data[country][field] = max(0, value)
		"population":
			country_data[country][field] = max(1000, value)

# Retorna valor específico de um campo
func get_country_value(country: String, field: String, default_value = 0):
	var country_dict = get_country(country)
	return country_dict.get(field, default_value)

# Retorna dados do jogador atual
func get_player_data() -> Dictionary:
	return get_country(player_country)

# Define o país do jogador
func set_player_country(country: String) -> void:
	if country_data.has(country):
		# Remover flag is_player do país anterior
		if country_data.has(player_country):
			country_data[player_country]["is_player"] = false
		
		# Definir novo país do jogador
		player_country = country
		country_data[country]["is_player"] = true
		print("País do jogador alterado para: ", country)
	else:
		print("Erro: País '%s' não existe" % country)

# =====================================
#  SIMULAÇÃO PASSIVA DOS PAÍSES (BALANCEADA)
# =====================================

# Chamado a cada mês por Main.gd
func simulate_monthly_changes() -> void:
	for country_name in country_data.keys():
		if country_name == player_country:
			# Jogador: apenas orçamento e shift político
			apply_monthly_budget(country_name)
			apply_monthly_political_shift(country_name)
		else:
			# IA: simulação completa
			simulate_ai_country(country_name)

# =====================================
#  IA PASSIVA PARA PAÍSES NÃO-JOGADOR
# =====================================
func simulate_ai_country(country: String) -> void:
	var d = country_data[country]
	if d.is_empty() or country == player_country:
		return
	
	print("🤖 === IA SIMULAÇÃO: %s ===" % country)
	
	# 1. Aplicar orçamento mensal
	apply_monthly_budget(country)
	
	# 2. Verificar se está em revolução
	if d.get("in_revolution", false):
		print("🔴 %s está em revolução - nenhuma ação IA" % country)
		return
	
	# 3. Decisão aleatória de foco (uma por mês)
	var action = randi() % 5
	var g = randi_range(2, 4)
	var r = randi_range(2, 4)
	
	match action:
		0:  # Reformas sociais
			d.stability = clamp(d.stability + r, 0, 100)
			d.money -= 500
			print("📋 [%s] Reformas sociais: estab+%d, dinheiro-500" % [country, r])
		
		1:  # Repressão
			d.gov_power = clamp(d.gov_power + g, 0, 100)
			d.rebel_power = clamp(d.rebel_power - r, 0, 100)
			d.stability = max(d.stability - 2, 0)
			print("👮 [%s] Repressão: gov+%d, rebel-%d, estab-2" % [country, g, r])
		
		2:  # Propaganda
			d.gov_power = clamp(d.gov_power + g, 0, 100)
			d.money -= 300
			print("📺 [%s] Propaganda: gov+%d, dinheiro-300" % [country, g])
		
		3:  # Corrupção
			d.money -= 800
			d.stability = max(d.stability - 5, 0)
			print("💰 [%s] Corrupção: dinheiro-800, estab-5" % country)
		
		4:  # Investimento
			d.money -= 600
			d.stability = clamp(d.stability + 2, 0, 100)
			print("🏗️ [%s] Investimento: dinheiro-600, estab+2" % country)
	
	# 4. Evento ocasional (10% chance)
	if randi() % 100 < 10:
		print("🎲 [%s] Evento aleatório disparado!" % country)
		apply_random_event(country)
	
	# 5. Aplicar shift político baseado na nova estabilidade
	apply_monthly_political_shift(country)
	
	# 6. Checar revolução IA
	if d.rebel_power >= 100 and not d.has("in_revolution"):
		print("💥 [%s] REVOLUÇÃO DA IA! País entra em colapso!" % country)
		d["in_revolution"] = true
		d.stability = 0
		d.gov_power = 0
	
	print("🤖 === FIM IA: %s ===" % country)

# Simula mudanças mensais para um país (DEPRECIADA - removida para IA)
# func _simulate_country_month(country: String) -> void:

# =====================================
#  SISTEMA DE ORÇAMENTO MENSAL
# =====================================
func apply_monthly_budget(country: String) -> void:
	var data = country_data[country]
	var income = data.get("income", 1000)
	var expenses = data.get("expenses", 800)
	
	# Calcular saldo base
	var base_balance = income - expenses
	
	# Adicionar variação econômica aleatória (±0-600, raramente ±1000)
	var economic_event = 0
	var event_chance = randi() % 100
	if event_chance < 10:  # 10% chance de evento econômico grande
		economic_event = randi_range(-1000, 1000)
		print("📊 Evento econômico grande: %+d" % economic_event)
	elif event_chance < 30:  # 20% chance de evento econômico médio
		economic_event = randi_range(-600, 600)
		print("📊 Evento econômico médio: %+d" % economic_event)
	else:  # 70% sem evento ou evento pequeno
		economic_event = randi_range(-200, 200)
	
	# Aplicar mudança no dinheiro
	var total_change = base_balance + economic_event
	adjust_country_value(country, "money", total_change)
	
	var current_money = get_country_value(country, "money", 0)
	print("💰 %s: Receita %d, Despesa %d, Evento %+d = %+d (Total: %d)" % [
		country, income, expenses, economic_event, total_change, current_money
	])
	
	# Verificar falência (money < -2000)
	if current_money < -2000:
		print("💸 FALÊNCIA! %s perdeu 10 pontos de estabilidade" % country)
		adjust_country_value(country, "stability", -10)

# =====================================
#  SISTEMA POLÍTICO BALANCEADO
# =====================================
func apply_monthly_political_shift(country: String) -> void:
	var stability = get_country_value(country, "stability", 50)
	
	# Shift baseado na estabilidade
	var gov_shift: int
	var rebel_shift: int
	
	if stability >= 70:
		gov_shift = -1
		rebel_shift = 1
		print("🟢 %s: Estabilidade alta (shift leve)" % country)
	elif stability >= 40:
		gov_shift = -2
		rebel_shift = 2
		print("🟡 %s: Estabilidade média (shift médio)" % country)
	else:
		gov_shift = -3
		rebel_shift = 4
		print("🔴 %s: Estabilidade baixa (shift pesado)" % country)
	
	# Aplicar shifts
	adjust_country_value(country, "gov_power", gov_shift)
	adjust_country_value(country, "rebel_power", rebel_shift)
	
	# Recalcular estabilidade baseada no novo equilíbrio
	var new_gov_power = get_country_value(country, "gov_power", 50)
	var new_rebel_power = get_country_value(country, "rebel_power", 50)
	var new_stability = (new_gov_power + (100 - new_rebel_power)) / 2
	set_country_value(country, "stability", new_stability)
	
	print("🏛️ %s: Gov %d → %d, Rebel %d → %d, Estab → %d" % [
		country, 
		new_gov_power - gov_shift, new_gov_power,
		new_rebel_power - rebel_shift, new_rebel_power,
		new_stability
	])

# =====================================
#  SISTEMA DE RELAÇÕES DIPLOMÁTICAS
# =====================================

# Define relação entre dois países (-100 a +100)
func set_relation(country1: String, country2: String, value: int) -> void:
	value = clamp(value, -100, 100)
	
	if country_data.has(country1):
		if not country_data[country1].has("relations"):
			country_data[country1]["relations"] = {}
		country_data[country1]["relations"][country2] = value
	
	if country_data.has(country2):
		if not country_data[country2].has("relations"):
			country_data[country2]["relations"] = {}
		country_data[country2]["relations"][country1] = value

# Obtém relação entre dois países
func get_relation(country1: String, country2: String) -> int:
	var relations = country_data.get(country1, {}).get("relations", {})
	return relations.get(country2, 0)

# Ajusta relação entre países
func adjust_relation(country1: String, country2: String, delta: int) -> void:
	var current_relation = get_relation(country1, country2)
	set_relation(country1, country2, current_relation + delta)

# =====================================
#  SISTEMA DE EVENTOS ALEATÓRIOS (BALANCEADO)
# =====================================

# Aplica evento aleatório a um país
func apply_random_event(country: String) -> Dictionary:
	var events = [
		{
			"name": "Greve Geral",
			"description": "Sindicatos paralisam o país",
			"type": "economic",
			"effects": {"expenses": 400, "stability": -5},
			"duration": 2  # Efeito dura 2 meses
		},
		{
			"name": "Descoberta de Recursos",
			"description": "Novos recursos naturais são descobertos",
			"type": "economic", 
			"effects": {"income": 300, "industry": 5},
			"duration": 0  # Efeito permanente
		},
		{
			"name": "Escândalo de Corrupção",
			"description": "Escândalo político abala o governo",
			"type": "political",
			"effects": {"gov_power": -8, "rebel_power": 8}
		},
		{
			"name": "Reforma Militar",
			"description": "Forças armadas são modernizadas",
			"type": "military",
			"effects": {"defense": 8, "expenses": 200},
			"duration": 3  # Custo extra por 3 meses
		},
		{
			"name": "Boa Colheita",
			"description": "Setor agrícola tem excelente desempenho",
			"type": "economic",
			"effects": {"income": 200, "stability": 3}
		},
		{
			"name": "Protestos Estudantis",
			"description": "Manifestações universitárias se espalham",
			"type": "political",
			"effects": {"rebel_power": 6, "stability": -3}
		}
	]
	
	var event = events[randi() % events.size()]
	
	# Aplicar efeitos do evento (limitados a ±10% das variáveis)
	for field in event.effects.keys():
		var effect_value = event.effects[field]
		
		# Limitar efeitos para não serem muito extremos
		if field == "money":
			effect_value = clamp(effect_value, -1000, 1000)
		elif field in ["stability", "gov_power", "rebel_power"]:
			effect_value = clamp(effect_value, -10, 10)
		elif field in ["income", "expenses"]:
			effect_value = clamp(effect_value, -500, 500)
		
		adjust_country_value(country, field, effect_value)
	
	print("📰 Evento em %s: %s - %s" % [country, event.name, event.description])
	
	# Log dos efeitos
	for field in event.effects.keys():
		print("   %s: %+d" % [field, event.effects[field]])
	
	return event

# =====================================
#  RESETAR JOGO (para GameOver)
# =====================================
func reset_game() -> void:
	print("🔄 Resetando dados do jogo...")
	
	# Resetar tempo
	current_month = 1
	current_year = 1973
	
	# Resetar país do jogador para Argentina (Cone Sul)
	player_country = "Argentina"
	
	# Recriar dados dos países com valores iniciais
	country_data = _create_initial_country_data()
	
	# Resetar relações diplomáticas
	country_relations = {}
	_initialize_relations()
	
	print("✅ Jogo resetado com sucesso!")

# =====================================
#  CRIAR DADOS INICIAIS DOS PAÍSES
# =====================================
func _create_initial_country_data() -> Dictionary:
	var initial_data = {}
	
	# Dados específicos por país (Cone Sul com economia balanceada)
	initial_data["Argentina"] = {
		"money": 10_000,
		"income": 1_500,      # Receitas fixas mensais
		"expenses": 1_200,    # Despesas fixas mensais
		"stability": 60,
		"gov_power": 60,
		"rebel_power": 40,
		"population": 45_000_000,
		"gdp": 380_000_000_000,
		"industry": 35,
		"agriculture": 25,
		"defense": 15,
		"relations": {},
		"last_update": 0,
		"is_player": true
	}
	
	initial_data["Chile"] = {
		"money": 8_200,
		"income": 1_300,
		"expenses": 1_100,
		"stability": 68,
		"gov_power": 68,
		"rebel_power": 32,
		"population": 19_000_000,
		"gdp": 250_000_000_000,
		"industry": 42,
		"agriculture": 18,
		"defense": 22,
		"relations": {},
		"last_update": 0,
		"is_player": false
	}
	
	initial_data["Uruguay"] = {
		"money": 3_500,
		"income": 800,
		"expenses": 700,
		"stability": 75,
		"gov_power": 75,
		"rebel_power": 25,
		"population": 3_500_000,
		"gdp": 55_000_000_000,
		"industry": 20,
		"agriculture": 45,
		"defense": 10,
		"relations": {},
		"last_update": 0,
		"is_player": false
	}
	
	initial_data["Paraguay"] = {
		"money": 2_800,
		"income": 600,
		"expenses": 550,
		"stability": 45,
		"gov_power": 45,
		"rebel_power": 55,
		"population": 7_000_000,
		"gdp": 35_000_000_000,
		"industry": 15,
		"agriculture": 60,
		"defense": 8,
		"relations": {},
		"last_update": 0,
		"is_player": false
	}
	
	initial_data["Bolivia"] = {
		"money": 2_200,
		"income": 500,
		"expenses": 480,
		"stability": 40,
		"gov_power": 40,
		"rebel_power": 60,
		"population": 11_500_000,
		"gdp": 38_000_000_000,
		"industry": 18,
		"agriculture": 55,
		"defense": 12,
		"relations": {},
		"last_update": 0,
		"is_player": false
	}
	
	# Não adicionar países extras - apenas Cone Sul
	# var additional_countries = ["Colombia", "Venezuela", "Peru", "Equador", "USA", "Mexico", "Canada", "Cuba"]
	
	return initial_data

# =====================================
#  INICIALIZAR RELAÇÕES DIPLOMÁTICAS
# =====================================
func _initialize_relations() -> void:
	var countries = country_data.keys()
	
	for country_a in countries:
		for country_b in countries:
			if country_a != country_b:
				var relation_key = _get_relation_key(country_a, country_b)
				if not country_relations.has(relation_key):
					country_relations[relation_key] = randi_range(30, 70)
				
				# Também inicializar no dicionário de cada país
				set_relation(country_a, country_b, country_relations[relation_key])

func _get_relation_key(country_a: String, country_b: String) -> String:
	var sorted_countries = [country_a, country_b]
	sorted_countries.sort()
	return sorted_countries[0] + "_" + sorted_countries[1]

# =====================================
#  FUNÇÕES DE DEBUG E UTILITÁRIOS
# =====================================

# Imprime dados de um país
func debug_print_country(country: String) -> void:
	var data = get_country(country)
	if data.is_empty():
		print("País '%s' não encontrado" % country)
		return
	
	print("=== %s ===" % country)
	for key in data.keys():
		if key != "relations":
			print("  %s: %s" % [key, data[key]])
	print("===============")

# Imprime relações diplomáticas
func debug_print_relations(country: String) -> void:
	var relations = get_country_value(country, "relations", {})
	print("=== Relações de %s ===" % country)
	for other_country in relations.keys():
		print("  %s: %d" % [other_country, relations[other_country]])
	print("====================")

# Reseta dados de um país para valores padrão
func reset_country_data(country: String) -> void:
	if not country_data.has(country):
		print("País '%s' não encontrado" % country)
		return
	
	# Valores padrão baseados no país
	var default_data = {
		"money": randi_range(2000, 10000),
		"stability": randi_range(40, 80),
		"gov_power": randi_range(40, 80),
		"rebel_power": randi_range(20, 60),
		"population": randi_range(1000000, 50000000),
		"gdp": randi_range(10000000000, 500000000000),
		"industry": randi_range(10, 50),
		"agriculture": randi_range(15, 70),
		"defense": randi_range(5, 30),
		"relations": {},
		"last_update": Time.get_ticks_msec(),
		"is_player": (country == player_country)
	}
	
	country_data[country] = default_data
	print("Dados de %s resetados" % country)

# =====================================
#  SISTEMA DE SAVE/LOAD
# =====================================

# Salva dados em arquivo
func save_game_data(file_path: String = "user://game_save.dat") -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("Erro ao criar arquivo de salvamento")
		return false
	
	var save_data = {
		"country_data": country_data,
		"player_country": player_country,
		"current_month": current_month,
		"current_year": current_year,
		"country_relations": country_relations,
		"save_timestamp": Time.get_unix_time_from_system()
	}
	
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("Jogo salvo em: ", file_path)
	return true

# Carrega dados de arquivo
func load_game_data(file_path: String = "user://game_save.dat") -> bool:
	if not FileAccess.file_exists(file_path):
		print("Arquivo de salvamento não encontrado")
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Erro ao abrir arquivo de salvamento")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Erro ao parsear dados do salvamento")
		return false
	
	var save_data = json.data
	
	# Carregar dados
	country_data = save_data.get("country_data", country_data)
	player_country = save_data.get("player_country", player_country)
	current_month = save_data.get("current_month", current_month)
	current_year = save_data.get("current_year", current_year)
	country_relations = save_data.get("country_relations", {})
	
	print("Jogo carregado de: ", file_path)
	return true

# =====================================
#  GETTERS PARA COMPATIBILIDADE
# =====================================
func get_current_month() -> int:
	return current_month

func get_current_year() -> int:
	return current_year

# =====================================
#  INICIALIZAÇÃO
# =====================================

func _ready() -> void:
	print("=== GLOBALS INICIALIZADO ===")
	print("Países disponíveis: ", country_data.keys())
	print("País do jogador: ", player_country)
	
	# Inicializar relações diplomáticas neutras
	_initialize_relations()
	
	print("Sistema de relações diplomáticas inicializado")
	print("==============================")
	# =====================================
#  SISTEMA DE AGENTE POLÍTICO
# =====================================
# =====================================
#  SISTEMA DE AGENTE POLÍTICO
# =====================================
func init_player_agent() -> void:
	# ↳ use TAB (⇥) em cada nível; nada de espaços!
	if current_player_agent == null:
		# placeholder até implementarmos presets (Dia 3-5)
		current_player_agent = PlayerAgent.new()
		print("✅ Agente político inicializado.")
