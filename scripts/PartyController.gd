# res://scripts/PartyController.gd
# Versão corrigida - sem erros de .get()

class_name PartyController
extends Node

# --- SINAIS ---
signal phase_advanced(old_phase, new_phase)
signal support_changed(group_name, old_value, new_value)
signal treasury_changed(old_value, new_value)
signal action_executed(action_name, success, message)

# --- DADOS E SISTEMAS ---
var party_data: PartyResource
const PartyActions = preload("res://scripts/PartyActions.gd")
var actions_manager: Node

func _ready():
	# Registra o PartyController no sistema global se disponível
	if Globals.has_method("register_party_controller"):
		Globals.register_party_controller(self)
	elif Globals:
		print("PartyController registrado (método manual)")
	
	# Inicializa os dados do partido e o gestor de ações
	party_data = PartyResource.new()
	actions_manager = PartyActions.new()
# =====================================
# LÓGICA DE AÇÕES DO PARTIDO
# =====================================

func get_available_actions() -> Array:
	if not actions_manager: 
		return []
	return actions_manager.get_available_actions(party_data)

func can_execute_action(action_name: String) -> bool:
	for action in get_available_actions():
		if action.name == action_name:
			return party_data.treasury >= action.cost
	return false

func execute_action(action_name: String):
	if not can_execute_action(action_name):
		emit_signal("action_executed", action_name, false, "Recursos insuficientes na tesouraria!")
		return

	for action in get_available_actions():
		if action.name == action_name:
			# Deduz o custo da ação
			var old_treasury = party_data.treasury
			party_data.treasury -= action.cost
			emit_signal("treasury_changed", old_treasury, party_data.treasury)

			# Calcula sucesso baseado na influência do partido
			var base_success_chance = min(0.8, party_data.influence / 25.0)
			var success = randf() < base_success_chance
			
			if success:
				var message = "Ação do partido '%s' bem-sucedida!" % action_name
				
				# Verifica se há traumas que amplificam o efeito
				var amplifier = 1.0
				if TraumaSystem:
					amplifier = TraumaSystem.check_trauma_activation(action_name)
				
				# OPERAÇÃO CONDOR: Aplicar penalidade para ações internacionais
				if _is_international_action(action_name):
					var condor_penalty = Globals.get_condor_action_penalty()
					if condor_penalty > 0:
						amplifier *= (1.0 - condor_penalty)
						message += " (Operação Condor reduziu efetividade em %.0f%%)" % (condor_penalty * 100)
						print("🕸️ CONDOR: Penalidade de %.1f aplicada à ação '%s'" % [condor_penalty, action_name])
				
				# Cria narrativas sobre a ação
				if NarrativeSystem:
					NarrativeSystem.create_narrative_from_action(action_name, party_data)
				
				# Aplica os efeitos específicos de cada ação
				_apply_action_effects(action_name, amplifier)
				
				emit_signal("action_executed", action_name, true, message)
			else:
				var message = "Ação do partido '%s' não teve o efeito esperado." % action_name
				party_data.influence = max(0, party_data.influence - 0.2)
				emit_signal("action_executed", action_name, false, message)
			return

func _is_international_action(action_name: String) -> bool:
	"""Verifica se uma ação é considerada internacional (afetada pela Operação Condor)"""
	var international_actions = [
		"Buscar Apoio Internacional",
		"Organizar Exílio",
		"Contactar Embaixadas", 
		"Lobby Internacional",
		"Missão Diplomática",
		"Rede de Solidariedade Internacional",
		"Denúncia Internacional",
		"Campanha de Direitos Humanos"
	]
	return action_name in international_actions

func _handle_condor_exile_threat():
	"""Lida com ameaças da Operação Condor durante tentativas de exílio"""
	var threat_outcomes = [
		{
			"message": "Tentativa de exílio interceptada por agentes da Operação Condor!",
			"effects": {"militants": -5, "treasury": -30, "influence": -1.0}
		},
		{
			"message": "Operação Condor compromete rota de exílio. Militantes capturados.",
			"effects": {"militants": -8, "influence": -1.5}
		},
		{
			"message": "Vigilância da Operação Condor frustra planos de exílio.",
			"effects": {"treasury": -20, "influence": -0.5}
		}
	]
	
	var threat = threat_outcomes[randi() % threat_outcomes.size()]
	
	# Aplica efeitos da ameaça
	for effect_type in threat.effects:
		match effect_type:
			"militants":
				party_data.militants += threat.effects[effect_type]
				party_data.militants = max(0, party_data.militants)
			"treasury":
				party_data.treasury += threat.effects[effect_type]
				party_data.treasury = max(0, party_data.treasury)
			"influence":
				party_data.influence += threat.effects[effect_type]
				party_data.influence = max(0, party_data.influence)
	
	emit_signal("action_executed", "Operação Condor", false, threat.message)

