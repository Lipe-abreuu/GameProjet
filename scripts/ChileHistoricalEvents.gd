# res://scripts/ChileHistoricalEvents.gd
# Eventos históricos do Chile - Versão completa e corrigida

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
	"""Execução do evento do Golpe de 1973"""
	get_tree().paused = true
	
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
	
	# Encontra o PartyController e aplica as consequências
	var party_controller_node = _find_node_by_class("PartyController")
	if party_controller_node:
		party_controller_node.handle_coup_response(consequence)
	else:
		print("ERRO: PartyController não encontrado para processar consequências do golpe")

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
	if _system_exists("Globals"):
		Globals.condor_active = true
	
	print("MECÂNICA DE JOGO: Operação Condor está agora ATIVA.")
	
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

func _find_node_by_class(target_class_name: String) -> Node:
	"""Encontra um node pela sua classe de forma segura"""
	var candidates = [
		"Main/PartyController",
		"PartyController",
		"/root/Main/PartyController",
		"/root/PartyController"
	]
	
	for path in candidates:
		var node = get_node_or_null(path)
		if node and node.get_script() and node.get_script().get_global_name() == target_class_name:
			return node
	
	return null

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
