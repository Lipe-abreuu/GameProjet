# res://scripts/PartyController.gd
# Versão final corrigida

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
	# Anuncia a sua existência para todo o jogo
	Globals.party_controller = self
	
	# Inicializa os dados do partido e o gestor de ações
	party_data = PartyResource.new()
	actions_manager = PartyActions.new()
	
	print("PartyController inicializado com partido: %s" % party_data.party_name)

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
			var success = randf() < (party_data.influence / 10.0)
			
			if success:
				var message = "Ação do partido '%s' bem-sucedida!" % action_name
				
				# Verifica se há traumas que amplificam o efeito
				var amplifier = 1.0
				if TraumaSystem:
					amplifier = TraumaSystem.check_trauma_activation(action_name)
				
				# CORRIGIDO: Agora passa party_data corretamente como PartyResource
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
		
		# Adicione mais ações conforme necessário
		_:
			print("AVISO: Efeitos não definidos para a ação '%s'" % action_name)

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
	
	# Processa narrativas se o sistema estiver disponível
	if NarrativeSystem:
		NarrativeSystem.process_narrative_spread()
		NarrativeSystem.check_narrative_consequences()
	
	print("MÊS AVANÇADO: +%d militantes (total: %d)" % [new_militants, party_data.militants])

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
	return {
		"name": party_data.party_name,
		"phase": party_data.get_phase_name(),
		"influence": party_data.influence,
		"treasury": party_data.treasury,
		"militants": party_data.militants,
		"support": party_data.group_support,
		"average_support": get_average_support()
	}

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
	print("Apoio por Grupo:")
	for group in info.support:
		print("  - %s: %d%%" % [group, info.support[group]])
	print("=========================")