# =====================================
# FUNÇÕES DE EVENTOS HISTÓRICOS
# =====================================

func handle_coup_response(consequence: String):
	"""Aplica os efeitos baseados na escolha do jogador durante o golpe"""
	match consequence:
		"resist":
			party_data.influence -= 10
			_change_support("military", -20)
			_change_support("workers", 15)
			_change_support("students", 10)
			print("PARTIDO: Decidiu resistir ao golpe - consequências aplicadas")
		
		"wait_and_see":
			party_data.influence -= 5
			_change_support("intellectuals", -10)
			_change_support("workers", -10)
			_change_support("students", -5)
			print("PARTIDO: Manteve silêncio durante o golpe - consequências aplicadas")
		
		"exile":
			party_data.influence = max(1.0, party_data.influence / 4)
			party_data.treasury = max(10, party_data.treasury / 10)
			party_data.militants = max(1, party_data.militants / 4)
			party_data.is_in_exile = true  # Marca partido como exilado
			# Zera o apoio de grupos locais mas mantém algum apoio internacional
			for group_name in party_data.group_support:
				_change_support(group_name, -50)
			print("PARTIDO: Buscou exílio - consequências severas aplicadas")

	# Emite sinal para atualização da UI
	emit_signal("treasury_changed", party_data.treasury, party_data.treasury)

# =====================================
# FUNÇÕES AUXILIARES E MENSAIS
# =====================================

func _change_support(group_name: String, base_amount: int, trauma_amplifier: float = 1.0):
	"""Altera o apoio de um grupo específico"""
	var final_amount = int(base_amount * trauma_amplifier)
	
	if not party_data.group_support.has(group_name):
		printerr("ERRO: Tentou alterar apoio para um grupo inexistente: ", group_name)
		return
	
	var old_support = party_data.group_support[group_name]
	party_data.group_support[group_name] = clamp(old_support + final_amount, 0, 100)
	var new_support = party_data.group_support[group_name]
	
	if old_support != new_support:
		emit_signal("support_changed", group_name, old_support, new_support)
		print("APOIO ALTERADO: %s de %d para %d" % [group_name, old_support, new_support])

func advance_month():
	"""Processa eventos mensais do partido - INCLUINDO SISTEMA DE CONTRIBUIÇÕES"""
	
	# 1. CRESCIMENTO NATURAL DE MILITANTES
	var new_militants = int(party_data.influence / 2.0)
	party_data.militants += new_militants
	
	# 2. SISTEMA DE CONTRIBUIÇÕES DOS MILITANTES
	_process_militant_contributions()
	
	# 3. VERIFICAR DESERÇÕES POR PRESSÃO FINANCEIRA
	_check_militant_desertion()
	
	# 4. OPERAÇÃO CONDOR: Verificar ameaças mensais
	if Globals.is_condor_active():
		_check_monthly_condor_threats()
	
	# 5. PROCESSA NARRATIVAS
	if NarrativeSystem:
		NarrativeSystem.process_narrative_spread()
		NarrativeSystem.check_narrative_consequences()
	
	print("MÊS AVANÇADO: +%d militantes (total: %d)" % [new_militants, party_data.militants])

# =====================================
# SISTEMA DE CONTRIBUIÇÕES PRINCIPAL
# =====================================

