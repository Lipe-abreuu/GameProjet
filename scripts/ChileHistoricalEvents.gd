# res://scripts/ChileHistoricalEvents.gd
# Eventos históricos do Chile - Versão completa corrigida

extends Node

# Sinais para comunicação com outros sistemas
signal historical_event_notification(title, message, type)

# CRONOGRAMA COMPLETO DE EVENTOS HISTÓRICOS
var scheduled_events: Dictionary = {
	1973: {9: ["golpe_1973"]},
	1974: {6: ["criacao_dina"], 10: ["operacao_colombo"]},
	1975: {6: ["plano_shock"], 8: ["operacao_condor"]},
	1976: {9: ["assassinato_letelier"]},
	1978: {4: ["anistia_geral"]},
	1980: {8: ["constituicao_1980"]},
	1982: {1: ["crise_economica_1982"]},
	1983: {5: ["protestas_1983"]},
	1984: {3: ["estado_sitio_1984"]},
	1985: {8: ["acordo_nacional_1985"]},
	1986: {9: ["atentado_pinochet_1986"]},
	1988: {10: ["plebiscito_1988"]}
}

# Referências para outros sistemas (com verificação de existência)
var choice_dialog_scene = null

func _ready():
	# Tenta carregar a cena do diálogo, mas não quebra se não existir
	if ResourceLoader.exists("res://scenes/ui/ChoiceDialog.tscn"):
		choice_dialog_scene = preload("res://scenes/ChoiceDialog.tscn")
	elif ResourceLoader.exists("res://scenes/ChoiceDialog.tscn"):
		choice_dialog_scene = preload("res://scenes/ChoiceDialog.tscn")
	else:
		print("AVISO: ChoiceDialog.tscn não encontrado. Eventos com escolhas usarão fallback.")

# =====================================
# FUNÇÕES PRINCIPAIS DE CONTROLE
# =====================================

# Função chamada pelo main.gd para verificar eventos agendados
func check_for_events(year: int, month: int):
	"""Verifica se há eventos agendados para o ano/mês atual"""
	if scheduled_events.has(year) and scheduled_events[year].has(month):
		for event_id in scheduled_events[year][month]:
			if _are_conditions_met(event_id):
				trigger_historical_event(event_id)

func trigger_historical_event(event_id: String):
	"""Dispara a função correspondente ao ID do evento"""
	print("EVENTO HISTÓRICO DISPARADO: ", event_id)
	var function_name = "execute_" + event_id
	if has_method(function_name):
		call(function_name)
	else:
		printerr("AVISO: A função '%s' ainda não foi implementada." % function_name)

func _are_conditions_met(event_id: String) -> bool:
	"""Verifica se as condições para o evento são atendidas"""
	# Eventos condicionais específicos
	match event_id:
		"atentado_pinochet_1986":
			return _check_atentado_conditions()
		"acordo_nacional_1985":
			return _check_acordo_conditions()
		_:
			# Por padrão, todos os outros eventos sempre acontecem
			return true

# =====================================
# EXECUÇÃO DE EVENTOS HISTÓRICOS
# =====================================

# --- PERÍODO 1: GOLPE E CONSOLIDAÇÃO (1973-1976) ---

func execute_golpe_1973():
	"""Execução do evento do Golpe de 1973 - Versão com debug melhorado"""
	get_tree().paused = true
	
	print("=== EXECUTANDO GOLPE DE 1973 ===")
	print("PartyController no Globals: ", Globals.get("party_controller"))
	
	emit_signal("historical_event_notification", 
		"Golpe de Estado", 
		"11 de setembro de 1973: As Forças Armadas derrubam o governo. A democracia chilena chega ao fim.", 
		_get_notification_type("ERROR"))
	
	# Cria trauma coletivo relacionado ao golpe
	if _system_exists("TraumaSystem"):
		TraumaSystem.create_trauma("Golpe_1973_Real", {
			"name": "O Golpe de 11 de Setembro", 
			"type": "political", 
			"intensity": 2.0, 
			"triggers": ["militar", "golpe", "repressão"], 
			"year": 1973
		})
	
	# Cria narrativas sobre o golpe
	if _system_exists("NarrativeSystem"):
		NarrativeSystem.create_narrative_from_action("golpe_militar", "system")
	
	# Debug: Lista todos os nós para ajudar a encontrar o PartyController
	print("=== DEBUG: ESTRUTURA DE NÓS ===")
	_print_node_tree(get_tree().root, 0, 3)  # Máximo 3 níveis
	
	# Mostra escolhas para o jogador
	var choices = [
		{"text": "Condenar e resistir.", "consequence": "resist"}, 
		{"text": "Manter silêncio.", "consequence": "wait_and_see"}, 
		{"text": "Buscar exílio.", "consequence": "exile"}
	]
	
	_show_choice_dialog("O Golpe Aconteceu!", "Como o seu partido reage?", choices, "_on_golpe_1973_choice_made")

