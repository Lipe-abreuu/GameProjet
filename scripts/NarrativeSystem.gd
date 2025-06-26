# res://scripts/NarrativeSystem.gd
# Gestor de narrativas competidoras.

extends Node

# Sinal emitido quando a crença numa narrativa ativa uma consequência.
signal narrative_consequence_triggered(group_name, narrative_content)

var active_narratives: Array = []

# Classe interna que define a estrutura de uma narrativa.
class Narrative:
	var content: String
	var source_group: String
	var intensity: int
	var credibility: float
	var target_groups: Array
	var spread_counter: int = 0
	var belief_levels: Dictionary = {}
	var consequences_triggered_for: Dictionary = {}

	func _init(data: Dictionary):
		content = data.get("content", "")
		source_group = data.get("source_group", "")
		intensity = data.get("intensity", 50)
		credibility = data.get("credibility", 0.5)
		target_groups = data.get("target_groups", [])
		for group in target_groups:
			belief_levels[group] = 0.0

# -----------------------------------------------------------------------------
# FUNÇÕES PRINCIPAIS
# -----------------------------------------------------------------------------

# Cria narrativas com base numa ação ou evento do sistema.
func create_narrative_from_action(action_name: String, agent_data: PartyResource):
	var new_narratives = []

	# --- LÓGICA CORRIGIDA AQUI ---
	# Cada bloco "if" agora tem a sua própria lógica de forma clara.
	if action_name == "Fazer Discurso":
		new_narratives.append(Narrative.new({
			"content": "O discurso de %s inspira o povo e une os trabalhadores." % agent_data.party_name,
			"source_group": "player_allies", "intensity": 60, "credibility": 0.7,
			"target_groups": ["workers", "students", "intellectuals"]
		}))
		new_narratives.append(Narrative.new({
			"content": "A retórica inflamada de %s é perigosa e semeia a discórdia." % agent_data.party_name,
			"source_group": "opposition_media", "intensity": 50, "credibility": 0.6,
			"target_groups": ["business", "military"]
		}))
	
	if action_name == "operacao_colombo":
		new_narratives.append(Narrative.new({
			"content": "Opositores do governo matam-se uns aos outros em confrontos internos no estrangeiro.",
			"source_group": "government_media", "intensity": 75, "credibility": 0.6,
			"target_groups": ["military", "business"]
		}))
	
	if action_name == "colapso_economico":
		new_narratives.append(Narrative.new({
			"content": "O modelo económico dos 'Chicago Boys' fracassou, levando o país à ruína.",
			"source_group": "opposition_allies", "intensity": 80, "credibility": 0.8,
			"target_groups": ["workers", "students", "intellectuals", "church"]
		}))

	# Adiciona as novas narrativas à lista de ativas no jogo.
	if not new_narratives.is_empty():
		active_narratives.append_array(new_narratives)
		print("NARRATIVAS CRIADAS para o evento '%s'." % action_name)

# Processa a propagação e a expiração das narrativas a cada mês.
func process_narrative_spread():
	if active_narratives.is_empty(): return

	for i in range(active_narratives.size() - 1, -1, -1):
		var narrative = active_narratives[i]
		narrative.spread_counter += 1

		for group in narrative.target_groups:
			var belief_change = _calculate_belief_impact(narrative, group)
			var current_belief = narrative.belief_levels.get(group, 0.0)
			narrative.belief_levels[group] = clamp(current_belief + belief_change, 0.0, 1.0)
		
		if narrative.spread_counter > 12:
			active_narratives.remove_at(i)

# Verifica se a crença numa narrativa ultrapassou o limiar para ativar uma consequência.
func check_narrative_consequences():
	for narrative in active_narratives:
		for group_name in narrative.belief_levels:
			if narrative.belief_levels[group_name] > 0.7:
				if not narrative.consequences_triggered_for.has(group_name):
					_trigger_consequence(narrative, group_name)
					narrative.consequences_triggered_for[group_name] = true

# -----------------------------------------------------------------------------
# FUNÇÕES AUXILIARES
# -----------------------------------------------------------------------------

# Função interna para calcular o impacto persuasivo de uma narrativa.
func _calculate_belief_impact(narrative: Narrative, group_name: String) -> float:
	var base_impact = narrative.intensity * narrative.credibility
	var compatibility_modifier = 1.0
	# TODO: Expandir esta lógica com as ideologias dos grupos.
	return (base_impact * compatibility_modifier) / 1000.0

# Função interna para emitir o sinal de consequência.
func _trigger_consequence(narrative: Narrative, group_name: String):
	print("CONSEQUÊNCIA ATIVADA: O grupo '%s' foi convencido pela narrativa!" % group_name)
	emit_signal("narrative_consequence_triggered", group_name, narrative.content)
