# res://scripts/NarrativeSystem.gd
extends Node

signal narrative_consequence_triggered(group_name, narrative_content)

var active_narratives: Array = []

class Narrative:
	var content: String
	var source_group: String
	var intensity: int
	var credibility: float
	var target_groups: Array
	var spread_counter: int = 0
	var belief_levels: Dictionary = {}
	# CORREÇÃO: Dicionário para rastrear para quais grupos a consequência já foi ativada.
	var consequences_triggered_for: Dictionary = {}

	func _init(data: Dictionary):
		content = data.get("content", "")
		source_group = data.get("source_group", "")
		intensity = data.get("intensity", 50)
		credibility = data.get("credibility", 0.5)
		target_groups = data.get("target_groups", [])
		for group in target_groups:
			belief_levels[group] = 0.0

func create_narrative_from_action(action_name: String, agent_data: PartyResource):
	var new_narratives = []
	if action_name == "Fazer Discurso":
		new_narratives.append(Narrative.new({
			"content": "O discurso de %s inspira o povo e une os trabalhadores." % agent_data.agent_name,
			"source_group": "player_allies", "intensity": 60, "credibility": 0.7,
			"target_groups": ["workers", "students", "intellectuals"]
		}))
		new_narratives.append(Narrative.new({
			"content": "A retórica inflamada de %s é perigosa e semeia a discórdia." % agent_data.agent_name,
			"source_group": "opposition_media", "intensity": 50, "credibility": 0.6,
			"target_groups": ["business", "military"]
		}))

	if not new_narratives.is_empty():
		active_narratives.append_array(new_narratives)
		print("NARRATIVAS CRIADAS para a ação '%s'." % action_name)

func calculate_belief_impact(narrative: Narrative, group_name: String) -> float:
	var base_impact = narrative.intensity * narrative.credibility
	var compatibility_modifier = 1.0
	if group_name in ["workers", "students"] and "allies" in narrative.source_group:
		compatibility_modifier = 1.5
	elif group_name in ["business", "military"] and "opposition" in narrative.source_group:
		compatibility_modifier = 1.3
	elif group_name in ["business", "military"] and "allies" in narrative.source_group:
		compatibility_modifier = 0.5
	return (base_impact * compatibility_modifier) / 1000.0

func process_narrative_spread():
	if active_narratives.is_empty(): return
	for i in range(active_narratives.size() - 1, -1, -1):
		var narrative = active_narratives[i]
		narrative.spread_counter += 1
		for group in narrative.target_groups:
			var belief_change = calculate_belief_impact(narrative, group)
			var current_belief = narrative.belief_levels.get(group, 0.0)
			narrative.belief_levels[group] = clamp(current_belief + belief_change, 0.0, 1.0)
			print("PROPAGAÇÃO: Grupo '%s' agora tem %.1f%% de crença na narrativa: '%s'" % [group, narrative.belief_levels[group] * 100, narrative.content])
		if narrative.spread_counter > 12:
			print("NARRATIVA EXPIRADA: ", narrative.content)
			active_narratives.remove_at(i)

# =============================================================
# FUNÇÕES DE CONSEQUÊNCIA CORRIGIDAS
# =============================================================
func check_narrative_consequences():
	for narrative in active_narratives:
		for group_name in narrative.belief_levels:
			var belief_level = narrative.belief_levels[group_name]
			
			# Se a crença do grupo for maior que 70%...
			if belief_level > 0.7:
				# ...E se a consequência ainda não foi ativada para este grupo
				if not narrative.consequences_triggered_for.has(group_name):
					trigger_consequence(narrative, group_name)
					# Marca como ativada para não acontecer de novo
					narrative.consequences_triggered_for[group_name] = true

func trigger_consequence(narrative: Narrative, group_name: String):
	print("CONSEQUÊNCIA ATIVADA: O grupo '%s' foi convencido pela narrativa!" % group_name)
	emit_signal("narrative_consequence_triggered", group_name, narrative.content)