func _on_golpe_1973_choice_made(consequence: String):
	"""Processa a escolha do jogador durante o golpe"""
	get_tree().paused = false
	
	print("=== PROCESSANDO ESCOLHA DO GOLPE: %s ===" % consequence)
	
	# MÉTODO 1: Usar referência do Globals (Recomendado)
	if "party_controller" in Globals and Globals.party_controller:
		print("GOLPE: Usando PartyController do Globals")
		Globals.party_controller.handle_coup_response(consequence)
		return
	
	# MÉTODO 2: Busca direta por classe
	var party_controller = _find_party_controller_improved()
	if party_controller:
		print("GOLPE: PartyController encontrado via busca direta")
		party_controller.handle_coup_response(consequence)
		return
	
	# MÉTODO 3: Busca na árvore de nós
	party_controller = _search_tree_for_party_controller(get_tree().root)
	if party_controller:
		print("GOLPE: PartyController encontrado via busca na árvore")
		party_controller.handle_coup_response(consequence)
		return
	
	# FALLBACK: Se ainda não encontrou, aplica efeitos manuais
	print("ERRO: PartyController não encontrado. Aplicando efeitos manuais.")
	_apply_manual_coup_effects(consequence)

func execute_criacao_dina():
	"""Criação da DINA - polícia secreta do regime"""
	emit_signal("historical_event_notification", 
		"Criação da DINA", 
		"O regime cria a sua temida polícia secreta. A repressão irá intensificar-se.", 
		_get_notification_type("ERROR"))
	
	# Aumenta a repressão no país
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "repression", 30)
	
	# Cria trauma relacionado à repressão
	if _system_exists("TraumaSystem"):
		TraumaSystem.create_trauma("DINA_Terror", {
			"name": "Terror da DINA", 
			"type": "security", 
			"intensity": 1.8, 
			"triggers": ["dina", "polícia", "repressão", "tortura"], 
			"year": 1974
		})

func execute_operacao_colombo():
	"""Operação Colombo - simulação de confrontos para encobrir desaparecimentos"""
	emit_signal("historical_event_notification", 
		"Operação Colombo", 
		"O regime simula confrontos para encobrir o desaparecimento de opositores.", 
		_get_notification_type("INFO"))
	
	# Cria narrativa oficial sobre a operação
	if _system_exists("NarrativeSystem"):
		NarrativeSystem.create_narrative_from_action("operacao_colombo", "system")

func execute_operacao_condor():
	"""Operação Condor - cooperação entre ditaduras do Cone Sul"""
	emit_signal("historical_event_notification", 
		"Operação Condor", 
		"As ditaduras do Cone Sul unem-se para perseguir opositores além das suas fronteiras. O exílio já não é um lugar seguro.", 
		_get_notification_type("ERROR"))
	
	# Ativa a mecânica global da Operação Condor
	if _system_exists("Globals") and Globals.has_method("activate_condor"):
		Globals.activate_condor()
	else:
		print("MECÂNICA DE JOGO: Operação Condor ativada (funcionalidade básica)")
	
	# Cria trauma relacionado à perseguição internacional
	if _system_exists("TraumaSystem"):
		TraumaSystem.create_trauma("Condor_Terror", {
			"name": "Terror Internacional", 
			"type": "international", 
			"intensity": 1.5, 
			"triggers": ["condor", "exílio", "perseguição", "fronteira"], 
			"year": 1975
		})

