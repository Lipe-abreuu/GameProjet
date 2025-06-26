# res://scripts/NarrativeSystem.gd
# Gestor de narrativas competidoras - Versão corrigida

extends Node

# Sinal emitido quando a crença numa narrativa ativa uma consequência.
signal narrative_consequence_triggered(group_name, narrative_content)

var active_narratives: Array = []

# Ideologia básica atribuída a cada grupo de interesse.
# Quando um sistema dedicado de ideologias existir, estes valores
# poderão ser carregados de lá automaticamente.
const GROUP_IDEOLOGIES: Dictionary = {
        "workers": "left",
        "poor": "left",
        "students": "left",
        "intellectuals": "left",
        "peasants": "left",
        "business": "right",
        "military": "right",
        "church": "right",
        "middle_class": "center"
}

# Tabela simples de compatibilidade entre ideologias. Valores
# maiores que 1 aumentam o impacto de crença; menores reduzem.
const IDEOLOGY_COMPATIBILITY: Dictionary = {
        "left":   {"left": 1.2, "center": 1.0, "right": 0.8},
        "center": {"left": 1.0, "center": 1.1, "right": 1.0},
        "right":  {"left": 0.8, "center": 1.0, "right": 1.2}
}

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
# CORRIGIDO: Agora aceita tanto PartyResource quanto String
func create_narrative_from_action(action_name: String, agent_data):
	var new_narratives = []
	var agent_name: String
	
	# Determina o nome do agente baseado no tipo de dado recebido
	if agent_data is PartyResource:
		agent_name = agent_data.party_name
	elif agent_data is String:
		agent_name = agent_data
	else:
		agent_name = "Desconhecido"
		print("AVISO: Tipo de agent_data não reconhecido em create_narrative_from_action")

	# --- LÓGICA DE CRIAÇÃO DE NARRATIVAS ---
	match action_name:
		"Realizar Debate Ideológico":
			new_narratives.append(Narrative.new({
				"content": "O debate organizado por %s eleva o nível intelectual da discussão política." % agent_name,
				"source_group": "intellectuals", 
				"intensity": 60, 
				"credibility": 0.7,
				"target_groups": ["students", "middle_class", "church"]
			}))
			new_narratives.append(Narrative.new({
				"content": "Os intelectuais de %s apenas confundem o povo com teorias abstratas." % agent_name,
				"source_group": "opposition_media", 
				"intensity": 40, 
				"credibility": 0.5,
				"target_groups": ["workers", "poor"]
			}))
		
		"Distribuir Panfletos":
			new_narratives.append(Narrative.new({
				"content": "Os panfletos de %s esclarecem os trabalhadores sobre seus direitos." % agent_name,
				"source_group": "workers", 
				"intensity": 55, 
				"credibility": 0.6,
				"target_groups": ["poor", "students"]
			}))
			new_narratives.append(Narrative.new({
				"content": "A propaganda de %s espalha ideias perigosas que ameaçam a ordem." % agent_name,
				"source_group": "business", 
				"intensity": 50, 
				"credibility": 0.6,
				"target_groups": ["military", "middle_class"]
			}))
		
		"Organizar Protesto Local":
			new_narratives.append(Narrative.new({
				"content": "A manifestação organizada por %s demonstra o poder da organização popular." % agent_name,
				"source_group": "workers", 
				"intensity": 70, 
				"credibility": 0.8,
				"target_groups": ["students", "poor", "intellectuals"]
			}))
			new_narratives.append(Narrative.new({
				"content": "Os protestos de %s perturbam a paz e assustam famílias trabalhadoras." % agent_name,
				"source_group": "middle_class", 
				"intensity": 60, 
				"credibility": 0.7,
				"target_groups": ["business", "church", "military"]
			}))
		
		"Publicar Manifesto":
			new_narratives.append(Narrative.new({
				"content": "O manifesto de %s articula uma visão clara para o futuro do país." % agent_name,
				"source_group": "intellectuals", 
				"intensity": 65, 
				"credibility": 0.75,
				"target_groups": ["students", "workers", "middle_class"]
			}))
			new_narratives.append(Narrative.new({
				"content": "As ideias radicais de %s ameaçam as tradições e valores da nossa sociedade." % agent_name,
				"source_group": "church", 
				"intensity": 55, 
				"credibility": 0.65,
				"target_groups": ["business", "military"]
			}))
		
		# --- EVENTOS HISTÓRICOS ---
		"operacao_colombo":
			new_narratives.append(Narrative.new({
				"content": "Opositores do governo matam-se uns aos outros em confrontos internos no estrangeiro.",
				"source_group": "government_media", 
				"intensity": 75, 
				"credibility": 0.6,
				"target_groups": ["military", "business", "middle_class"]
			}))
		
		"colapso_economico":
			new_narratives.append(Narrative.new({
				"content": "O modelo económico dos 'Chicago Boys' fracassou, levando o país à ruína.",
				"source_group": "opposition_allies", 
				"intensity": 80, 
				"credibility": 0.8,
				"target_groups": ["workers", "students", "intellectuals", "church"]
			}))
		
		"golpe_militar":
			new_narratives.append(Narrative.new({
				"content": "O governo militar salvou o país do caos e da ameaça comunista.",
				"source_group": "government_media", 
				"intensity": 85, 
				"credibility": 0.7,
				"target_groups": ["military", "business", "middle_class"]
			}))
			new_narratives.append(Narrative.new({
				"content": "O golpe militar destruiu a democracia e trouxe terror ao povo.",
				"source_group": "opposition_underground", 
				"intensity": 90, 
				"credibility": 0.9,
				"target_groups": ["workers", "students", "intellectuals"]
			}))
		
		"nacionalizar_cobre":
			new_narratives.append(Narrative.new({
				"content": "A nacionalização do cobre finalmente coloca as riquezas nacionais nas mãos do povo.",
				"source_group": "workers", 
				"intensity": 70, 
				"credibility": 0.8,
				"target_groups": ["students", "poor", "intellectuals"]
			}))
			new_narratives.append(Narrative.new({
				"content": "A expropriação do cobre é um passo em direção ao comunismo que destruirá a economia.",
				"source_group": "business", 
				"intensity": 80, 
				"credibility": 0.7,
				"target_groups": ["military", "church", "middle_class"]
			}))

	# Adiciona as novas narrativas à lista de ativas no jogo.
	if not new_narratives.is_empty():
		active_narratives.append_array(new_narratives)
		print("NARRATIVAS CRIADAS para o evento '%s' (agente: %s)." % [action_name, agent_name])
	else:
		print("AVISO: Nenhuma narrativa encontrada para a ação '%s'." % action_name)

