# =====================================
#  PLAYERMANAGER.GD - SISTEMA DE INTEGRAÇÃO
#  Conecta PlayerAgent com o sistema de países existente
# =====================================
extends Node

# =====================================
#  SINAIS
# =====================================
signal player_position_changed(old_position: String, new_position: String)
signal player_gained_power()
signal player_lost_power()
signal action_completed(action_name: String, success: bool)

# =====================================
#  VARIÁVEIS PRINCIPAIS
# =====================================
var player_agent: PlayerAgent
var phase_1_ui: Control  # Referência para UI da Fase 1
var phase_2_ui: Control  # Referência para UI da Fase 2 (existente)
var current_phase: int = 1

# Referências do sistema existente
var main_game_script: Node
var character_creation: Control

# =====================================
#  INICIALIZAÇÃO
# =====================================
func _ready():
	# Conectar com o sistema existente
	_setup_integration()

func _setup_integration():
	# Encontrar referências do sistema existente
	main_game_script = get_node_or_null("../Main")
	if main_game_script == null:
		main_game_script = get_tree().current_scene
	
	print("🔗 PlayerManager inicializado")

# =====================================
#  CRIAÇÃO E CONFIGURAÇÃO DO AGENTE
# =====================================
func create_player_agent(agent: PlayerAgent):
	player_agent = agent
	
	# Configurar país do jogador no sistema existente
	if Globals.has_method("set_player_country"):
		Globals.set_player_country(agent.country)
	else:
		Globals.player_country = agent.country
	
	# Inicializar dados do país se necessário
	_ensure_player_country_exists()
	
	# Configurar UI inicial
	_setup_phase_1_ui()
	
	print("👤 Agente criado: %s de %s" % [agent.name, agent.country])
	print("🎭 %s | ⚖️ %s" % [agent.background, agent.ideology])

func _ensure_player_country_exists():
	var country_data = Globals.get_country(player_agent.country)
	if country_data.is_empty():
		# Criar dados básicos do país se não existir
		Globals.country_data[player_agent.country] = {
			"money": 50000,
			"stability": 50,
			"gov_power": 50,
			"rebel_power": 50,
			"population": 10000000,
			"industry": 30,
			"defense": 40
		}

# =====================================
#  INTERFACE DA FASE 1 (AGENTE POLÍTICO)
# =====================================
func _setup_phase_1_ui():
	if phase_1_ui != null:
		phase_1_ui.queue_free()
	
	phase_1_ui = Control.new()
	phase_1_ui.name = "Phase1UI"
	add_child(phase_1_ui)
	
	_create_agent_info_panel()
	_create_actions_panel()
	_create_progress_panel()

func _create_agent_info_panel():
	# Painel de informações do agente (canto superior direito)
	var info_panel = PanelContainer.new()
	info_panel.position = Vector2(get_viewport().size.x - 320, 10)
	info_panel.custom_minimum_size = Vector2(300, 200)
	phase_1_ui.add_child(info_panel)
	
	var vbox = VBoxContainer.new()
	info_panel.add_child(vbox)
	
	# Nome e posição
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = "%s" % player_agent.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(name_label)
	
	var position_label = Label.new()
	position_label.name = "PositionLabel"
	position_label.text = "Posição: %s" % player_agent.current_position
	vbox.add_child(position_label)
	
	# Atributos principais
	var attributes_label = Label.new()
	attributes_label.name = "AttributesLabel"
	attributes_label.text = "💬%d 🧠%d 🤝%d 💰%d" % [
		player_agent.charisma, 
		player_agent.intelligence, 
		player_agent.connections, 
		player_agent.wealth
	]
	vbox.add_child(attributes_label)
	
	# Apoio total
	var support_label = Label.new()
	support_label.name = "SupportLabel"
	support_label.text = "Apoio Total: %d/700" % player_agent.get_total_support()
	vbox.add_child(support_label)
	
	# Progresso para próxima posição
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	var required = player_agent.get_required_support_for_next_position()
	var current = player_agent.get_total_support()
	progress_label.text = "Próximo: %s (%d/%d)" % [
		player_agent.get_next_position(), 
		current, 
		required
	]
	vbox.add_child(progress_label)

func _create_actions_panel():
	# Painel de ações (parte inferior da tela)
	var actions_panel = PanelContainer.new()
	actions_panel.position = Vector2(10, get_viewport().size.y - 150)
	actions_panel.custom_minimum_size = Vector2(get_viewport().size.x - 340, 130)
	phase_1_ui.add_child(actions_panel)
	
	var vbox = VBoxContainer.new()
	actions_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🎯 Ações Políticas Disponíveis:"
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	var actions_container = HBoxContainer.new()
	actions_container.name = "ActionsContainer"
	vbox.add_child(actions_container)
	
	_update_available_actions()