func execute_assassinato_letelier():
	"""Assassinato de Orlando Letelier em Washington"""
	emit_signal("historical_event_notification", 
		"Assassinato em Washington", 
		"O ex-chanceler Orlando Letelier é assassinado pela DINA nos EUA, causando uma crise diplomática.", 
		_get_notification_type("ERROR"))
	
	# Aumenta pressão internacional
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "international_pressure", 25)
	
	# Cria trauma diplomático
	if _system_exists("TraumaSystem"):
		TraumaSystem.create_trauma("Crise_Diplomatica_EUA", {
			"name": "Crise Diplomática com os EUA", 
			"type": "diplomatic", 
			"intensity": 1.5, 
			"triggers": ["eua", "cia", "washington", "diplomacia"], 
			"year": 1976
		})

# --- PERÍODO 2: INSTITUCIONALIZAÇÃO (1977-1982) ---

func execute_plano_shock():
	"""Implementação do plano econômico dos Chicago Boys"""
	emit_signal("historical_event_notification", 
		"Plano de Choque Económico", 
		"Os 'Chicago Boys' assumem a economia, implementando reformas neoliberais drásticas.", 
		_get_notification_type("INFO"))
	
	# Ajusta indicadores econômicos
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "economic_liberalization", 40)
		Globals.adjust_country_value("Chile", "unemployment", 15)
	
	# Cria narrativa econômica
	if _system_exists("NarrativeSystem"):
		NarrativeSystem.create_narrative_from_action("plano_shock", "system")

func execute_anistia_geral():
	"""Lei de Anistia de 1978"""
	emit_signal("historical_event_notification", 
		"Lei de Anistia", 
		"O regime decreta uma anistia geral para crimes políticos cometidos desde 1973, garantindo impunidade para agentes do Estado.", 
		_get_notification_type("ERROR"))
	
	# Reduz pressão internacional mas aumenta impunidade
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "international_pressure", -10)
		Globals.adjust_country_value("Chile", "impunity", 30)
	
	# Cria trauma relacionado à impunidade
	if _system_exists("TraumaSystem"):
		TraumaSystem.create_trauma("Impunidade_Legal", {
			"name": "Impunidade Legalizada", 
			"type": "legal", 
			"intensity": 1.3, 
			"triggers": ["anistia", "impunidade", "justiça", "crimes"], 
			"year": 1978
		})

func execute_constituicao_1980():
	"""Constituição de 1980"""
	emit_signal("historical_event_notification", 
		"Nova Constituição", 
		"O regime promulga uma nova constituição que institucionaliza o modelo autoritário e protege os militares.", 
		_get_notification_type("INFO"))
	
	# Institucionaliza o regime
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "institutional_protection", 35)
	
	# Cria trauma constitucional
	if _system_exists("TraumaSystem"):
		TraumaSystem.create_trauma("Constituicao_Autoritaria", {
			"name": "Constituição Autoritária", 
			"type": "institutional", 
			"intensity": 1.2, 
			"triggers": ["constituição", "institucional", "proteção"], 
			"year": 1980
		})

# --- PERÍODO 3: CRISE ECONÔMICA (1982-1983) ---

func execute_crise_economica_1982():
	"""Crise econômica de 1982"""
	emit_signal("historical_event_notification", 
		"Crise Econômica", 
		"O 'milagre econômico' chileno desmorona. Bancos quebram, desemprego dispara e a pobreza aumenta drasticamente.", 
		_get_notification_type("ERROR"))
	
	# Ajusta indicadores econômicos negativamente
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "unemployment", 25)
		Globals.adjust_country_value("Chile", "poverty", 30)
		Globals.adjust_country_value("Chile", "economic_growth", -40)
	
	# Cria narrativa sobre o colapso econômico
	if _system_exists("NarrativeSystem"):
		NarrativeSystem.create_narrative_from_action("colapso_economico", "system")
	
	# Cria trauma econômico
	if _system_exists("TraumaSystem"):
		TraumaSystem.create_trauma("Crise_Economica_82", {
			"name": "Colapso Econômico", 
			"type": "economic", 
			"intensity": 2.2, 
			"triggers": ["economia", "desemprego", "pobreza", "crise"], 
			"year": 1982
		})

