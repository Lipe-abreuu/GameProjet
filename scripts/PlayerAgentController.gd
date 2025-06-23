# =====================================
#  PLAYERAGENTCONTROLLER.GD - LÓGICA DO AGENTE
# =====================================
# IMPORTANTE: Este arquivo deve ser salvo como PlayerAgentController.gd
class_name PlayerAgentController
extends Node

signal position_advanced(old_position: String, new_position: String)
signal support_changed(group: String, old_value: int, new_value: int)
signal wealth_changed(old_value: int, new_value: int)
signal action_executed(action_name: String, success: bool, message: String)

@export var agent_data: PlayerAgentResource

const POSITION_REQUIREMENTS = {
	1: {"experience": 50, "min_support": 70},    # Ativista
	2: {"experience": 150, "min_support": 200},  # Deputado
	3: {"experience": 300, "min_support": 350},  # Senador
	4: {"experience": 500, "min_support": 500},  # Ministro
	5: {"experience": 1000, "min_support": 600}  # Presidente
}

var _action_registry = {}

func _ready():
	if not agent_data:
		agent_data = PlayerAgentResource.new()
	_register_default_actions()

func _register_default_actions():
	_action_registry = {
		"Distribuir Panfletos": {
			"min_level": 0,
			"cost": 5,
			"effect": _effect_distribute_pamphlets,
			"success_modifier": 0.1
		},
		"Fazer Discurso": {
			"min_level": 1,
			"cost": 10,
			"effect": _effect_make_speech,
			"success_modifier": 0.2
		},
		"Organizar Reunião": {
			"min_level": 1,
			"cost": 5,
			"effect": _effect_organize_meeting,
			"success_modifier": 0.15
		}
	}

func advance_month():
	var passive_exp = int(agent_data.connections * 0.1)
	if passive_exp > 0:
		add_experience(passive_exp)

func execute_action(action_name: String) -> Dictionary:
	var result = {"success": false, "message": ""}
	
	if not _action_registry.has(action_name):
		result.message = "Ação desconhecida: %s" % action_name
		emit_signal("action_executed", action_name, false, result.message)
		return result
	
	var action = _action_registry[action_name]
	
	if agent_data.position_level < action.min_level:
		result.message = "Você precisa ser pelo menos %s" % agent_data.position_hierarchy[action.min_level]
		emit_signal("action_executed", action_name, false, result.message)
		return result
	
	if agent_data.wealth < action.cost:
		result.message = "Recursos insuficientes! (Custo: %d)" % action.cost
		emit_signal("action_executed", action_name, false, result.message)
		return result
	
	set_wealth(agent_data.wealth - action.cost)
	
	var base_chance = (agent_data.charisma + agent_data.intelligence + agent_data.connections) / 300.0
	var final_chance = clamp(base_chance + action.success_modifier, 0.1, 0.95)
	
	if randf() < final_chance:
		result.success = true
		result = action.effect.call(result)
		add_experience(5)
		check_for_promotion()
	else:
		result.message = "Sua tentativa não teve o efeito esperado."
	
	emit_signal("action_executed", action_name, result.success, result.message)
	return result

func _effect_distribute_pamphlets(result: Dictionary) -> Dictionary:
	var support_gain = randi_range(3, 7)
	modify_support("worker", support_gain)
	modify_support("student", int(support_gain * 0.5))
	result.message = "Panfletos distribuídos! Apoio dos trabalhadores +%d" % support_gain
	return result

func _effect_make_speech(result: Dictionary) -> Dictionary:
	var charisma_bonus = int(agent_data.charisma * 0.1)
	var support_gain = randi_range(5, 10) + charisma_bonus
	
	for group in ["worker", "student", "intellectual"]:
		modify_support(group, int(support_gain * 0.7))
	
	result.message = "Discurso inspirador! Múltiplos grupos impressionados."
	return result

func _effect_organize_meeting(result: Dictionary) -> Dictionary:
	var connections_bonus = int(agent_data.connections * 0.05)
	var support_gain = randi_range(2, 5) + connections_bonus
	
	modify_support("intellectual", support_gain)
	add_experience(3)
	
	result.message = "Reunião produtiva! Apoio intelectual +%d" % support_gain
	return result

func check_for_promotion():
	var current_level = agent_data.position_level
	if current_level >= agent_data.position_hierarchy.size() - 1:
		return
	
	var next_level = current_level + 1
	if not POSITION_REQUIREMENTS.has(next_level):
		return
	
	var reqs = POSITION_REQUIREMENTS[next_level]
	var total_support = agent_data.get_total_support()
	
	if agent_data.political_experience >= reqs.experience and total_support >= reqs.min_support:
		set_position_level(next_level)

func set_position_level(new_level: int):
	new_level = clamp(new_level, 0, agent_data.position_hierarchy.size() - 1)
	if new_level != agent_data.position_level:
		var old_pos = agent_data.get_position_name()
		agent_data.position_level = new_level
		emit_signal("position_advanced", old_pos, agent_data.get_position_name())

func set_wealth(new_value: int):
	if new_value != agent_data.wealth:
		var old_value = agent_data.wealth
		agent_data.wealth = max(0, new_value)
		emit_signal("wealth_changed", old_value, agent_data.wealth)

func add_experience(amount: int):
	if amount > 0:
		agent_data.political_experience += amount

func modify_support(group_name: String, change: int):
	if agent_data.personal_support.has(group_name):
		var old_value = agent_data.personal_support[group_name]
		var new_value = clamp(old_value + change, 0, 100)
		
		if new_value != old_value:
			agent_data.personal_support[group_name] = new_value
			emit_signal("support_changed", group_name, old_value, new_value)

func get_available_actions() -> Array:
	var actions = []
	for action_name in _action_registry:
		var action = _action_registry[action_name]
		if agent_data.position_level >= action.min_level:
			actions.append({
				"name": action_name,
				"cost": action.cost,
				"available": agent_data.wealth >= action.cost
			})
	return actions