func _process_militant_contributions():
	"""Sistema completo de contribuições dos militantes"""
	
	if party_data.militants <= 0:
		return
	
	# CONFIGURAÇÕES DO SISTEMA DE CONTRIBUIÇÕES
	var contribution_settings = _get_contribution_settings()
	var base_contribution = contribution_settings.base_amount
	var pressure_level = contribution_settings.pressure_level
	var loyalty_modifier = contribution_settings.loyalty_modifier
	
	# CALCULA CONTRIBUIÇÃO TOTAL
	var total_contribution = 0
	var contributing_militants = 0
	
	for i in range(party_data.militants):
		# Cada militante tem chance individual de contribuir
		var will_contribute = _militant_will_contribute(pressure_level, loyalty_modifier)
		
		if will_contribute:
			contributing_militants += 1
			# Variação individual na contribuição (80% a 120% do base)
			var individual_contribution = int(base_contribution * randf_range(0.8, 1.2))
			total_contribution += individual_contribution
	
	# APLICA CONTRIBUIÇÃO
	party_data.treasury += total_contribution
	
	# CALCULA ESTATÍSTICAS
	var participation_rate = float(contributing_militants) / float(party_data.militants) * 100
	var avg_contribution = float(total_contribution) / float(contributing_militants) if contributing_militants > 0 else 0
	
	# ARMAZENA DADOS PARA DECISÕES FUTURAS
	party_data.last_contribution_total = total_contribution
	party_data.last_participation_rate = participation_rate
	party_data.contribution_pressure = pressure_level
	
	# FEEDBACK DETALHADO
	print("💰 CONTRIBUIÇÕES: %d/%d militantes doaram %d recursos (%.1f%% participação, média %.1f)" % 
		[contributing_militants, party_data.militants, total_contribution, participation_rate, avg_contribution])
	
	# AJUSTA MORAL DO PARTIDO BASEADO NA PARTICIPAÇÃO
	_adjust_party_morale(participation_rate)

func _get_contribution_settings() -> Dictionary:
	"""Determina configurações de contribuição baseadas na estratégia atual"""
	
	# NÍVEL DE PRESSÃO CONFIGURÁVEL (futuro: controlado pelo jogador)
	var pressure_level = "medium"
	if "contribution_demand" in party_data:
		pressure_level = party_data.contribution_demand
	
	var settings = {}
	
	match pressure_level:
		"low":
			settings.base_amount = 1.5  # Contribuição baixa
			settings.pressure_level = 0.2  # Baixa pressão
			settings.loyalty_modifier = 1.1  # Bonus de lealdade
			settings.desertion_risk = 0.01  # 1% risco deserção
			
		"medium":
			settings.base_amount = 2.5  # Contribuição média
			settings.pressure_level = 0.5  # Pressão média
			settings.loyalty_modifier = 1.0  # Neutro
			settings.desertion_risk = 0.02  # 2% risco deserção
			
		"high":
			settings.base_amount = 4.0  # Contribuição alta
			settings.pressure_level = 0.8  # Alta pressão
			settings.loyalty_modifier = 0.9  # Penalty de lealdade
			settings.desertion_risk = 0.05  # 5% risco deserção
			
		"emergency":
			settings.base_amount = 6.0  # Contribuição de emergência
			settings.pressure_level = 1.0  # Pressão máxima
			settings.loyalty_modifier = 0.7  # Penalty severo
			settings.desertion_risk = 0.08  # 8% risco deserção
	
	return settings

func _militant_will_contribute(pressure_level: float, loyalty_modifier: float) -> bool:
	"""Determina se um militante individual irá contribuir"""
	
	# FATORES QUE INFLUENCIAM VONTADE DE CONTRIBUIR
	var base_willingness = 0.75  # 75% base
	
	# MODIFICADORES POSITIVOS
	base_willingness += party_data.influence * 0.02  # +2% por ponto de influência
	base_willingness += _get_group_loyalty_bonus()  # Bonus baseado no apoio dos grupos
	base_willingness *= loyalty_modifier  # Modifier do nível de pressão
	
	# MODIFICADORES NEGATIVOS
	if Globals.is_condor_active():
		base_willingness -= 0.1  # -10% com Operação Condor ativa
	
	var repression = Globals.get_country_value("Chile", "repression", 0) if Globals else 0
	base_willingness -= repression * 0.002  # -0.2% por ponto de repressão
	
	# PRESSÃO FINANCEIRA PODE FORÇAR CONTRIBUIÇÃO ALÉM DA VONTADE
	var final_chance = base_willingness + (pressure_level * 0.3)
	
	return randf() < clamp(final_chance, 0.1, 0.95)

func _get_group_loyalty_bonus() -> float:
	"""Calcula bonus de lealdade baseado no apoio dos grupos sociais"""
	
	var avg_support = party_data.get_average_support()
	
	if avg_support > 80:
		return 0.15  # +15% se apoio muito alto
	elif avg_support > 60:
		return 0.1   # +10% se apoio alto
	elif avg_support > 40:
		return 0.05  # +5% se apoio médio
	elif avg_support > 20:
		return 0.0   # Neutro se apoio baixo
	else:
		return -0.1  # -10% se apoio muito baixo