# Processa a propagação e a expiração das narrativas a cada mês.
func process_narrative_spread():
	if active_narratives.is_empty(): 
		return

	for i in range(active_narratives.size() - 1, -1, -1):
		var narrative = active_narratives[i]
		narrative.spread_counter += 1

		# Calcula o impacto da narrativa em cada grupo alvo
		for group in narrative.target_groups:
			var belief_change = _calculate_belief_impact(narrative, group)
			var current_belief = narrative.belief_levels.get(group, 0.0)
			narrative.belief_levels[group] = clamp(current_belief + belief_change, 0.0, 1.0)
		
		# Remove narrativas que já se espalharam por muito tempo (12 meses)
		if narrative.spread_counter > 12:
			print("NARRATIVA EXPIRADA: '%s'" % narrative.content)
			active_narratives.remove_at(i)

# Verifica se a crença numa narrativa ultrapassou o limiar para ativar uma consequência.
func check_narrative_consequences():
	for narrative in active_narratives:
		for group_name in narrative.belief_levels:
			if narrative.belief_levels[group_name] > 0.7:
				if not narrative.consequences_triggered_for.has(group_name):
					_trigger_consequence(narrative, group_name)
					narrative.consequences_triggered_for[group_name] = true

# Obtém narrativas ativas para exibição na UI
func get_active_narratives() -> Array:
	return active_narratives.duplicate()

# Obtém narrativas que afetam um grupo específico
func get_narratives_affecting_group(group_name: String) -> Array:
        var relevant_narratives = []
        for narrative in active_narratives:
                if group_name in narrative.target_groups:
                        relevant_narratives.append(narrative)
        return relevant_narratives

# -----------------------------------------------------------------------------
# FUNÇÕES AUXILIARES
# -----------------------------------------------------------------------------

# Retorna a ideologia associada a um grupo. Quando o sistema de
# ideologias de grupos for implementado em outro lugar, esta função
# irá buscá-la de Globals; até lá usamos os valores locais.
func _get_group_ideology(group_name: String) -> String:
        if Globals and Globals.has("group_ideologies"):
                return Globals.group_ideologies.get(group_name, "")
        return GROUP_IDEOLOGIES.get(group_name, "")

# Função interna para calcular o impacto persuasivo de uma narrativa.
func _calculate_belief_impact(narrative: Narrative, group_name: String) -> float:
        var base_impact = narrative.intensity * narrative.credibility
        var compatibility_modifier = 1.0

        # Primeiro tenta usar compatibilidade baseada em ideologias declaradas.
        var source_ideology = _get_group_ideology(narrative.source_group)
        var target_ideology = _get_group_ideology(group_name)

        if source_ideology != "" and target_ideology != "":
                var row = IDEOLOGY_COMPATIBILITY.get(source_ideology, {})
                compatibility_modifier = row.get(target_ideology, 1.0)
        else:
                # Fallback para regras simplificadas se ideologias não estiverem disponíveis
                match group_name:
                        "workers", "poor":
                                if narrative.source_group in ["workers", "opposition_allies"]:
                                        compatibility_modifier = 1.2
                                elif narrative.source_group in ["business", "military"]:
                                        compatibility_modifier = 0.8
                        "business", "military":
                                if narrative.source_group in ["government_media", "business"]:
                                        compatibility_modifier = 1.2
                                elif narrative.source_group in ["workers", "opposition_allies"]:
                                        compatibility_modifier = 0.8
                        "intellectuals", "students":
                                if narrative.source_group in ["intellectuals", "opposition_underground"]:
                                        compatibility_modifier = 1.1
                                elif narrative.source_group in ["government_media"]:
                                        compatibility_modifier = 0.9

        return (base_impact * compatibility_modifier) / 1000.0

# Função interna para emitir o sinal de consequência.
func _trigger_consequence(narrative: Narrative, group_name: String):
	print("CONSEQUÊNCIA ATIVADA: O grupo '%s' foi convencido pela narrativa: '%s'" % [group_name, narrative.content])
	emit_signal("narrative_consequence_triggered", group_name, narrative.content)

# Limpa todas as narrativas ativas (útil para resets ou testes)
func clear_all_narratives():
	active_narratives.clear()
	print("TODAS AS NARRATIVAS FORAM REMOVIDAS.")