func execute_protestas_1983():
	"""Início das protestas nacionais de 1983"""
	emit_signal("historical_event_notification", 
		"Jornadas de Protesto", 
		"A crise econômica gera as primeiras grandes manifestações contra o regime. O país volta às ruas após 10 anos de silêncio.", 
		_get_notification_type("INFO"))
	
	# Aumenta instabilidade política
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "political_instability", 20)
		Globals.adjust_country_value("Chile", "civil_resistance", 25)
	
	# Cria trauma de resistência
	if _system_exists("TraumaSystem"):
		TraumaSystem.create_trauma("Protestas_83", {
			"name": "Despertar da Resistência", 
			"type": "social", 
			"intensity": 1.8, 
			"triggers": ["protesto", "manifestação", "resistência", "ruas"], 
			"year": 1983
		})
	
	# Oferece escolhas ao jogador se o partido ainda existir
	var party_controller = _find_party_controller_safe()
	if party_controller and party_controller.party_data.influence > 1.0:
		var choices = [
			{"text": "Apoiar os protestos ativamente.", "consequence": "support_protests"},
			{"text": "Observar cautelosamente.", "consequence": "observe_protests"}, 
			{"text": "Manter-se afastado.", "consequence": "avoid_protests"}
		]
		_show_choice_dialog("Protestos Nacionais", "Como seu partido reage às manifestações?", choices, "_on_protestos_choice_made")

func _on_protestos_choice_made(consequence: String):
	"""Processa a escolha do jogador durante os protestos"""
	var party_controller = _find_party_controller_safe()
	if party_controller:
		match consequence:
			"support_protests":
				party_controller.party_data.influence += 1.0
				party_controller._change_support("workers", 5)
				party_controller._change_support("students", 3)
				party_controller._change_support("military", -3)
			"observe_protests":
				party_controller.party_data.influence += 0.2
			"avoid_protests":
				party_controller._change_support("workers", -2)
				party_controller._change_support("students", -1)

# --- PERÍODO 4: TRANSIÇÃO (1984-1990) ---

func execute_estado_sitio_1984():
	"""Estado de sítio de 1984"""
	emit_signal("historical_event_notification", 
		"Estado de Sítio", 
		"O regime declara estado de sítio para reprimir as crescentes manifestações. A repressão intensifica-se novamente.", 
		_get_notification_type("ERROR"))
	
	# Aumenta repressão mas também resistência
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "repression", 15)
		Globals.adjust_country_value("Chile", "civil_resistance", 10)

func execute_acordo_nacional_1985():
	"""Acordo Nacional de 1985"""
	emit_signal("historical_event_notification", 
		"Acordo Nacional", 
		"Partidos da oposição assinam um acordo para uma transição pacífica à democracia, excluindo a esquerda radical.", 
		_get_notification_type("INFO"))
	
	# Fortalece oposição moderada
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "democratic_opposition", 20)
		Globals.adjust_country_value("Chile", "political_polarization", -5)
	
	# Oferece escolha ao partido se for de esquerda
	var party_controller = _find_party_controller_safe()
	if party_controller:
		var choices = [
			{"text": "Tentar participar do acordo.", "consequence": "join_agreement"},
			{"text": "Formar oposição alternativa.", "consequence": "alternative_opposition"},
			{"text": "Manter posição radical.", "consequence": "stay_radical"}
		]
		_show_choice_dialog("Acordo Nacional", "A oposição moderada exclui a esquerda. Como reagir?", choices, "_on_acordo_choice_made")

