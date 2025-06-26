# res://scripts/ChileHistoricalEvents.gd
# Gestor da timeline histórica do Chile (1973-1990), com todos os eventos do plano.
extends Node

# Sinal para notificar o jogo sobre um evento, de forma desacoplada da UI.
signal historical_event_notification(title, message, type)

# Carrega a cena do diálogo de escolha para ser usada nos eventos.
const ChoiceDialog = preload("res://scenes/ChoiceDialog.tscn")

# =============================================================================
# TIMELINE COMPLETA DE EVENTOS (Baseado nos seus documentos de design)
# =============================================================================
var scheduled_events: Dictionary = {
	1973: {
		9: ["golpe_setembro"]
	},
	1974: {
		6: ["criacao_dina"],
		10: ["operacao_colombo"]
	},
	1975: {
		6: ["plano_shock"],
		8: ["operacao_condor"]
	},
	1976: {
		9: ["assassinato_letelier"]
	},
	1978: {
		4: ["anistia_geral"]
	},
	1980: {
		8: ["plebiscito_1980"]
	},
	1982: {
		1: ["crise_economica_1982"]
	},
	1983: {
		5: ["protestos_nacionais"]
	},
	1986: {
		9: ["atentado_pinochet"]
	},
	1988: {
		10: ["plebiscito_1988"]
	},
	1989: {
		12: ["eleicoes_1989"]
	}
}

# -----------------------------------------------------------------------------
# LÓGICA PRINCIPAL (Não precisa de ser alterada)
# -----------------------------------------------------------------------------

# Função chamada todo mês pelo main.gd para verificar se há um evento agendado.
func check_for_events(year: int, month: int):
	if scheduled_events.has(year) and scheduled_events[year].has(month):
		for event_id in scheduled_events[year][month]:
			if _are_conditions_met(event_id):
				trigger_historical_event(event_id)

# Dispara a função correspondente ao ID do evento.
func trigger_historical_event(event_id: String):
	print("EVENTO HISTÓRICO DISPARADO: ", event_id)
	if has_method("execute_" + event_id):
		call("execute_" + event_id)
	else:
		printerr("AVISO: A função para o evento '%s' ainda não foi implementada." % event_id)

# =============================================================================
# IMPLEMENTAÇÃO DOS EVENTOS
# =============================================================================

# --- PERÍODO 1: INSTALAÇÃO DA DITADURA (1973-1976) ---

func execute_golpe_setembro():
	get_tree().paused = true
	emit_signal("historical_event_notification", "11 de Setembro de 1973", "Forças Armadas iniciam um golpe de estado.", NotificationSystem.NotificationType.ERROR)
	TraumaSystem.create_trauma("Golpe_1973_Real", {"name": "O Golpe de 11 de Setembro", "type": "political", "intensity": 2.0, "triggers": ["militar", "golpe", "repressão"], "year": 1973})
	
	var choices = [{"text": "Condenar e resistir.", "consequence": "resist"}, {"text": "Manter silêncio.", "consequence": "wait_and_see"}, {"text": "Buscar exílio.", "consequence": "exile"}]
	var dialog = ChoiceDialog.instantiate()
	dialog.connect("choice_made", _on_golpe_1973_choice_made)
	get_tree().root.add_child(dialog)
	dialog.setup_choices("O Golpe Aconteceu!", "Como o seu partido reage?", choices)

func _on_golpe_1973_choice_made(consequence: String):
	get_tree().paused = false
	var party_controller_node = get_tree().root.get_node("Main/PartyController")
	if party_controller_node:
		party_controller_node.handle_coup_response(consequence)

func execute_criacao_dina():
	emit_signal("historical_event_notification", "Criação da DINA", "O regime cria a sua temida polícia secreta. A repressão irá intensificar-se.", NotificationSystem.NotificationType.ERROR)
	Globals.adjust_country_value("Chile", "repression", 30)

func execute_operacao_colombo():
	emit_signal("historical_event_notification", "Operação Colombo", "O regime simula confrontos para encobrir o desaparecimento de opositores.", NotificationSystem.NotificationType.INFO)
	NarrativeSystem.create_narrative_from_action("operacao_colombo", "system")

