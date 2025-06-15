# Combat.gd - Sistema de combate simplificado integrado com dados centralizados

extends Node

# =====================================
#  ESTRUTURAS DE DADOS
# =====================================

# Conflitos ativos (formato simples)
var active_conflicts := {}

# =====================================
#  SISTEMA DE COMBATE
# =====================================

# Chamado pelo Main.gd para migrar para o sistema centralizado
func use_global_data() -> void:
	print("Combat.gd agora usando sistema centralizado de dados")

# Resolver combates mensais
func resolve_combat() -> void:
	_check_new_conflicts()
	_resolve_active_combats()
	_update_active_conflicts()

# Verificar novos conflitos
func _check_new_conflicts() -> void:
	# Chance baixa de novo conflito (5%)
	if randi() % 100 < 5:
		_initiate_random_conflict()

# Iniciar conflito aleatório
func _initiate_random_conflict() -> void:
	var countries = Globals.country_data.keys()
	if countries.size() < 2:
		return
	
	# Escolher dois países aleatórios com baixa relação
	var country1 = countries[randi() % countries.size()]
	var country2 = countries[randi() % countries.size()]
	
	# Evitar conflito consigo mesmo
	if country1 == country2:
		return
	
	var relation = Globals.get_relation(country1, country2)
	if relation < -20:  # Só se a relação for muito ruim
		start_conflict(country1, country2)

# Iniciar conflito entre dois países
func start_conflict(country1: String, country2: String) -> String:
	var conflict_id = "conflict_" + str(Time.get_ticks_msec())
	
	var conflict = {
		"id": conflict_id,
		"country1": country1,
		"country2": country2,
		"duration": 0,
		"intensity": 1  # 1-3, escalação do conflito
	}
	
	active_conflicts[conflict_id] = conflict
	
	print("🔥 Novo conflito iniciado: %s vs %s" % [country1, country2])
	
	# Impacto diplomático imediato
	Globals.adjust_relation(country1, country2, randi_range(-15, -25))
	
	# Afetar estabilidade
	Globals.adjust_country_value(country1, "stability", randi_range(-5, -2))
	Globals.adjust_country_value(country2, "stability", randi_range(-5, -2))
	
	return conflict_id

# Resolver combates ativos
func _resolve_active_combats() -> void:
	for conflict_id in active_conflicts.keys():
		var conflict = active_conflicts[conflict_id]
		_resolve_conflict_round(conflict)

# Resolver uma rodada de conflito
func _resolve_conflict_round(conflict: Dictionary) -> void:
	var country1 = conflict.country1
	var country2 = conflict.country2
	
	# Obter capacidades militares
	var country1_power = _calculate_military_power(country1)
	var country2_power = _calculate_military_power(country2)
	
	# Determinar resultado da rodada
	var total_power = country1_power + country2_power
	var country1_advantage = country1_power / total_power if total_power > 0 else 0.5
	
	var battle_result = randf()
	
	if battle_result < country1_advantage:
		# País 1 vence a rodada
		_apply_battle_victory(country1, country2, conflict)
	else:
		# País 2 vence a rodada
		_apply_battle_victory(country2, country1, conflict)

# Calcular poder militar de um país
func _calculate_military_power(country: String) -> float:
	var defense = Globals.get_country_value(country, "defense", 10)
	var money = Globals.get_country_value(country, "money", 1000)
	var stability = Globals.get_country_value(country, "stability", 50)
	
	# Fórmula simples de poder militar
	var base_power = defense * 2
	var economic_support = (money / 1000) * 0.1
	var stability_modifier = stability / 100.0
	
	var total_power = (base_power + economic_support) * stability_modifier
	return max(1.0, total_power)

# Aplicar resultado de vitória em batalha
func _apply_battle_victory(winner: String, loser: String, _conflict: Dictionary) -> void:
	print("⚔️ %s vence batalha contra %s" % [winner, loser])
	
	# Custos da batalha
	var winner_cost = randi_range(200, 500)
	var loser_cost = randi_range(400, 800)
	
	# Aplicar custos
	Globals.adjust_country_value(winner, "money", -winner_cost)
	Globals.adjust_country_value(loser, "money", -loser_cost)
	
	# Afetar moral e estabilidade
	Globals.adjust_country_value(winner, "stability", randi_range(1, 3))
	Globals.adjust_country_value(winner, "gov_power", randi_range(1, 2))
	
	Globals.adjust_country_value(loser, "stability", randi_range(-4, -1))
	Globals.adjust_country_value(loser, "gov_power", randi_range(-3, -1))

# Atualizar conflitos ativos
func _update_active_conflicts() -> void:
	var conflicts_to_remove = []
	
	for conflict_id in active_conflicts.keys():
		var conflict = active_conflicts[conflict_id]
		conflict.duration += 1
		
		# Verificar se conflito deve terminar
		if _should_conflict_end(conflict):
			_end_conflict(conflict_id)
			conflicts_to_remove.append(conflict_id)
	
	# Remover conflitos terminados
	for conflict_id in conflicts_to_remove:
		active_conflicts.erase(conflict_id)