func _on_acordo_choice_made(consequence: String):
	"""Processa a escolha do jogador sobre o Acordo Nacional"""
	var party_controller = _find_party_controller_safe()
	if party_controller:
		match consequence:
			"join_agreement":
				party_controller._change_support("intellectuals", 3)
				party_controller._change_support("workers", -2)
				party_controller.party_data.influence += 0.5
			"alternative_opposition":
				party_controller._change_support("students", 3)
				party_controller._change_support("workers", 2)
			"stay_radical":
				party_controller._change_support("workers", 1)
				party_controller._change_support("intellectuals", -2)

func execute_atentado_pinochet_1986():
	"""Atentado contra Pinochet"""
	emit_signal("historical_event_notification", 
		"Atentado Frustrado", 
		"A Frente Patriótica Manuel Rodríguez tenta assassinar Pinochet. O atentado falha e a repressão recrudesce.", 
		_get_notification_type("ERROR"))
	
	# Aumenta repressão e polarização
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "repression", 20)
		Globals.adjust_country_value("Chile", "political_polarization", 15)
		Globals.adjust_country_value("Chile", "radical_left_support", -25)

func execute_plebiscito_1988():
	"""Plebiscito de 1988"""
	emit_signal("historical_event_notification", 
		"Plebiscito", 
		"A oposição democrática vence o plebiscito com o 'NO'. Pinochet aceita o resultado e inicia-se a transição.", 
		_get_notification_type("SUCCESS"))
	
	# Marca vitória democrática
	if _system_exists("Globals"):
		Globals.adjust_country_value("Chile", "democratic_legitimacy", 40)
		Globals.adjust_country_value("Chile", "regime_support", -30)
	
	# Cria trauma de vitória democrática
	if _system_exists("TraumaSystem"):
		TraumaSystem.create_trauma("Victoria_NO", {
			"name": "Vitória do NO", 
			"type": "democratic", 
			"intensity": 1.5, 
			"triggers": ["plebiscito", "democracia", "vitória", "transição"], 
			"year": 1988
		})
	
	# Oferece escolha final ao partido
	var party_controller = _find_party_controller_safe()
	if party_controller and party_controller.party_data.influence > 0.5:
		var choices = [
			{"text": "Participar da transição democrática.", "consequence": "join_transition"},
			{"text": "Manter oposição crítica.", "consequence": "critical_opposition"},
			{"text": "Preparar para eleições.", "consequence": "prepare_elections"}
		]
		_show_choice_dialog("Vitória do NO", "A democracia retorna. Qual o papel do seu partido?", choices, "_on_plebiscito_choice_made")

func _on_plebiscito_choice_made(consequence: String):
	"""Processa a escolha do jogador após o plebiscito"""
	var party_controller = _find_party_controller_safe()
	if party_controller:
		match consequence:
			"join_transition":
				party_controller.party_data.influence += 2.0
				party_controller._change_support("intellectuals", 5)
				party_controller._change_support("middle_class", 3)
			"critical_opposition":
				party_controller._change_support("workers", 3)
				party_controller._change_support("students", 2)
			"prepare_elections":
				party_controller.party_data.influence += 1.5
				party_controller.party_data.militants += 20

# =====================================
# FUNÇÕES DE CONDIÇÕES
# =====================================

func _check_atentado_conditions() -> bool:
	"""Verifica se as condições para o atentado estão presentes"""
	# Atentado só acontece se houver alta repressão e resistência ativa
	var repression = 0
	var resistance = 0
	
	if _system_exists("Globals"):
		repression = Globals.get_country_value("Chile", "repression", 0)
		resistance = Globals.get_country_value("Chile", "civil_resistance", 0)
	
	return repression > 70 and resistance > 20

func _check_acordo_conditions() -> bool:
	"""Verifica se as condições para o acordo nacional estão presentes"""
	# Acordo só acontece se há oposição organizada mas não muito radicalizada
	var opposition = 0
	var polarization = 0
	
	if _system_exists("Globals"):
		opposition = Globals.get_country_value("Chile", "democratic_opposition", 0)
		polarization = Globals.get_country_value("Chile", "political_polarization", 0)
	
	return opposition > 15 and polarization < 30

# =====================================
# FUNÇÕES DE BUSCA DO PARTYCONTROLLER
# =====================================

