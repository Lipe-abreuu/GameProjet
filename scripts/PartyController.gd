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

func _apply_action_effects(action_name: String, amplifier: float):
	"""Aplica os efeitos específicos de cada ação do partido"""
	match action_name:
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
			# Protesto pode gerar reação negativa de outros grupos
			_change_support("business", -1, amplifier)
			_change_support("military", -1, amplifier)
		
		"Publicar Manifesto":
			party_data.influence += 0.8 * amplifier
			_change_support("intellectuals", 3, amplifier)
			_change_support("students", 2, amplifier)
			# Manifesto pode assustar grupos conservadores
			_change_support("church", -1, amplifier)
		
		"Buscar Apoio Internacional":
			party_data.influence += 0.3 * amplifier
			_change_support("intellectuals", 1, amplifier)
			# Ação internacional tem risco adicional sob Condor
			if Globals.is_condor_active():
				# CORRIGIDO: Usar sintaxe correta para valores opcionais
				var current_exposure = 0
				if party_data.has("condor_exposure"):
					current_exposure = party_data.condor_exposure
				party_data.condor_exposure = current_exposure + 1
		
		"Organizar Exílio":
			# Ação perigosa sob Operação Condor
			if Globals.is_condor_active():
				var exile_risk = Globals.get_condor_exile_risk()
				if randi() % 100 < exile_risk:
					_handle_condor_exile_threat()
			party_data.influence += 0.2 * amplifier
			_change_support("intellectuals", 1, amplifier)
		
		# Adicione mais ações conforme necessário
		_:
			print("AVISO: Efeitos não definidos para a ação '%s'" % action_name)

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
	"""Processa eventos mensais do partido"""
	# Crescimento natural de militantes baseado na influência
	var new_militants = int(party_data.influence / 2.0)
	party_data.militants += new_militants
	
	# OPERAÇÃO CONDOR: Verificar ameaças mensais
	if Globals.is_condor_active():
		_check_monthly_condor_threats()
	
	# Processa narrativas se o sistema estiver disponível
	if NarrativeSystem:
		NarrativeSystem.process_narrative_spread()
		NarrativeSystem.check_narrative_consequences()
	
	print("MÊS AVANÇADO: +%d militantes (total: %d)" % [new_militants, party_data.militants])

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
                var message := "Rede '%s' descoberta com sucesso!" % network_id
                if PowerNetworks and PowerNetworks.hidden_networks.has(network_id):
                        var network = PowerNetworks.hidden_networks[network_id]
                        network["discovered"] = true
                        PowerNetworks.hidden_networks[network_id] = network
                        message = "Rede '%s' descoberta! Membros: %s" % [network["name"], ", ".join(network["members"])]
                        print("✅ Investigação revelou detalhes da rede '%s'" % network_id)
                emit_signal("action_executed", "Investigar Rede", true, message)
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

func debug_print_status():
	"""Imprime status completo do partido no console"""
	var info = get_party_info()
	print("=== STATUS DO PARTIDO ===")
	print("Nome: %s" % info.name)
	print("Fase: %s" % info.phase)
	print("Influência: %.1f" % info.influence)
	print("Tesouraria: %d" % info.treasury)
	print("Militantes: %d" % info.militants)
	print("Apoio Médio: %.1f%%" % info.average_support)
	
	if info.has("is_in_exile") and info.is_in_exile:
		print("STATUS: No exílio")
	
	if Globals.is_condor_active():
		print("--- OPERAÇÃO CONDOR ---")
		print("Status: %s" % Globals.get_condor_status_text())
		print("Exposição: %d" % info.get("condor_exposure", 0))
		print("Risco de Exílio: %d%%" % info.get("condor_risk", 0))
		print("Penalidade Ações: %.1f%%" % (info.get("condor_penalty", 0) * 100))
	
	print("Apoio por Grupo:")
	for group in info.support:
		print("  - %s: %d%%" % [group, info.support[group]])
	print("=========================")