# Verificar se conflito deve terminar
func _should_conflict_end(conflict: Dictionary) -> bool:
	var country1 = conflict.country1
	var country2 = conflict.country2
	
	# Término por falta de recursos
	var country1_money = Globals.get_country_value(country1, "money", 0)
	var country2_money = Globals.get_country_value(country2, "money", 0)
	
	if country1_money < 500 or country2_money < 500:
		return true
	
	# Término por baixa estabilidade
	var country1_stability = Globals.get_country_value(country1, "stability", 50)
	var country2_stability = Globals.get_country_value(country2, "stability", 50)
	
	if country1_stability < 15 or country2_stability < 15:
		return true
	
	# Término por duração longa
	if conflict.duration > 12:  # 1 ano
		return true
	
	# Chance aleatória de paz (10% por mês)
	if randi() % 100 < 10:
		return true
	
	return false

# Terminar conflito
func _end_conflict(conflict_id: String) -> void:
	var conflict = active_conflicts[conflict_id]
	
	print("🏳️ Conflito terminado: %s vs %s (duração: %d meses)" % [conflict.country1, conflict.country2, conflict.duration])
	
	# Determinar vencedor baseado em condições atuais
	var winner = _determine_conflict_winner(conflict)
	_apply_peace_settlement(conflict, winner)

# Determinar vencedor do conflito
func _determine_conflict_winner(conflict: Dictionary) -> String:
	var country1 = conflict.country1
	var country2 = conflict.country2
	
	var country1_power = _calculate_military_power(country1)
	var country2_power = _calculate_military_power(country2)
	
	# Vencedor é quem tem mais poder militar restante
	if country1_power > country2_power:
		return country1
	elif country2_power > country1_power:
		return country2
	else:
		return "draw"  # Empate

# Aplicar acordo de paz
func _apply_peace_settlement(conflict: Dictionary, winner: String) -> void:
	var country1 = conflict.country1
	var country2 = conflict.country2
	var loser = ""
	
	if winner == country1:
		loser = country2
	elif winner == country2:
		loser = country1
	
	print("📜 Acordo de paz: %s" % ("Vitória de " + winner if winner != "draw" else "Empate"))
	
	if winner != "draw":
		# Vencedor ganha benefícios
		Globals.adjust_country_value(winner, "stability", randi_range(5, 10))
		Globals.adjust_country_value(winner, "gov_power", randi_range(3, 8))
		Globals.adjust_country_value(winner, "money", randi_range(300, 1000))  # Reparações
		
		# Perdedor sofre penalidades
		Globals.adjust_country_value(loser, "stability", randi_range(-8, -3))
		Globals.adjust_country_value(loser, "gov_power", randi_range(-6, -2))
		Globals.adjust_country_value(loser, "money", randi_range(-1000, -300))  # Reparações
	else:
		# Empate - ambos sofrem um pouco
		Globals.adjust_country_value(country1, "stability", randi_range(-3, 1))
		Globals.adjust_country_value(country2, "stability", randi_range(-3, 1))
	
	# Normalizar relações (mas ainda negativas)
	Globals.set_relation(country1, country2, randi_range(-20, -5))

# =====================================
#  FUNÇÕES UTILITÁRIAS
# =====================================

# Obter conflitos ativos de um país
func get_country_conflicts(country: String) -> Array:
	var conflicts = []
	for conflict in active_conflicts.values():
		if country in [conflict.country1, conflict.country2]:
			conflicts.append(conflict)
	return conflicts

# Verificar se país está em guerra
func is_country_at_war(country: String) -> bool:
	return get_country_conflicts(country).size() > 0

# =====================================
#  FUNÇÕES DE DEBUG
# =====================================

# Debug: Forçar conflito entre países
func debug_start_conflict(country1: String, country2: String) -> void:
	print("DEBUG: Iniciando conflito %s vs %s" % [country1, country2])
	start_conflict(country1, country2)

# Debug: Terminar todos os conflitos
func debug_end_all_conflicts() -> void:
	print("DEBUG: Terminando todos os conflitos")
	for conflict_id in active_conflicts.keys():
		_end_conflict(conflict_id)
	active_conflicts.clear()

# Debug: Listar conflitos ativos
func debug_list_conflicts() -> void:
	print("=== CONFLITOS ATIVOS ===")
	for conflict in active_conflicts.values():
		print("%s vs %s (duração: %d)" % [conflict.country1, conflict.country2, conflict.duration])

# =====================================
#  INICIALIZAÇÃO
# =====================================

func _ready() -> void:
	print("=== COMBAT SYSTEM INICIALIZADO (Versão Simplificada) ===")