func _find_party_controller_improved() -> Node:
	"""Busca melhorada do PartyController"""
	var search_paths = [
		# Caminhos mais prováveis primeiro
		"/root/Main/PartyController",
		"/root/PartyController", 
		"Main/PartyController",
		"PartyController",
		# Busca por qualquer nó filho do Main
		"/root/Main"
	]
	
	for path in search_paths:
		var node = get_node_or_null(path)
		if node:
			# Se encontrou um nó, verifica se é PartyController
			if node.get_script() and "PartyController" in str(node.get_script()):
				return node
			
			# Se é o Main, procura PartyController entre seus filhos
			if node.name == "Main":
				for child in node.get_children():
					if child.get_script() and "PartyController" in str(child.get_script()):
						return child
	
	return null

func _search_tree_for_party_controller(node: Node) -> Node:
	"""Busca recursiva por qualquer nó PartyController na árvore"""
	# Verifica se o nó atual é PartyController
	if node.get_script() and "PartyController" in str(node.get_script()):
		return node
	
	# Busca nos filhos
	for child in node.get_children():
		var result = _search_tree_for_party_controller(child)
		if result:
			return result
	
	return null

func _find_party_controller_safe() -> Node:
	"""Versão segura que não gera erros se não encontrar"""
	# Primeiro tenta usar o Globals
	if Globals.has("party_controller") and Globals.party_controller:
		return Globals.party_controller
	
	# Senão, tenta busca melhorada
	var party_controller = _find_party_controller_improved()
	if party_controller:
		return party_controller
	
	# Por último, busca na árvore
	return _search_tree_for_party_controller(get_tree().root)

# =====================================
# FUNÇÕES DE FALLBACK MANUAL
# =====================================

func _apply_manual_coup_effects(consequence: String):
	"""Aplica efeitos do golpe manualmente se PartyController não for encontrado"""
	print("APLICANDO EFEITOS MANUAIS DO GOLPE: %s" % consequence)
	
	# Efeitos básicos dependendo da escolha
	match consequence:
		"resist":
			print("- Partido escolheu resistir: -10 influência, apoio militar reduzido")
			if _system_exists("Globals"):
				Globals.adjust_country_value("Chile", "resistance_strength", 15)
		
		"wait_and_see":
			print("- Partido manteve silêncio: -5 influência, apoio geral reduzido")
			if _system_exists("Globals"):
				Globals.adjust_country_value("Chile", "political_uncertainty", 10)
		
		"exile":
			print("- Partido buscou exílio: influência severamente reduzida")
			if _system_exists("Globals"):
				Globals.adjust_country_value("Chile", "exile_population", 20)
	
	# Notifica o jogador sobre o que aconteceu
	var message = ""
	match consequence:
		"resist":
			message = "Seu partido decidiu resistir ao golpe. A repressão será severa, mas a resistência se organiza."
		"wait_and_see":
			message = "Seu partido manteve silêncio durante o golpe. A incerteza política aumenta."
		"exile":
			message = "Seu partido buscou exílio. A influência local foi perdida, mas a sobrevivência está garantida."
	
	# Emite notificação
	emit_signal("historical_event_notification", 
		"Resposta ao Golpe", 
		message, 
		_get_notification_type("INFO"))

# =====================================
# FUNÇÕES AUXILIARES SEGURAS
# =====================================

func _system_exists(system_name: String) -> bool:
	"""Verifica se um sistema existe antes de usá-lo"""
	match system_name:
		"TraumaSystem":
			return get_node_or_null("/root/TraumaSystem") != null
		"NarrativeSystem":
			return get_node_or_null("/root/NarrativeSystem") != null
		"Globals":
			return get_node_or_null("/root/Globals") != null
		_:
			return false

func _get_notification_type(type_name: String) -> int:
	"""Retorna o tipo de notificação de forma segura"""
	if get_node_or_null("/root/NotificationSystem"):
		match type_name:
			"ERROR":
				return NotificationSystem.NotificationType.ERROR
			"INFO":
				return NotificationSystem.NotificationType.INFO
			"SUCCESS":
				return NotificationSystem.NotificationType.SUCCESS
			_:
				return 0
	else:
		# Fallback se NotificationSystem não existir
		match type_name:
			"ERROR":
				return 2
			"INFO":
				return 1
			"SUCCESS":
				return 0
			_:
				return 1