func _adjust_party_morale(participation_rate: float):
	"""Ajusta moral do partido baseado na participação nas contribuições"""
	
	# Inicializa moral se não existir
	if not "morale" in party_data:
		party_data.morale = 75.0  # Moral inicial
	
	var morale_change = 0.0
	
	if participation_rate > 85:
		morale_change = 2.0  # Excelente participação
	elif participation_rate > 70:
		morale_change = 1.0  # Boa participação
	elif participation_rate > 50:
		morale_change = 0.0  # Participação normal
	elif participation_rate > 30:
		morale_change = -1.0  # Participação baixa
	else:
		morale_change = -2.5  # Participação crítica
	
	party_data.morale = clamp(party_data.morale + morale_change, 0, 100)
	
	if abs(morale_change) > 0:
		print("📊 MORAL DO PARTIDO: %.1f (%+.1f)" % [party_data.morale, morale_change])

# =====================================
# SISTEMA DE DESERÇÃO
# =====================================

func _check_militant_desertion():
	"""Verifica se militantes abandonam o partido por pressão financeira excessiva"""
	
	if party_data.militants <= 5:  # Protege contra deserção total
		return
	
	var settings = _get_contribution_settings()
	var base_desertion_risk = settings.desertion_risk
	
	# FATORES QUE AUMENTAM DESERÇÃO
	var final_risk = base_desertion_risk
	
	# Moral baixa aumenta deserção
	var morale = 75.0
	if "morale" in party_data:
		morale = party_data.morale
	if morale < 30:
		final_risk *= 2.0  # Dobra risco se moral crítica
	elif morale < 50:
		final_risk *= 1.5  # Aumenta 50% se moral baixa
	
	# Repressão alta aumenta deserção
	var repression = Globals.get_country_value("Chile", "repression", 0) if Globals else 0
	final_risk += repression * 0.0005  # +0.05% por ponto de repressão
	
	# Operação Condor aumenta deserção
	if Globals.is_condor_active():
		final_risk += 0.01  # +1% com Condor ativa
	
	# CALCULA DESERÇÕES
	var deserters = 0
	for i in range(party_data.militants):
		if randf() < final_risk:
			deserters += 1
	
	# APLICA DESERÇÕES
	if deserters > 0:
		party_data.militants -= deserters
		party_data.militants = max(1, party_data.militants)  # Mínimo 1 militante
		
		# FEEDBACK BASEADO NA GRAVIDADE
		if deserters >= 10:
			print("🚨 DESERÇÃO MASSIVA: %d militantes abandonaram o partido!" % deserters)
			emit_signal("action_executed", "Crise Interna", false, "Pressão excessiva causou deserção massiva")
		elif deserters >= 5:
			print("⚠️ DESERÇÃO SIGNIFICATIVA: %d militantes saíram do partido" % deserters)
		else:
			print("📉 DESERÇÃO: %d militantes deixaram o partido" % deserters)

# =====================================
# FUNÇÕES DE CONTROLE FUTURAS
# =====================================

func set_contribution_demand(level: String):
	"""Permite ao jogador controlar nível de contribuições (funcionalidade futura)"""
	
	var valid_levels = ["low", "medium", "high", "emergency"]
	if level in valid_levels:
		party_data.contribution_demand = level
		print("💰 POLÍTICA DE CONTRIBUIÇÕES alterada para: %s" % level.to_upper())
		
		# Feedback imediato sobre as implicações
		var settings = _get_contribution_settings()
		print("   • Contribuição esperada: %.1f recursos/militante" % settings.base_amount)
		print("   • Risco de deserção: %.1f%%" % (settings.desertion_risk * 100))
	else:
		print("ERRO: Nível de contribuição inválido: %s" % level)

func get_contribution_stats() -> Dictionary:
	"""Retorna estatísticas detalhadas do sistema de contribuições"""
	
	var current_demand = "medium"
	if "contribution_demand" in party_data:
		current_demand = party_data.contribution_demand
	
	var last_total = 0
	if "last_contribution_total" in party_data:
		last_total = party_data.last_contribution_total
	
	var last_participation = 0
	if "last_participation_rate" in party_data:
		last_participation = party_data.last_participation_rate
	
	var morale = 75
	if "morale" in party_data:
		morale = party_data.morale
	
	var stats = {
		"current_demand": current_demand,
		"last_total": last_total,
		"last_participation": last_participation,
		"party_morale": morale,
		"projected_monthly": _calculate_projected_income()
	}
	
	return stats

func _calculate_projected_income() -> int:
	"""Calcula renda mensal projetada baseada nas configurações atuais"""
	
	if party_data.militants <= 0:
		return 0
	
	var settings = _get_contribution_settings()
	var expected_participation = _militant_will_contribute(settings.pressure_level, settings.loyalty_modifier)
	var expected_contributors = int(party_data.militants * (0.75 if expected_participation else 0.5))
	
	return int(expected_contributors * settings.base_amount)

