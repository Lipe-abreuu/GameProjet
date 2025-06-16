# PoliticalActionUI.gd - Novo script para adicionar à cena
extends Control

# Referência ao agente do jogador
var player_agent: PlayerAgent

# Referência aos elementos da UI
var action_name_label: Label
var action_description_label: Label
var action_risk_label: Label
var action_cost_label: Label
var execute_button: Button
var cancel_button: Button

# Ação atual selecionada
var current_action: Dictionary

func _ready() -> void:
	# Obter referências
	action_name_label = $ActionNameLabel
	action_description_label = $DescriptionLabel
	action_risk_label = $RiskLabel
	action_cost_label = $CostLabel
	execute_button = $ExecuteButton
	cancel_button = $CancelButton
	
	# Conectar sinais
	execute_button.pressed.connect(_on_execute_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Obter o agente do player (pode estar em Globals ou como nó da cena)
	player_agent = Globals.current_player_agent
	
	if not player_agent:
		print("Erro: PlayerAgent não encontrado!")
		queue_free()
		return
	
	# Usar a primeira ação disponível como exemplo
	var available_actions = player_agent.get_available_actions()
	if available_actions.size() > 0:
		set_current_action(available_actions[0])
	else:
		print("Aviso: Nenhuma ação disponível")
		hide()

func set_current_action(action: Dictionary) -> void:
	current_action = action
	
	# Atualizar UI
	action_name_label.text = "Executar: " + action.get("name", "Ação")
	action_description_label.text = "Descrição: " + action.get("description", "")
	action_risk_label.text = "Risco: " + str(action.get("risk", 0)) + "%"
	
	# Formatar custos
	var costs = action.get("costs", {})
	var cost_text = "Custos: "
	for cost_type in costs:
		cost_text += cost_type + ": " + str(costs[cost_type]) + " "
	action_cost_label.text = cost_text

func _on_execute_pressed() -> void:
	if player_agent and current_action:
		var result = player_agent.execute_action(current_action)
		
		# Exibir resultado
		if result.success:
			OS.alert("Ação bem-sucedida: " + result.message, "Sucesso!")
		else:
			OS.alert("Falha: " + result.message, "Falha!")
		
		# Atualizar a UI do jogo
		var game_ui = get_node("/root/Main")
		if game_ui and game_ui.has_method("_update_ui"):
			game_ui._update_ui()
		
		# Fechar diálogo
		hide()

func _on_cancel_pressed() -> void:
	hide()
