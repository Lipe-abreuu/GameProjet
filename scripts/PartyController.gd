# res://scripts/PartyController.gd
# Versão final e corrigida.

class_name PartyController
extends Node

signal phase_advanced(old_phase, new_phase)
signal support_changed(group_name, old_value, new_value)
signal treasury_changed(old_value, new_value)
signal action_executed(action_name, success, message)

var party_data: PartyResource
# CORREÇÃO: Carregando o novo PartyActions.gd
const PartyActions = preload("res://scripts/PartyActions.gd")
var actions_manager: Node

func _ready():
	party_data = PartyResource.new()
	# CORREÇÃO: Instanciando o novo PartyActions
	actions_manager = PartyActions.new()

func get_available_actions() -> Array:
	if not actions_manager: return []
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
			var old_treasury = party_data.treasury
			party_data.treasury -= action.cost
			emit_signal("treasury_changed", old_treasury, party_data.treasury)

			var success = randf() < (party_data.influence / 10.0)
			if success:
				var message = "Ação do partido '%s' bem-sucedida!" % action_name
				var amplifier = TraumaSystem.check_trauma_activation(action_name)
				NarrativeSystem.create_narrative_from_action(action_name, party_data)
				
				match action_name:
					"Realizar Debate Ideológico":
						party_data.influence += 0.5 * amplifier
						_change_support("intellectuals", 2, amplifier)
					"Distribuir Panfletos":
						party_data.militants += 5
						_change_support("workers", 2, amplifier)

				emit_signal("action_executed", action_name, true, message)
			else:
				var message = "A ação do partido '%s' não teve o efeito esperado." % action_name
				party_data.influence = max(0, party_data.influence - 0.2)
				emit_signal("action_executed", action_name, false, message)
			return

func _change_support(group_name: String, base_amount: int, trauma_amplifier: float = 1.0):
	var final_amount = int(base_amount * trauma_amplifier)
	if not party_data.group_support.has(group_name):
		return
	var old_support = party_data.group_support[group_name]
	party_data.group_support[group_name] = clamp(old_support + final_amount, 0, 100)
	var new_support = party_data.group_support[group_name]
	if old_support != new_support:
		emit_signal("support_changed", group_name, old_support, new_support)

func advance_month():
	party_data.militants += int(party_data.influence / 2.0)

func get_average_support() -> float:
	if party_data: return party_data.get_average_support()
	return 0.0

func attempt_network_discovery(network_id: String):
	var cost = 50
	if party_data.treasury < cost:
		emit_signal("action_executed", "Investigar Rede", false, "Custo de %d, você não tem recursos suficientes." % cost)
		return
	var old_treasury = party_data.treasury
	party_data.treasury -= cost
	emit_signal("treasury_changed", old_treasury, party_data.treasury)
	
	var network = PowerNetworks.hidden_networks.get(network_id)
	if not network:
		return
	
	var discovery_chance = (party_data.influence + party_data.militants) / 1000.0
	
	if randf() < discovery_chance:
		network["discovered"] = true
		emit_signal("action_executed", "Investigar Rede", true, "Sucesso! Você descobriu a rede: %s" % network["name"])
	else:
		emit_signal("action_executed", "Investigar Rede", false, "A investigação não revelou nada de concreto.")