# =====================================
# FUNÇÕES DE DEBUG E MONITORAMENTO
# =====================================

func debug_contribution_system():
	"""Imprime status completo do sistema de contribuições"""
	
	print("=== SISTEMA DE CONTRIBUIÇÕES ===")
	var stats = get_contribution_stats()
	
	print("Militantes: %d" % party_data.militants)
	print("Política atual: %s" % stats.current_demand.to_upper())
	print("Última arrecadação: %d recursos" % stats.last_total)
	print("Participação: %.1f%%" % stats.last_participation)
	print("Moral do partido: %.1f" % stats.party_morale)
	print("Projeção mensal: %d recursos" % stats.projected_monthly)
	print("Tesouraria atual: %d" % party_data.treasury)
	print("===============================")

# =====================================
# INTEGRAÇÃO COM AÇÕES DO PARTIDO
# =====================================

# Adicione esta ação em PartyActions.gd:
# {"name": "Campanha de Arrecadação", "cost": 0, "description": "Intensifica esforços de contribuição dos militantes"}

# E este efeito em _apply_action_effects():
func _apply_special_contribution_effects(action_name: String, amplifier: float):
	"""Efeitos especiais relacionados ao sistema de contribuições"""
	
	match action_name:
		"Campanha de Arrecadação":
			# Melhora temporariamente a participação
			var current_boost = 0
			if "contribution_boost" in party_data:
				current_boost = party_data.contribution_boost
			party_data.contribution_boost = current_boost + 2
			
			var current_morale = 75.0
			if "morale" in party_data:
				current_morale = party_data.morale
			party_data.morale = clamp(current_morale + 5, 0, 100)
			print("📢 CAMPANHA: Militantes motivados a contribuir mais")
		
		"Reduzir Pressão Financeira":
			# Diminui nível de contribuição temporariamente
			var current_demand = "medium"
			if "contribution_demand" in party_data:
				current_demand = party_data.contribution_demand
			
			if current_demand == "high":
				set_contribution_demand("medium")
			elif current_demand == "medium":
				set_contribution_demand("low")
			print("💸 ALÍVIO: Pressão sobre militantes reduzida")

func _check_monthly_condor_threats():
	"""Verifica ameaças mensais da Operação Condor"""
	var risk_chance = 0
	
	# Calcula chance de ameaça baseada em fatores de risco
	# CORRIGIDO: Verificar se propriedades existem antes de usar
	if "is_in_exile" in party_data and party_data.is_in_exile:
		risk_chance += 15
	
	var current_exposure = 0
	if "condor_exposure" in party_data:
		current_exposure = party_data.condor_exposure
	if current_exposure > 2:
		risk_chance += 10
	
	if party_data.influence > 5:
		risk_chance += 5
	
	# Base: 5% chance por mês se Condor ativa
	risk_chance += 5
	
	if randi() % 100 < risk_chance:
		_apply_condor_monthly_threat()

func _apply_condor_monthly_threat():
	"""Aplica uma ameaça mensal da Operação Condor"""
	var threats = [
		{
			"type": "surveillance", 
			"message": "Agentes da Operação Condor intensificam vigilância sobre o partido.",
			"effects": {"influence": -0.3}
		},
		{
			"type": "harassment",
			"message": "Militantes relatam perseguição por agentes internacionais.",
			"effects": {"militants": -2, "treasury": -15}
		},
		{
			"type": "infiltration",
			"message": "Suspeita de infiltração nos círculos do partido.",
			"effects": {"influence": -0.5, "support_penalty": 2}
		},
		{
			"type": "communication_block",
			"message": "Operação Condor intercepta comunicações internacionais do partido.",
			"effects": {"treasury": -10, "influence": -0.2}
		}
	]
	
	var threat = threats[randi() % threats.size()]
	
	# Aplica efeitos
	for effect in threat.effects:
		match effect:
			"influence":
				party_data.influence += threat.effects[effect]
				party_data.influence = max(0, party_data.influence)
			"militants":
				party_data.militants += threat.effects[effect]
				party_data.militants = max(0, party_data.militants)
			"treasury":
				party_data.treasury += threat.effects[effect]
				party_data.treasury = max(0, party_data.treasury)
			"support_penalty":
				var penalty = threat.effects[effect]
				for group in party_data.group_support:
					_change_support(group, -penalty)
	
	emit_signal("action_executed", "Ameaça Condor", false, threat.message)
	print("🕸️ AMEAÇA CONDOR MENSAL: %s" % threat.type)