func execute_operacao_condor():
	emit_signal("historical_event_notification", "Operação Condor", "As ditaduras do Cone Sul unem-se para perseguir opositores além das suas fronteiras. O exílio já não é um lugar seguro.", NotificationSystem.NotificationType.ERROR)
	Globals.condor_active = true
	print("MECÂNICA DE JOGO: Operação Condor está agora ATIVA.")

func execute_assassinato_letelier():
	emit_signal("historical_event_notification", "Assassinato em Washington", "O ex-chanceler Orlando Letelier é assassinado pela DINA nos EUA, causando uma crise diplomática.", NotificationSystem.NotificationType.ERROR)
	Globals.adjust_country_value("Chile", "international_pressure", 25)
	TraumaSystem.create_trauma("Crise_Diplomatica_EUA", {"name": "Crise Diplomática com os EUA", "type": "diplomatic", "intensity": 1.5, "triggers": ["eua", "cia", "washington", "diplomacia"], "year": 1976})

# --- PERÍODO 2: INSTITUCIONALIZAÇÃO (1977-1982) ---

func execute_plano_shock():
	emit_signal("historical_event_notification", "Plano de Choque Económico", "Os 'Chicago Boys' assumem a economia, implementando reformas neoliberais drásticas.", NotificationSystem.NotificationType.INFO)

func execute_anistia_geral():
	emit_signal("historical_event_notification", "Lei de Anistia", "O regime decreta uma anistia geral para crimes políticos cometidos desde 1973, garantindo impunidade para agentes do Estado.", NotificationSystem.NotificationType.INFO)

func execute_plebiscito_1980():
	emit_signal("historical_event_notification", "Plebiscito de 1980", "O regime realiza um plebiscito para aprovar uma nova Constituição, que institucionaliza o seu poder.", NotificationSystem.NotificationType.INFO)
	Globals.adjust_country_value("Chile", "stability", 15)
	Globals.adjust_country_value("Chile", "gov_power", 20)

func execute_crise_economica_1982():
	emit_signal("historical_event_notification", "Crise da Dívida de 1982", "Uma grave crise económica atinge a América Latina. O 'Milagre Chileno' chega a um fim abrupto.", NotificationSystem.NotificationType.ERROR)
	Globals.country_data["Chile"]["economic_modifier"] = 0.4
	TraumaSystem.create_trauma("Crise_1982", {"name": "A Crise de 1982", "type": "economic", "intensity": 1.8, "triggers": ["economia", "crise", "desemprego"], "year": 1982})
	NarrativeSystem.create_narrative_from_action("colapso_economico", "system")

# --- PERÍODO 3: CRISE E PROTESTOS (1983-1988) ---

func execute_protestos_nacionais():
	emit_signal("historical_event_notification", "Jornadas de Protesto Nacional", "A crise económica e a repressão levam a uma onda de protestos massivos por todo o país.", NotificationSystem.NotificationType.INFO)
	Globals.adjust_country_value("Chile", "stability", -20)
	Globals.adjust_country_value("Chile", "rebel_power", 15)

func execute_atentado_pinochet():
	emit_signal("historical_event_notification", "Atentado a Pinochet", "A Frente Patriótica Manuel Rodríguez tenta assassinar o General Pinochet. Ele sobrevive, e o regime responde com uma onda de repressão brutal.", NotificationSystem.NotificationType.ERROR)
	Globals.adjust_country_value("Chile", "repression", 40)

# --- PERÍODO 4: TRANSIÇÃO (1988-1990) ---

func execute_plebiscito_1988():
	emit_signal("historical_event_notification", "Convocação do Plebiscito", "O futuro do regime será decidido num plebiscito histórico: 'SIM' para a continuidade, 'NÃO' para eleições livres.", NotificationSystem.NotificationType.SUCCESS)

func execute_eleicoes_1989():
	emit_signal("historical_event_notification", "Eleições Presidenciais", "O Chile realiza as suas primeiras eleições presidenciais livres em quase 20 anos.", NotificationSystem.NotificationType.SUCCESS)

# -----------------------------------------------------------------------------
# CONDIÇÕES PARA EVENTOS
# -----------------------------------------------------------------------------
func _are_conditions_met(event_id: String) -> bool:
	# Por agora, todos os eventos são automáticos. No futuro, podemos adicionar condições aqui.
	return true