func _create_progress_panel():
	# Painel de progresso (lado esquerdo)
	var progress_panel = PanelContainer.new()
	progress_panel.position = Vector2(10, 120)
	progress_panel.custom_minimum_size = Vector2(280, 300)
	phase_1_ui.add_child(progress_panel)
	
	var vbox = VBoxContainer.new()
	progress_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "📊 Apoio dos Grupos:"
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	# Criar barras de progresso para cada grupo
	for group_name in player_agent.support:
		var group_container = HBoxContainer.new()
		vbox.add_child(group_container)
		
		var emoji = _get_group_emoji(group_name)
		var label = Label.new()
		label.text = "%s %s:" % [emoji, group_name.capitalize()]
		label.custom_minimum_size.x = 120
		group_container.add_child(label)
		
		var progress_bar = ProgressBar.new()
		progress_bar.name = "%sProgress" % group_name.capitalize()
		progress_bar.max_value = 100
		progress_bar.value = player_agent.support[group_name]
		progress_bar.custom_minimum_size.x = 140
		group_container.add_child(progress_bar)
		
		var value_label = Label.new()
		value_label.name = "%sValue" % group_name.capitalize()
		value_label.text = "%d" % player_agent.support[group_name]
		value_label.custom_minimum_size.x = 30
		group_container.add_child(value_label)

# =====================================
#  ATUALIZAÇÃO DA UI
# =====================================
func _update_phase_1_ui():
	if phase_1_ui == null or current_phase != 1:
		return
	
	# Buscar elementos da UI de forma mais robusta
	var panels = phase_1_ui.get_children()
	
	for panel in panels:
		if panel is PanelContainer:
			var vbox = panel.get_child(0) if panel.get_child_count() > 0 else null
			if vbox == null:
				continue
				
			# Atualizar labels se existirem
			for child in vbox.get_children():
				if child is Label:
					match child.name:
						"NameLabel":
							child.text = "%s" % player_agent.name
						"PositionLabel":
							child.text = "Posição: %s" % player_agent.current_position
						"AttributesLabel":
							child.text = "💬%d 🧠%d 🤝%d 💰%d" % [
								player_agent.charisma, 
								player_agent.intelligence, 
								player_agent.connections, 
								player_agent.wealth
							]
						"SupportLabel":
							child.text = "Apoio Total: %d/700" % player_agent.get_total_support()
						"ProgressLabel":
							var required = player_agent.get_required_support_for_next_position()
							var current = player_agent.get_total_support()
							child.text = "Próximo: %s (%d/%d)" % [
								player_agent.get_next_position(), 
								current, 
								required
							]
	
	_update_available_actions()

func _update_available_actions():
	# Buscar container de ações
	var actions_container: HBoxContainer = null
	
	if phase_1_ui:
		for panel in phase_1_ui.get_children():
			if panel is PanelContainer:
				var vbox = panel.get_child(0) if panel.get_child_count() > 0 else null
				if vbox:
					for child in vbox.get_children():
						if child is HBoxContainer and child.name == "ActionsContainer":
							actions_container = child
							break
	
	if actions_container == null:
		return
	
	# Limpar ações antigas
	for child in actions_container.get_children():
		child.queue_free()
	
	# Adicionar ações disponíveis
	var available_actions = player_agent.get_available_actions()
	for action in available_actions:
		var action_button = Button.new()
		action_button.text = action["name"]
		action_button.custom_minimum_size = Vector2(150, 40)
		action_button.pressed.connect(_on_action_selected.bind(action))
		actions_container.add_child(action_button)
		
		# Tooltip com informações da ação
		var tooltip = "Risco: %d%%\n" % action.get("risk", 0)
		if action.has("cost"):
			tooltip += "Custo: "
			for cost_type in action["cost"]:
				tooltip += "%s: %d " % [cost_type, action["cost"][cost_type]]
		action_button.tooltip_text = tooltip

# =====================================
#  SISTEMA DE AÇÕES
# =====================================
func _on_action_selected(action: Dictionary):
	print("🎯 Executando ação: %s" % action["name"])
	
	var result = player_agent.execute_action(action)
	
	# Mostrar resultado
	_show_action_result(action["name"], result)
	
	# Atualizar UI
	_update_phase_1_ui()
	
	# Verificar se pode avançar posição
	_check_position_advancement()
	
	# Emitir sinal
	action_completed.emit(action["name"], result["success"])