func get_average_support() -> float:
	"""Retorna o apoio médio entre todos os grupos"""
	if party_data: 
		return party_data.get_average_support()
	return 0.0

func attempt_network_discovery(network_id: String):
	"""Tenta descobrir uma rede clandestina"""
	var cost = 50
	if party_data.treasury < cost:
		emit_signal("action_executed", "Investigar Rede", false, "Custo de %d, você não tem recursos suficientes." % cost)
		return
	
	party_data.treasury -= cost
	var success_chance = party_data.influence / 100.0
	
	if randf() < success_chance:
		emit_signal("action_executed", "Investigar Rede", true, "Rede '%s' descoberta com sucesso!" % network_id)
		# TODO: Adicionar lógica para revelar informações da rede
	else:
		emit_signal("action_executed", "Investigar Rede", false, "Investigação não revelou informações úteis sobre '%s'." % network_id)

# =====================================
# GETTERS PARA DEBUGGING E UI
# =====================================

func get_party_info() -> Dictionary:
	"""Retorna informações completas do partido para debugging"""
	var info = {
		"name": party_data.party_name,
		"phase": party_data.get_phase_name(),
		"influence": party_data.influence,
		"treasury": party_data.treasury,
		"militants": party_data.militants,
		"support": party_data.group_support,
		"average_support": get_average_support()
	}
	
	# CORRIGIDO: Verificar se propriedades existem
	if party_data.has("is_in_exile"):
		info["is_in_exile"] = party_data.is_in_exile
	else:
		info["is_in_exile"] = false
	
	# Adiciona informações da Operação Condor se ativa
	if Globals.is_condor_active():
		if party_data.has("condor_exposure"):
			info["condor_exposure"] = party_data.condor_exposure
		else:
			info["condor_exposure"] = 0
		info["condor_risk"] = Globals.get_condor_exile_risk()
		info["condor_penalty"] = Globals.get_condor_action_penalty()
	
	return info
	
	# Adicione estes casos na função _apply_action_effects():