func _show_choice_dialog(title: String, message: String, choices: Array, callback_method: String):
	"""Mostra diálogo de escolha de forma segura"""
	if choice_dialog_scene:
		var dialog = choice_dialog_scene.instantiate()
		if dialog.has_signal("choice_made"):
			dialog.connect("choice_made", Callable(self, callback_method))
		get_tree().root.add_child(dialog)
		if dialog.has_method("setup_choices"):
			dialog.setup_choices(title, message, choices)
		else:
			print("ERRO: ChoiceDialog não tem método setup_choices")
	else:
		# Fallback: executa a primeira escolha automaticamente
		print("FALLBACK: Executando primeira escolha para '%s'" % title)
		if choices.size() > 0:
			call(callback_method, choices[0].consequence)

func _print_node_tree(node: Node, level: int, max_level: int):
	"""Imprime a estrutura da árvore de nós para debug"""
	if level > max_level:
		return
	
	var indent = "  ".repeat(level)
	var script_info = ""
	if node.get_script():
		script_info = " (%s)" % str(node.get_script()).get_file()
	
	print("%s%s%s" % [indent, node.name, script_info])
	
	for child in node.get_children():
		_print_node_tree(child, level + 1, max_level)

# =====================================
# FUNÇÕES DE UTILIDADE E DEBUG
# =====================================

func get_event_by_year(year: int) -> String:
	"""Retorna o evento principal de um ano específico"""
	match year:
		1973: return "Golpe de Estado"
		1974: return "Criação da DINA"
		1975: return "Operação Condor"
		1976: return "Assassinato Letelier"
		1977: return "Plano de Choque Econômico"
		1978: return "Lei de Anistia"
		1980: return "Nova Constituição"
		1982: return "Crise Econômica"
		1983: return "Jornadas de Protesto"
		1984: return "Estado de Sítio"
		1985: return "Acordo Nacional"
		1986: return "Atentado contra Pinochet"
		1988: return "Plebiscito"
		1990: return "Fim da Ditadura"
		_: return "Ano sem eventos principais"

func execute_event_by_name(event_name: String):
	"""Executa um evento específico pelo nome"""
	trigger_historical_event(event_name)
	

func debug_trigger_event(event_name: String):
	"""Função para testar eventos específicos durante desenvolvimento"""
	print("DEBUG: Executando evento '%s'" % event_name)
	execute_event_by_name(event_name)

func get_all_historical_events() -> Array:
	"""Retorna lista de todos os eventos históricos disponíveis"""
	return [
		"golpe_1973", "criacao_dina", "operacao_colombo", "operacao_condor",
		"assassinato_letelier", "plano_shock", "anistia_geral", "constituicao_1980",
		"crise_economica_1982", "protestas_1983", "estado_sitio_1984",
		"acordo_nacional_1985", "atentado_pinochet_1986", "plebiscito_1988"
	]

func get_scheduled_events() -> Dictionary:
	"""Retorna o cronograma completo de eventos"""
	return scheduled_events.duplicate()

func get_country_status() -> Dictionary:
	"""Retorna status atual do país para debug"""
	var status = {}
	if _system_exists("Globals"):
		status = {
			"repression": Globals.get_country_value("Chile", "repression", 0),
			"economic_growth": Globals.get_country_value("Chile", "economic_growth", 0),
			"civil_resistance": Globals.get_country_value("Chile", "civil_resistance", 0),
			"international_pressure": Globals.get_country_value("Chile", "international_pressure", 0),
			"democratic_opposition": Globals.get_country_value("Chile", "democratic_opposition", 0),
			"condor_active": Globals.condor_active if "condor_active" in Globals else false
		}
	return status

func debug_print_country_status():
	"""Imprime status completo do país no console"""
	print("=== STATUS DO CHILE ===")
	var status = get_country_status()
	for key in status:
		print("%s: %s" % [key.capitalize(), status[key]])
	print("=======================")