func _show_action_result(action_name: String, result: Dictionary):
	# Criar popup com resultado
	var dialog = AcceptDialog.new()
	dialog.title = "Resultado da Ação"
	
	var message = "🎯 %s\n\n" % action_name
	message += result["message"] + "\n"
	
	if result.has("events") and result["events"].size() > 0:
		message += "\n📰 Eventos:\n"
		for event in result["events"]:
			message += "• %s\n" % event
	
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func _check_position_advancement():
	if player_agent.can_advance_position():
		var old_position = player_agent.current_position
		if player_agent.advance_position():
			player_position_changed.emit(old_position, player_agent.current_position)
			
			# Se chegou a presidente, transição para Fase 2
			if player_agent.current_position == "Presidente":
				_transition_to_phase_2()

# =====================================
#  TRANSIÇÃO ENTRE FASES
# =====================================
func _transition_to_phase_2():
	print("🏛️ TRANSIÇÃO PARA FASE 2: PRESIDENTE!")
	
	current_phase = 2
	player_agent.in_power = true
	
	# Esconder UI da Fase 1
	if phase_1_ui:
		phase_1_ui.visible = false
	
	# Ativar sistema existente (Fase 2)
	if main_game_script and main_game_script.has_method("_update_ui"):
		main_game_script._update_ui()
	
	# Sincronizar dados com Globals
	_sync_agent_with_country_data()
	
	player_gained_power.emit()
	
	# Mostrar notificação épica
	_show_presidency_achievement()

func _sync_agent_with_country_data():
	# Transferir dados do agente para o sistema de países
	var country_data = Globals.get_country(player_agent.country)
	
	# Ajustar dados do país baseado no agente
	var stability_bonus = (player_agent.get_total_support() - 350) / 10  # -35 a +35
	var money_bonus = player_agent.wealth * 1000  # Riqueza pessoal vira orçamento
	
	Globals.adjust_country_value(player_agent.country, "stability", stability_bonus)
	Globals.adjust_country_value(player_agent.country, "money", money_bonus)
	
	# Ajustar poder governamental baseado no apoio
	var gov_power = 50 + (player_agent.support["military"] / 2)
	Globals.set_country_value(player_agent.country, "gov_power", gov_power)

func _show_presidency_achievement():
	var dialog = AcceptDialog.new()
	dialog.title = "🏛️ PRESIDENTE ELEITO!"
	
	var message = "🎉 PARABÉNS! 🎉\n\n"
	message += "%s foi eleito PRESIDENTE de %s!\n\n" % [player_agent.name, player_agent.country]
	message += "Agora você tem o poder de governar o país durante a turbulenta década de 1970.\n\n"
	message += "• Use suas habilidades políticas com sabedoria\n"
	message += "• Gerencie a economia e estabilidade\n"
	message += "• Navegue pelas pressões da Guerra Fria\n"
	message += "• Sobreviva às conspirações e golpes\n\n"
	message += "A Fase 2 começou - BOA SORTE! 🍀"
	
	dialog.dialog_text = message
	dialog.custom_minimum_size = Vector2(400, 300)
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

# =====================================
#  INTEGRAÇÃO COM SISTEMA DE TEMPO
# =====================================
func advance_month():
	if player_agent == null:
		return
	
	# Avançar tempo do agente
	player_agent.advance_month()
	
	# Atualizar UI se estiver na Fase 1
	if current_phase == 1:
		_update_phase_1_ui()
	
	# Verificar eventos especiais
	_check_special_events()

func _check_special_events():
	# Verificar se foi preso, exilado, etc.
	if player_agent.is_imprisoned:
		_handle_imprisonment()
	elif player_agent.is_in_exile:
		_handle_exile()
	
	# Verificar oportunidades de golpe
	if player_agent.can_attempt_military_coup() and randi() % 100 < 10:
		_offer_coup_opportunity()

func _handle_imprisonment():
	print("⚠️ %s foi preso!" % player_agent.name)
	# Implementar mecânicas de prisão/tortura/escape

func _handle_exile():
	print("⚠️ %s está no exílio!" % player_agent.name)
	# Implementar mecânicas de exílio/resistência

func _offer_coup_opportunity():
	# Oferecer oportunidade de golpe militar
	var dialog = ConfirmationDialog.new()
	dialog.title = "🎖️ Oportunidade de Golpe"
	dialog.dialog_text = "Contactos militares oferecem apoio para um golpe de estado. Aceitar?"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(_attempt_military_coup)
	dialog.canceled.connect(dialog.queue_free)

func _attempt_military_coup():
	print("🎖️ Tentando golpe militar...")
	# Implementar lógica de golpe

# =====================================
#  UTILIDADES
# =====================================
func _get_group_emoji(group: String) -> String:
	match group:
		"military": return "⚔️"
		"business": return "💼"
		"intellectuals": return "🎓"
		"workers": return "🔨"
		"students": return "📚"
		"church": return "⛪"
		"peasants": return "🌾"
		_: return "👥"