func _apply_action_effects(action_name: String, amplifier: float):
	"""Aplica os efeitos específicos de cada ação do partido"""
	match action_name:
		# AÇÕES EXISTENTES
		"Realizar Debate Ideológico":
			party_data.influence += 0.5 * amplifier
			_change_support("intellectuals", 2, amplifier)
		
		"Distribuir Panfletos":
			party_data.militants += int(5 * amplifier)
			_change_support("workers", 2, amplifier)
		
		"Organizar Protesto Local":
			party_data.influence += 1.0 * amplifier
			_change_support("workers", 3, amplifier)
			_change_support("students", 2, amplifier)
			_change_support("business", -1, amplifier)
			_change_support("military", -1, amplifier)
		
		"Publicar Manifesto":
			party_data.influence += 0.8 * amplifier
			_change_support("intellectuals", 3, amplifier)
			_change_support("students", 2, amplifier)
			_change_support("church", -1, amplifier)
		
		# NOVAS AÇÕES - FASE INFORMAL
		"Recrutar Intelectuais":
			party_data.militants += int(3 * amplifier)
			party_data.influence += 0.3 * amplifier
			_change_support("intellectuals", 4, amplifier)
			_change_support("students", 2, amplifier)
			# Pode atrair atenção negativa
			if randf() < 0.3:
				_change_support("military", -1, amplifier)
		
		"Organizar Célula Clandestina":
			party_data.militants += int(2 * amplifier)
			party_data.influence += 0.4 * amplifier
			# Reduz visibilidade (menos repressão)
			var current_visibility = 0
			if "visibility" in party_data:
				current_visibility = party_data.visibility
			party_data.visibility = current_visibility - 1
			_change_support("workers", 1, amplifier)
			# Risco de descoberta
			if randf() < 0.2:
				party_data.militants -= 3
				print("CÉLULA DESCOBERTA: 3 militantes perdidos")
		
		"Buscar Financiamento":
			var funding = int(randi_range(10, 30) * amplifier)
			party_data.treasury += funding
			party_data.influence += 0.1 * amplifier
			_change_support("business", 1, amplifier)  # Alguns empresários simpatizam
			print("FINANCIAMENTO: +%d recursos obtidos" % funding)
		
		"Infiltrar Universidade":
			party_data.influence += 0.6 * amplifier
			_change_support("students", 5, amplifier)
			_change_support("intellectuals", 3, amplifier)
			party_data.militants += int(4 * amplifier)
			# Reação negativa do regime
			_change_support("military", -2, amplifier)
		
		# NOVAS AÇÕES - MOVIMENTO LOCAL
		"Organizar Greve":
			party_data.influence += 1.5 * amplifier
			_change_support("workers", 6, amplifier)
			# Impacto econômico negativo no regime
			if Globals:
				Globals.adjust_country_value("Chile", "economic_disruption", 5)
			# Forte reação negativa
			_change_support("business", -4, amplifier)
			_change_support("military", -3, amplifier)
			# Risco de repressão
			if randf() < 0.4:
				party_data.militants -= int(5 * amplifier)
				print("REPRESSÃO: Greve foi reprimida, militantes perdidos")
		
		"Criar Jornal Underground":
			party_data.influence += 1.2 * amplifier
			_change_support("intellectuals", 4, amplifier)
			_change_support("students", 3, amplifier)
			_change_support("workers", 2, amplifier)
			# Gera narrativas mais efetivas
			var current_media = 0
			if "media_power" in party_data:
				current_media = party_data.media_power
			party_data.media_power = current_media + 1
		
		"Infiltrar Sindicatos":
			party_data.influence += 1.0 * amplifier
			_change_support("workers", 8, amplifier)
			party_data.militants += int(6 * amplifier)
			# Controle sindical
			var current_union = 0
			if "union_control" in party_data:
				current_union = party_data.union_control
			party_data.union_control = current_union + 1
		
		"Formar Milícia Popular":
			party_data.militants += int(10 * amplifier)
			party_data.influence += 0.8 * amplifier
			_change_support("workers", 4, amplifier)
			_change_support("students", 2, amplifier)
			# Forte reação militar
			_change_support("military", -5, amplifier)
			_change_support("business", -3, amplifier)
			_change_support("church", -2, amplifier)
			# Capacidade militar
			var current_military = 0
			if "military_capacity" in party_data:
				current_military = party_data.military_capacity
			party_data.military_capacity = current_military + 2
		
		"Rede de Apoio Internacional":
			party_data.influence += 0.5 * amplifier
			party_data.treasury += int(20 * amplifier)
			_change_support("intellectuals", 2, amplifier)
			# Proteção internacional (reduz efeitos da Operação Condor)
			var current_protection = 0
			if "international_protection" in party_data:
				current_protection = party_data.international_protection
			party_data.international_protection = current_protection + 1
			# Pode atrair Operação Condor
			if Globals and Globals.is_condor_active():
				if randf() < 0.3:
					_handle_condor_international_threat()
		
		"Sabotagem Econômica":
			party_data.influence += 1.8 * amplifier
			_change_support("workers", 3, amplifier)
			# Impacto econômico significativo
			if Globals:
				Globals.adjust_country_value("Chile", "economic_disruption", 10)
			# Reação severa
			_change_support("military", -6, amplifier)
			_change_support("business", -5, amplifier)
			# Alto risco de repressão
			if randf() < 0.6:
				party_data.militants -= int(8 * amplifier)
				party_data.influence -= 0.5
				print("REPRESSÃO SEVERA: Sabotagem descoberta, perdas pesadas")
		
		# AÇÕES REGIONAIS
		"Coordenar Resistência Nacional":
			party_data.influence += 3.0 * amplifier
			_change_support("workers", 5, amplifier)
			_change_support("students", 4, amplifier)
			_change_support("intellectuals", 3, amplifier)
			# Reação do regime
			_change_support("military", -4, amplifier)
		
		"Operar Rádio Clandestina":
			party_data.influence += 2.5 * amplifier
			# Atinge todos os grupos
			for group in party_data.group_support:
				_change_support(group, 2, amplifier)
			var current_media = 0
			if "media_power" in party_data:
				current_media = party_data.media_power
			party_data.media_power = current_media + 3
		
		"Estabelecer Governo Paralelo":
			party_data.influence += 4.0 * amplifier
			party_data.militants += int(15 * amplifier)
			# Legitimidade alternativa
			var current_legitimacy = 0
			if "legitimacy" in party_data:
				current_legitimacy = party_data.legitimacy
			party_data.legitimacy = current_legitimacy + 2
			# Reação extrema do regime
			_change_support("military", -8, amplifier)
		
		"Operação de Exfiltração":
			party_data.influence += 1.0 * amplifier
			# Salva militantes em risco
			var saved = int(5 * amplifier)
			party_data.militants += saved
			_change_support("intellectuals", 3, amplifier)
			print("EXFILTRAÇÃO: %d militantes salvos" % saved)
		
		"Infiltrar Forças Armadas":
			party_data.influence += 2.0 * amplifier
			_change_support("military", 3, amplifier)  # Alguns militares simpatizam
			# Informação privilegiada
			var current_intel = 0
			if "military_intelligence" in party_data:
				current_intel = party_data.military_intelligence
			party_data.military_intelligence = current_intel + 1
			# Risco extremo se descoberto
			if randf() < 0.4:
				party_data.militants -= int(12 * amplifier)
				party_data.influence -= 1.0
				print("INFILTRAÇÃO DESCOBERTA: Perdas severas")
		
		# AÇÕES NACIONAIS
		"Preparar Insurreição":
			party_data.influence += 5.0 * amplifier
			party_data.militants += int(20 * amplifier)
			var current_military = 0
			if "military_capacity" in party_data:
				current_military = party_data.military_capacity
			party_data.military_capacity = current_military + 5
			# Polarização extrema
			_change_support("workers", 8, amplifier)
			_change_support("students", 6, amplifier)
			_change_support("military", -10, amplifier)
			_change_support("business", -8, amplifier)
		
		"Negociar Transição":
			party_data.influence += 3.0 * amplifier
			_change_support("intellectuals", 6, amplifier)
			_change_support("middle_class", 4, amplifier)
			_change_support("business", 2, amplifier)
			# Pode decepcionar radicais
			_change_support("workers", -2, amplifier)
		
		"Mobilização Geral":
			party_data.influence += 6.0 * amplifier
			party_data.militants += int(30 * amplifier)
			# Mobiliza toda oposição
			for group in ["workers", "students", "intellectuals"]:
				_change_support(group, 10, amplifier)
		
		"Operação Libertação":
			# Ação final - efeitos dependem do contexto
			var success_chance = _calculate_liberation_success()
			if randf() < success_chance:
				party_data.influence += 10.0 * amplifier
				print("VITÓRIA: Operação Libertação bem-sucedida!")
				_trigger_liberation_victory()
			else:
				party_data.influence = max(1.0, party_data.influence / 4)
				party_data.militants = max(10, party_data.militants / 3)
				print("DERROTA: Operação Libertação falhou")
		
		_:
			print("AVISO: Efeitos não definidos para a ação '%s'" % action_name)

