# res://scripts/ChileHistoricalEvents.gd
# Gerencia a timeline de eventos históricos para o Chile, disparando-os
# nas datas corretas e apresentando escolhas ao jogador.
extends Node

# Sinal emitido para que a UI possa mostrar notificações sem acoplar os sistemas.
signal historical_event_notification(title, message, type)

# Carrega a cena do diálogo de escolha para ser usada nos eventos.
const ChoiceDialog = preload("res://scenes/ChoiceDialog.tscn")

# Dicionário com a timeline de eventos.
# A estrutura é: { ano: { mes: [id_do_evento] } }
var scheduled_events: Dictionary = {
	1973: {
		9: ["golpe_setembro"] # Em Setembro de 1973, dispara o evento do golpe.
	},
	1974: {
		6: ["criacao_dina"] # Em Junho de 1974, dispara a criação da DINA.
	}
	# Adicione aqui outros eventos históricos conforme o seu plano de design.
}

# -----------------------------------------------------------------------------
# LÓGICA PRINCIPAL DO SISTEMA DE EVENTOS
# -----------------------------------------------------------------------------

# Função chamada todo mês pelo main.gd para verificar se há um evento agendado.
func check_for_events(year: int, month: int):
	if scheduled_events.has(year) and scheduled_events[year].has(month):
		for event_id in scheduled_events[year][month]:
			trigger_historical_event(event_id)

# Dispara a função correspondente ao ID do evento.
func trigger_historical_event(event_id: String):
	print("EVENTO HISTÓRICO DISPARADO: ", event_id)
	if has_method("execute_" + event_id):
		call("execute_" + event_id)
	else:
		printerr("ERRO: A função para o evento '%s' não foi encontrada." % event_id)

# =============================================================================
# IMPLEMENTAÇÃO DOS EVENTOS HISTÓRICOS
# =============================================================================

# --- EVENTO: GOLPE DE 1973 ---
func execute_golpe_setembro():
	# 1. Pausa o jogo e emite um sinal para a UI mostrar a notificação.
	get_tree().paused = true
	emit_signal("historical_event_notification",
		"11 de Setembro de 1973",
		"Forças Armadas iniciam um golpe de estado para derrubar o governo.",
		NotificationSystem.NotificationType.ERROR
	)
	
	# 2. Cria um Trauma Coletivo que afetará o jogo a partir de agora.
	TraumaSystem.create_trauma("Golpe_1973_Real", {
		"name": "O Golpe de 11 de Setembro", "type": "political", "intensity": 2.0,
		"affected_groups": ["intellectuals", "workers", "students"],
		"triggers": ["militar", "golpe", "intervenção", "quartel", "repressão"],
		"year": 1973
	})
	
	# 3. Define as escolhas que o jogador terá que fazer, com base no seu plano.
	var choices = [
		{"text": "Condenar o golpe e organizar a resistência.", "consequence": "resist"},
		{"text": "Manter silêncio e esperar para ver o que acontece.", "consequence": "wait_and_see"},
		{"text": "Buscar asilo em uma embaixada para se exilar.", "consequence": "exile"}
	]
	
	# 4. Instancia e configura a janela de diálogo para apresentar as escolhas.
	var dialog = ChoiceDialog.instantiate()
	dialog.choice_made.connect(_on_golpe_1973_choice_made)
	get_tree().root.add_child(dialog)
	dialog.setup_choices("O Golpe Aconteceu!", "Como o seu partido reage?", choices)

# Função para lidar com a consequência da escolha do jogador no evento do golpe.
func _on_golpe_1973_choice_made(consequence: String):
	get_tree().paused = false # Despausa o jogo assim que a escolha é feita.
	
	print("CONSEQUÊNCIA DO GOLPE: O partido escolheu '%s'" % consequence)
	
	# Acessa o PartyController (que é um Autoload) de forma segura.
	var party_controller_node = get_tree().root.get_node("PartyController")
	if party_controller_node:
		# Chama a função no controlador para aplicar os efeitos da escolha.
		party_controller_node.handle_coup_response(consequence)
	else:
		printerr("ERRO CRÍTICO: O Autoload 'PartyController' não foi encontrado na raiz da cena.")


# --- EVENTO: CRIAÇÃO DA DINA (Exemplo de futuro evento) ---
func execute_criacao_dina():
	emit_signal("historical_event_notification",
		"Junho de 1974",
		"O regime cria a DINA, a nova e temida polícia secreta.",
		NotificationSystem.NotificationType.ERROR
	)
	# TODO: Adicionar consequências, como aumento da repressão.