func get_current_phase() -> int:
	return current_phase

func is_player_in_power() -> bool:
	return player_agent != null and player_agent.in_power

func get_player_agent() -> PlayerAgent:
	return player_agent

# =====================================
#  SAVE/LOAD DO AGENTE
# =====================================
func save_player_data() -> Dictionary:
	if player_agent == null:
		return {}
	
	return {
		"name": player_agent.name,
		"age": player_agent.age,
		"country": player_agent.country,
		"background": player_agent.background,
		"ideology": player_agent.ideology,
		"current_position": player_agent.current_position,
		"in_power": player_agent.in_power,
		"years_in_position": player_agent.years_in_position,
		"political_experience": player_agent.political_experience,
		"charisma": player_agent.charisma,
		"intelligence": player_agent.intelligence,
		"connections": player_agent.connections,
		"wealth": player_agent.wealth,
		"military_knowledge": player_agent.military_knowledge,
		"support": player_agent.support,
		"usa_influence": player_agent.usa_influence,
		"ussr_influence": player_agent.ussr_influence,
		"is_in_exile": player_agent.is_in_exile,
		"is_underground": player_agent.is_underground,
		"is_imprisoned": player_agent.is_imprisoned,
		"condor_target_level": player_agent.condor_target_level,
		"major_events": player_agent.major_events,
		"allies": player_agent.allies,
		"enemies": player_agent.enemies,
		"current_phase": current_phase
	}

func load_player_data(data: Dictionary):
	if data.is_empty():
		return
	
	player_agent = PlayerAgent.new()
	player_agent.name = data.get("name", "")
	player_agent.age = data.get("age", 30)
	player_agent.country = data.get("country", "")
	player_agent.background = data.get("background", "Estudante")
	player_agent.ideology = data.get("ideology", "Social-Democrata")
	player_agent.current_position = data.get("current_position", "Cidadão")
	player_agent.in_power = data.get("in_power", false)
	player_agent.years_in_position = data.get("years_in_position", 0)
	player_agent.political_experience = data.get("political_experience", 0)
	player_agent.charisma = data.get("charisma", 50)
	player_agent.intelligence = data.get("intelligence", 50)
	player_agent.connections = data.get("connections", 50)
	player_agent.wealth = data.get("wealth", 50)
	player_agent.military_knowledge = data.get("military_knowledge", 50)
	player_agent.support = data.get("support", {})
	player_agent.usa_influence = data.get("usa_influence", 0)
	player_agent.ussr_influence = data.get("ussr_influence", 0)
	player_agent.is_in_exile = data.get("is_in_exile", false)
	player_agent.is_underground = data.get("is_underground", false)
	player_agent.is_imprisoned = data.get("is_imprisoned", false)
	player_agent.condor_target_level = data.get("condor_target_level", 0)
	player_agent.major_events = data.get("major_events", [])
	player_agent.allies = data.get("allies", [])
	player_agent.enemies = data.get("enemies", [])
	current_phase = data.get("current_phase", 1)
	
	# Reconfigurar baseado na fase
	if current_phase == 1:
		_setup_phase_1_ui()
	else:
		_transition_to_phase_2()

# =====================================
#  DEBUG E TESTES
# =====================================
func debug_advance_to_president():
	if player_agent == null:
		return
	
	print("🔧 DEBUG: Avançando para presidente")
	
	# Forçar apoio máximo
	for group in player_agent.support:
		player_agent.support[group] = 85
	
	# Forçar posição
	player_agent.current_position = "Presidente"
	player_agent.in_power = true
	
	_transition_to_phase_2()

func debug_create_test_agent(country: String = "Argentina"):
	var test_agent = PlayerAgent.create_preset_character("intelectual_democrata", country)
	create_player_agent(test_agent)
	print("🔧 DEBUG: Agente de teste criado")

func get_debug_info() -> String:
	if player_agent == null:
		return "Nenhum agente criado"
	
	var info = "=== DEBUG INFO ===\n"
	info += "Fase: %d\n" % current_phase
	info += "Agente: %s\n" % player_agent.name
	info += "Posição: %s\n" % player_agent.current_position
	info += "Apoio Total: %d/700\n" % player_agent.get_total_support()
	info += "No Poder: %s\n" % ("Sim" if player_agent.in_power else "Não")
	
	if player_agent.is_imprisoned:
		info += "⚠️ PRESO\n"
	if player_agent.is_in_exile:
		info += "⚠️ EXILADO\n"
	if player_agent.condor_target_level > 50:
		info += "⚠️ ALTA AMEAÇA CONDOR\n"
	
	return info