# NOVAS FUNÇÕES DE APOIO
func _handle_condor_international_threat():
	"""Ameaça específica da Operação Condor para ações internacionais"""
	var threats = [
		"Operação Condor intercepta comunicações internacionais",
		"Agentes Condor ameaçam colaboradores estrangeiros",
		"Rede internacional do partido comprometida"
	]
	var threat = threats[randi() % threats.size()]
	party_data.treasury -= 15
	party_data.influence -= 0.3
	emit_signal("action_executed", "Ameaça Condor", false, threat)

func _calculate_liberation_success() -> float:
	"""Calcula chance de sucesso da Operação Libertação"""
	var base_chance = 0.1  # 10% base
	
	# Fatores que aumentam chance
	base_chance += party_data.influence * 0.02  # +2% por ponto de influência
	
	var military_cap = 0
	if "military_capacity" in party_data:
		military_cap = party_data.military_capacity
	base_chance += military_cap * 0.05  # +5% por capacidade militar
	
	var union_ctrl = 0
	if "union_control" in party_data:
		union_ctrl = party_data.union_control
	base_chance += union_ctrl * 0.1  # +10% por controle sindical
	
	var legitimacy = 0
	if "legitimacy" in party_data:
		legitimacy = party_data.legitimacy
	base_chance += legitimacy * 0.15  # +15% por legitimidade
	
	# Fatores do contexto global
	if Globals:
		var repression = Globals.get_country_value("Chile", "repression", 50)
		var resistance = Globals.get_country_value("Chile", "civil_resistance", 0)
		base_chance -= repression * 0.005  # -0.5% por ponto de repressão
		base_chance += resistance * 0.01   # +1% por ponto de resistência
	
	return clamp(base_chance, 0.05, 0.8)  # Entre 5% e 80%

func _trigger_liberation_victory():
	"""Dispara sequência de vitória"""
	emit_signal("action_executed", "VITÓRIA HISTÓRICA", true, "O regime militar foi derrubado! A democracia retorna ao Chile!")
	# TODO: Implementar sequência de final do jogo

# Sistema de contribuições
var last_contribution_total: int = 0
var last_participation_rate: float = 0.0
var contribution_pressure: String = "medium"
var contribution_demand: String = "medium"
var morale: float = 75.0
var contribution_boost: int = 0
