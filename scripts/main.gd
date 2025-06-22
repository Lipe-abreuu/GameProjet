# =====================================
#  MAIN.GD - VERSÃO COMPLETA PROFISSIONAL
#  Arquitetura limpa com todas as funções implementadas
# =====================================
extends Node

# =====================================
#  PRELOADS E IMPORTS
# =====================================
const NotificationSystem = preload("res://scripts/NotificationSystem.gd")
const GameMenu = preload("res://scenes/GameMenu.tscn")

# =====================================
#  CONSTANTES E CONFIGURAÇÕES
# =====================================
const MONTH_NAMES: Array[String] = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]
const AUTO_SAVE_INTERVAL: float = 30.0
const DEBUG_MODE: bool = true

# =====================================
#  ENUMS
# =====================================
enum GamePhase {
	POLITICAL_AGENT = 1,
	NATIONAL_LEADER = 2
}

# =====================================
#  SINAIS
# =====================================
signal game_phase_changed(old_phase: GamePhase, new_phase: GamePhase)
signal month_advanced(month: int, year: int)
signal agent_status_changed()
signal condor_event_triggered(event_data: Dictionary)
signal military_opportunity_offered(opportunity: Dictionary)

# =====================================
#  ESTADO DO JOGO
# =====================================
@export var time_running: bool = true
@export var current_phase: GamePhase = GamePhase.POLITICAL_AGENT
@export var auto_save_enabled: bool = true

# =====================================
#  COMPONENTES PRINCIPAIS
# =====================================
var player_agent: PlayerAgent
var notification_system: NotificationSystem
var ui_manager: UIManager
var timer: Timer
var auto_save_timer: Timer

# =====================================
#  REFERÊNCIAS DA UI
# =====================================
var date_label: Label
var money_label: Label
var stability_label: Label
var pause_button: Button
var next_button: Button
var info_container: VBoxContainer

# =====================================
#  CACHE DE DADOS
# =====================================
var cached_country_data: Dictionary = {}
var last_cache_update: int = 0

# =====================================
#  INICIALIZAÇÃO
# =====================================
func _ready() -> void:
	print("🎮 Iniciando sistema principal...")
	_initialize_globals()
	_initialize_systems()

	# --- Bloco de Criação do Menu de Pausa ---
	var GameMenu = preload("res://scenes/GameMenu.tscn")
	var game_menu_instance = GameMenu.instantiate()
	game_menu_instance.name = "GameMenu"
	# Importante: Faz o menu funcionar mesmo quando o jogo está pausado
	game_menu_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	game_menu_instance.hide() # O menu começa escondido
	add_child(game_menu_instance)

	# Conecta os sinais do menu às funções que já criamos em main.gd
	game_menu_instance.resume_game.connect(_on_resume_game)
	game_menu_instance.quit_to_main_menu.connect(_on_quit_to_main_menu)
	# --- Fim do Bloco do Menu ---

	_setup_ui_references()
	_setup_timers()
	_setup_input_handling()
	_create_default_agent()
	_start_game_loop()
	
func _initialize_globals() -> void:
	# Inicializar o sistema global
	if Globals.has_method("init_player_agent"):
		Globals.init_player_agent()
	else:
		push_error("Globals.init_player_agent() não encontrado!")

func _initialize_systems() -> void:
	# Sistema de notificações
	notification_system = NotificationSystem.new()
	notification_system.name = "NotificationSystem"
	add_child(notification_system)
	
	# UI Manager
	ui_manager = UIManager.new()
	ui_manager.name = "UIManager"
	ui_manager.setup(self)
	add_child(ui_manager)
	
	print("✅ Sistemas principais inicializados")

func _setup_ui_references() -> void:
	# Busca os elementos da UI de forma robusta
	var ui_paths = {
		"date_label": ["CanvasLayer/TopBar/HBoxContainer/DateLabel", "TopBar/HBoxContainer/DateLabel"],
		"money_label": ["CanvasLayer/TopBar/HBoxContainer/MoneyLabel", "TopBar/HBoxContainer/MoneyLabel"],
		"stability_label": ["CanvasLayer/TopBar/HBoxContainer/StabilityLabel", "TopBar/HBoxContainer/StabilityLabel"],
		"pause_button": ["CanvasLayer/BottomBar/HBoxContainer/PauseButton", "BottomBar/HBoxContainer/PauseButton"],
		"next_button": ["CanvasLayer/BottomBar/HBoxContainer/NextButton", "BottomBar/HBoxContainer/NextButton"],
		"info_container": ["CanvasLayer/Sidepanel/InfoContainer", "Sidepanel/InfoContainer"]
	}
	
	for ref_name in ui_paths:
		var found_node = null
		for path in ui_paths[ref_name]:
			found_node = get_node_or_null(path)
			if found_node:
				break
		
		set(ref_name, found_node)
		if DEBUG_MODE:
			print("UI %s: %s" % [ref_name, "✅" if found_node else "❌"])

func _setup_timers() -> void:
	# Timer principal do jogo
	timer = Timer.new()
	timer.name = "GameTimer"
	timer.wait_time = 3.0
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Timer de auto-save
	if auto_save_enabled:
		auto_save_timer = Timer.new()
		auto_save_timer.name = "AutoSaveTimer"
		auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
		auto_save_timer.timeout.connect(_on_auto_save)
		add_child(auto_save_timer)
		auto_save_timer.start()
	
	# Configurar botões
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
		pause_button.text = "⏸ Pausar"
		
	if next_button:
		next_button.pressed.connect(_on_next_month_pressed)
		next_button.text = "▶️ Próximo Mês"

func _setup_input_handling() -> void:
	set_process_unhandled_input(true)
	set_process_input(true)

func _create_default_agent() -> void:
	print(">> Criando agente político padrão...")

	player_agent = PlayerAgent.new()
	# Atribuir os valores diretamente às variáveis do agente
	player_agent.agent_name = "Lautaro Silva"
	player_agent.ideology = "Socialista Reformista"
	player_agent.wealth = 300
	player_agent.age = 35 # Adicionei uma idade padrão
	player_agent.country = "Chile"
	
	# Adiciona o agente à cena para que ele possa funcionar
	add_child(player_agent)

	if not player_agent:
		push_error("Falha ao criar PlayerAgent!")
		return

	# Conectar sinais do agente (ajustar se necessário)
	if not player_agent.position_advanced.is_connected(_on_agent_position_advanced):
		player_agent.position_advanced.connect(_on_agent_position_advanced)

	if not player_agent.support_changed.is_connected(_on_agent_support_changed):
		player_agent.support_changed.connect(_on_agent_support_changed)

	Globals.player_country = player_agent.country
	_ensure_country_data_exists()

	print("✅ Agente criado: %s (%s)" % [player_agent.agent_name, player_agent.get_position_name()])

	
	# Conectar sinais do agente
	if not player_agent.position_advanced.is_connected(_on_agent_position_advanced):
		player_agent.position_advanced.connect(_on_agent_position_advanced)
	if not player_agent.support_changed.is_connected(_on_agent_support_changed):
		player_agent.support_changed.connect(_on_agent_support_changed)
	
	# Configurar país no sistema global
	Globals.player_country = player_agent.country
	_ensure_country_data_exists()
	
	print("✅ Agente criado: %s (%s)" % [player_agent.get_position_name(), player_agent.get_position_name()])

func _ensure_country_data_exists() -> void:
	if not Globals.country_data.has(player_agent.country):
		Globals.country_data[player_agent.country] = {
			"money": 50000,
			"stability": 50,
			"gov_power": 50,
			"rebel_power": 50,
			"population": 45000000,
			"industry": 35,
			"defense": 40
		}

func _start_game_loop() -> void:
	timer.start()
	_update_all_ui()
	
	if notification_system:
		notification_system.show_notification(
			"🎮 Jogo Iniciado", 
			"Sistema carregado com sucesso!", 
			NotificationSystem.NotificationType.SUCCESS
		)
	
	print("🎮 Jogo iniciado - Fase: %s" % GamePhase.keys()[current_phase])

# =====================================
#  LOOP PRINCIPAL DO JOGO
# =====================================
func _on_timer_timeout() -> void:
	if time_running:
		advance_month()

func advance_month() -> void:
	# Avançar tempo global
	Globals.current_month += 1
	if Globals.current_month > 12:
		Globals.current_month = 1
		Globals.current_year += 1
		
		if notification_system:
			notification_system.show_notification(
				"📅 Novo Ano", 
				"Chegamos a %d!" % Globals.current_year, 
				NotificationSystem.NotificationType.SUCCESS
			)
	
	# Processar sistemas baseado na fase
	match current_phase:
		GamePhase.POLITICAL_AGENT:
			_process_agent_phase()
		GamePhase.NATIONAL_LEADER:
			_process_leader_phase()
	
	# Emitir sinal e atualizar UI
	month_advanced.emit(Globals.current_month, Globals.current_year)
	_update_all_ui()
	
	if DEBUG_MODE:
		print("📅 %s %d - Fase %d" % [
			MONTH_NAMES[Globals.current_month - 1], 
			Globals.current_year, 
			current_phase
		])

func _process_agent_phase() -> void:
	if not player_agent:
		push_warning("player_agent é null em _process_agent_phase")
		return
		
	# Avançar agente
	player_agent.advance_month()
	
	# Verificar transição para fase 2
	if player_agent.position_level == 5: # Verifica se o nível do jogador é 5 (Presidente)
		_transition_to_leader_phase()
	
	# Eventos aleatórios de agente
	_process_agent_events()

func _process_leader_phase() -> void:
	# Processar como líder nacional
	if Globals.has_method("simulate_monthly_changes"):
		Globals.simulate_monthly_changes()
	
	# Eventos históricos e aleatórios
	_process_national_events()

func _process_agent_events() -> void:
	if not player_agent:
		return
		
	# Simulação de atividade política automática
	if randf() < 0.3: # 30% chance
		_simulate_political_activity()
	
	# Eventos especiais baseados no contexto
	if player_agent.condor_threat_level > 60 and randf() < 0.1:
		_trigger_condor_event()
	
	if player_agent.personal_support["military"] >= 70 and randf() < 0.05:

		_offer_military_opportunity()

func _simulate_political_activity() -> void:
	if not player_agent:
		return
		
	var activity_chance = (player_agent.charisma + player_agent.intelligence + player_agent.connections) / 300.0
	
	if randf() < activity_chance:
		# A lista de grupos deve corresponder exatamente às chaves do nosso dicionário
		var support_groups = ["military", "business", "intellectual", "worker", "student", "church", "peasant"]
		var random_group = support_groups[randi() % support_groups.size()]
		
		# Pegamos o valor atual diretamente do dicionário
		var old_value = player_agent.personal_support[random_group]
		var gain = randi_range(1, 3)
		var new_value = old_value + gain
		
		# Usamos a função set_support() que já criamos.
		# Ela vai atualizar o valor, o total_support e emitir o sinal, tudo de forma segura.
		player_agent.set_support(random_group, new_value)
		
		# A notificação agora é mais simples
		if notification_system:
			notification_system.show_notification(
				"📈 Atividade Política",
				"%s ganhou %d de apoio com o grupo %s." % [player_agent.agent_name, gain, random_group],
				NotificationSystem.NotificationType.SUCCESS
			)


func _process_national_events() -> void:
	# Eventos aleatórios nacionais
	if randf() < 0.15: # 15% chance
		_trigger_random_national_event()

func _trigger_random_national_event() -> void:
	var countries = Globals.country_data.keys()
	if countries.is_empty():
		return
		
	var random_country = countries[randi() % countries.size()]
	if Globals.has_method("apply_random_event"):
		var event = Globals.apply_random_event(random_country)
		print("📰 EVENTO: %s em %s" % [event.get("name", "Evento"), random_country])

# =====================================
#  EVENTOS ESPECIAIS DO AGENTE
# =====================================
func _trigger_condor_event() -> void:
	"""Evento relacionado à Operação Condor"""
	if not player_agent:
		return
	
	var event_data = {
		"type": "condor_warning",
		"severity": player_agent.condor_threat_level,
		"message": "Inteligência detectou atividade suspeita. Cuidado com suas ações."
	}
	
	# Possíveis consequências
	if player_agent.condor_threat_level > 80:
		var consequences = ["surveillance", "intimidation", "arrest_attempt"]
		event_data["consequence"] = consequences[randi() % consequences.size()]
		
		match event_data["consequence"]:
			"surveillance":
				player_agent.connections = max(0, player_agent.connections - 5)
				event_data["message"] = "Você está sendo vigiado. Contatos reduzidos."
			"intimidation":
				player_agent.charisma = max(0, player_agent.charisma - 3)
				event_data["message"] = "Ameaças recebidas afetaram sua confiança."
			"arrest_attempt":
				if player_agent.military_support < 50:
					if player_agent.current_position == "Ativista":
						event_data["message"] = "Tentativa de prisão! Você teve que recuar."
	
	if notification_system:
		notification_system.show_notification(
			"⚠️ Operação Condor",
			event_data["message"],
			NotificationSystem.NotificationType.WARNING,
			5.0
		)
	
	condor_event_triggered.emit(event_data)

func _offer_military_opportunity() -> void:
	"""Oferece oportunidade de aliança militar"""
	if not player_agent:
		return
	
	var opportunity = {
		"type": "military_alliance",
		"requirement": 70,
		"reward": "position_boost"
	}
	
	if notification_system:
		notification_system.show_notification(
			"🎖️ Oportunidade Militar",
			"Os militares querem conversar. Esta pode ser sua chance!",
			NotificationSystem.NotificationType.INFO,
			4.0
		)
	
	# Adicionar opção de ação especial temporária
	player_agent.add_temporary_action({
		"id": "military_meeting",
		"name": "Reunião com Militares",
		"duration": 3, # Disponível por 3 meses
		"requirements": {"military_support": 70},
		"effects": {
			"position_advance": true,
			"military_support": 10,
			"condor_threat_level": -20
		}
	})
	
	military_opportunity_offered.emit(opportunity)

# =====================================
#  TRANSIÇÃO ENTRE FASES
# =====================================
func _transition_to_leader_phase() -> void:
	var old_phase = current_phase
	current_phase = GamePhase.NATIONAL_LEADER
	
	# Sincronizar dados do agente com o país
	_sync_agent_to_country()
	
	# Notificar transição
	game_phase_changed.emit(old_phase, current_phase)
	
	if notification_system:
		notification_system.show_notification(
			"🏛️ PRESIDENTE ELEITO!",
			"%s conquistou a presidência de %s!" % [player_agent.agent_name, player_agent.country],
			NotificationSystem.NotificationType.SUCCESS,
			5.0
		)
	
	print("🏛️ Transição para Fase 2: PRESIDENTE!")

func _sync_agent_to_country() -> void:
	if not player_agent or not Globals.has_method("adjust_country_value"):
		return
		
	# Transferir influência do agente para dados nacionais
	var stability_modifier = int((player_agent.total_support - 175.0) / 5.0)
	var money_bonus = player_agent.wealth * 1000
	var gov_power_modifier = 50 + int(player_agent.military_support / 2.0)
	
	Globals.adjust_country_value(player_agent.country, "stability", stability_modifier)
	Globals.adjust_country_value(player_agent.country, "money", money_bonus)
	Globals.adjust_country_value(player_agent.country, "gov_power", gov_power_modifier)

# =====================================
#  CALLBACKS DOS AGENTES
# =====================================
func _on_agent_position_advanced(old_position: String, new_position: String) -> void:
	if not notification_system: 
		return
		
	notification_system.show_notification(
		"🎖️ Avanço Político!",
		"%s avançou de %s para %s!" % [player_agent.agent_name, old_position, new_position],
		NotificationSystem.NotificationType.SUCCESS
	)
	agent_status_changed.emit()

func _on_agent_support_changed(group: String, old_value: int, new_value: int) -> void:
	if not notification_system: 
		return
		
	if abs(new_value - old_value) >= 5: # Só notificar mudanças significativas
		var change_text = "aumentou" if new_value > old_value else "diminuiu"
		notification_system.show_notification(
			"📊 Mudança de Apoio",
			"Apoio de %s %s de %d para %d" % [group, change_text, old_value, new_value],
			NotificationSystem.NotificationType.INFO
		)

# =====================================
#  CONTROLES DO JOGO
# =====================================
func _on_pause_pressed() -> void:
	time_running = not time_running
	
	if pause_button:
		pause_button.text = "⏸ Pausar" if time_running else "▶️ Retomar"
	
	if time_running:
		timer.start()
		if notification_system: 
			notification_system.show_notification("⏰ Tempo", "Jogo retomado.", NotificationSystem.NotificationType.INFO)
	else:
		timer.stop()
		if notification_system: 
			notification_system.show_notification("⏸️ Pausa", "Jogo pausado.", NotificationSystem.NotificationType.WARNING)
	
	print("🎮 Jogo %s" % ("retomado" if time_running else "pausado"))

func _on_next_month_pressed() -> void:
	if not time_running:
		advance_month()

# =====================================
#  SISTEMA DE UI
# =====================================
func _update_all_ui() -> void:
	_update_date_display()
	_update_resource_display()
	_update_stability_display()
	
	if ui_manager:
		ui_manager.update_phase_specific_ui(current_phase, player_agent)

func _update_date_display() -> void:
	if date_label:
		date_label.text = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
		date_label.modulate = Color.WHITE

func _update_resource_display() -> void:
	if not money_label:
		return
		
	var money_value: int
	var money_text: String
	
	match current_phase:
		GamePhase.POLITICAL_AGENT:
			money_value = (player_agent.wealth * 100) if player_agent else 0
			money_text = "💰 Recursos: %d" % money_value
		GamePhase.NATIONAL_LEADER:
			var player_data = Globals.get_player_data()
			money_value = player_data.get("money", 0)
			money_text = "$ %s" % _format_number(money_value)
	
	money_label.text = money_text
	money_label.modulate = Color.GREEN

func _update_stability_display() -> void:
	if not stability_label:
		return
		
	var stability_value: int
	var stability_text: String
	
	match current_phase:
		GamePhase.POLITICAL_AGENT:
			stability_value = player_agent.total_support if player_agent else 0
			var position_name = player_agent.get_position_name() if player_agent else "N/A"
			stability_text = "📊 Apoio: %d%% (%s)" % [stability_value, position_name]
		GamePhase.NATIONAL_LEADER:
			var player_data = Globals.get_player_data()
			stability_value = player_data.get("stability", 50)
			stability_text = "⚖️ Estabilidade: %d%%" % stability_value
	
	stability_label.text = stability_text
	
	# Cor baseada no valor
	if stability_value > 70:
		stability_label.modulate = Color.GREEN
	elif stability_value > 40:
		stability_label.modulate = Color.YELLOW
	else:
		stability_label.modulate = Color.RED

# =====================================
#  SISTEMA DE INFORMAÇÕES
# =====================================
func show_country_info(country_name: String) -> void:
	if not info_container:
		push_warning("InfoContainer não disponível")
		return
		
	# Limpar container
	for child in info_container.get_children():
		child.queue_free()
	
	# Obter dados do país
	var country_data = Globals.get_country(country_name)
	if country_data.is_empty():
		_show_no_country_data(country_name)
		return
	
	# Construir interface de informações
	_build_country_info_UI(country_name, country_data)
	
	if notification_system:
		notification_system.show_notification(
			"🏛️ " + country_name, 
			"Visualizando informações", 
			NotificationSystem.NotificationType.INFO
		)

func _show_no_country_data(country_name: String) -> void:
	var label = Label.new()
	label.text = "❌ Dados não disponíveis para %s" % country_name
	label.modulate = Color.RED
	info_container.add_child(label)
	
	if notification_system:
		notification_system.show_notification(
			"⚠️ Erro", 
			"Dados do país %s não carregados." % country_name, 
			NotificationSystem.NotificationType.ERROR
		)

func _build_country_info_UI(country_name: String, country_data: Dictionary) -> void:
	# Título
	var title = Label.new()
	title.text = "🏛️ %s" % country_name.to_upper()
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color.GOLD
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(title)
	
	# Indicador especial para país do jogador
	if country_name == Globals.player_country:
		var indicator = Label.new()
		match current_phase:
			GamePhase.POLITICAL_AGENT:
				indicator.text = "👤 %s (%s)" % [
					player_agent.agent_name if player_agent else "N/A", 
					player_agent.position_name if player_agent else "N/A"
				]
			GamePhase.NATIONAL_LEADER:
				indicator.text = "👑 SEU PAÍS"
		indicator.modulate = Color.CYAN
		indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_container.add_child(indicator)
	
	# Dados principais
	var data_items = [
		"💰 Dinheiro: $%s" % _format_number(country_data.get("money", 0)),
		"⚖️ Estabilidade: %d%%" % country_data.get("stability", 50),
		"🏛️ Poder Gov.: %d%%" % country_data.get("gov_power", 50),
		"🔥 Rebelião: %d%%" % country_data.get("rebel_power", 50),
		"👥 População: %s" % _format_number(country_data.get("population", 0)),
		"🏭 Indústria: %d%%" % country_data.get("industry", 0),
		"🛡️ Defesa: %d%%" % country_data.get("defense", 0)
	]
	
	for item in data_items:
		var label = Label.new()
		label.text = item
		label.add_theme_font_size_override("font_size", 12)
		info_container.add_child(label)
	
	# Informações específicas do agente (Fase 1)
	if current_phase == GamePhase.POLITICAL_AGENT and country_name == Globals.player_country:
		_add_agent_info_to_panel()
	
	# Botões de ação
	_add_action_buttons(country_name)

func _add_agent_info_to_panel() -> void:
	if not player_agent:
		return
		
	# Separador
	var separator = HSeparator.new()
	info_container.add_child(separator)
	
	# Título da seção
	var agent_title = Label.new()
	agent_title.text = "📋 DADOS DO AGENTE"
	agent_title.add_theme_font_size_override("font_size", 14)
	agent_title.modulate = Color.YELLOW
	info_container.add_child(agent_title)
	
	# Dados do agente
	var agent_data = [
		"💬 Carisma: %d" % player_agent.charisma,
		"🧠 Inteligência: %d" % player_agent.intelligence,
		"🤝 Contatos: %d" % player_agent.connections,
		"💰 Riqueza: %d" % player_agent.wealth,
		"⚔️ Conhec. Militar: %d" % player_agent.military_knowledge,
		"📊 Apoio Total: %d/700" % player_agent.total_support,
		"🎯 Experiência: %d" % player_agent.political_experience
	]
	
	for item in agent_data:
		var label = Label.new()
		label.text = item
		label.add_theme_font_size_override("font_size", 11)
		info_container.add_child(label)

func _add_action_buttons(country_name: String) -> void:
	var button = Button.new()
	button.custom_minimum_size = Vector2(180, 35)
	
	if country_name == Globals.player_country:
		match current_phase:
			GamePhase.POLITICAL_AGENT:
				button.text = "🎯 Ações Políticas"
				if player_agent:
					button.pressed.connect(_on_political_action_button_pressed)
			GamePhase.NATIONAL_LEADER:
				button.text = "👑 Governar"
				button.pressed.connect(_govern_country.bind(country_name))
	else:
		button.text = "🤝 Negociar"
		button.pressed.connect(_negotiate_with_country.bind(country_name))
	
	info_container.add_child(button)

# =====================================
#  AÇÕES POLÍTICAS
# =====================================
func _on_political_action_button_pressed() -> void:
	print("🎮 Botão de ação política pressionado!")
	
	if current_phase != GamePhase.POLITICAL_AGENT:
		if notification_system:
			notification_system.show_notification(
				"🚫 Erro de Fase",
				"Ações políticas apenas disponíveis na fase de agente político.",
				NotificationSystem.NotificationType.WARNING
			)
		return
		
	if not player_agent:
		if notification_system:
			notification_system.show_notification(
				"🚫 Erro de Sistema",
				"Agente político não inicializado corretamente.",
				NotificationSystem.NotificationType.ERROR
			)
		return
	
	_show_political_actions()

func _show_political_actions() -> void:
	var agent_actions = []
	if player_agent:
		agent_actions = player_agent.get_available_actions()
	
	if agent_actions.is_empty():
		if notification_system:
			notification_system.show_notification(
				"🚫 Sem Ações",
				"Nenhuma ação política disponível no momento",
				NotificationSystem.NotificationType.WARNING
			)
		return
	
	# Executar primeira ação disponível (simplificado)
	var action = agent_actions[0]
	_execute_political_action_directly(action)

# A função _execute_political_action_directly vem logo depois
func _execute_political_action_directly(action: Dictionary) -> void:
	# ...
	if not player_agent:
		return
	
	var result = player_agent.execute_action(action)
	
	var success = result.get("success", false)
	var message = result.get("message", "")
	
	var notification_type = NotificationSystem.NotificationType.SUCCESS if success else NotificationSystem.NotificationType.ERROR
	
	var display_message = message
	var events = result.get("events", [])
	if not events.is_empty():
		display_message += "\n\nResultados:"
		for event in events:
			display_message += "\n• %s" % event
	
	if notification_system:
		notification_system.show_notification(
			"🎯 %s" % action.get("name", "Ação Política"),
			display_message,
			notification_type
		)
	
	_update_all_ui()

# =====================================
#  AÇÕES NACIONAIS
# =====================================
func _govern_country(country_name: String) -> void:
	if not Globals.has_method("adjust_country_value"):
		return
		
	var gov_bonus = randi_range(3, 8)
	var cost = -500
	
	Globals.adjust_country_value(country_name, "gov_power", gov_bonus)
	Globals.adjust_country_value(country_name, "money", cost)
	
	if notification_system:
		notification_system.show_notification(
			"👑 Ação Governamental",
			"Poder governamental aumentou em %d pontos" % gov_bonus,
			NotificationSystem.NotificationType.SUCCESS
		)
	
	_update_all_ui()
	show_country_info(country_name)

func _negotiate_with_country(country_name: String) -> void:
	if not Globals.has_method("adjust_country_value"):
		return
		
	var trade_bonus = randi_range(200, 800)
	var relation_bonus = randi_range(2, 8)
	
	Globals.adjust_country_value(Globals.player_country, "money", trade_bonus)
	
	if Globals.has_method("adjust_relation"):
		Globals.adjust_relation(Globals.player_country, country_name, relation_bonus)
	
	if notification_system:
		notification_system.show_notification(
			"🤝 Negociação",
			"Acordo comercial rendeu $%s" % _format_number(trade_bonus),
			NotificationSystem.NotificationType.SUCCESS
		)
	
	_update_all_ui()

# =====================================
#  SISTEMA DE AUTO-SAVE
# =====================================
func _on_auto_save() -> void:
	if not auto_save_enabled:
		return
		
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": {
			"current_phase": current_phase,
			"current_month": Globals.current_month,
			"current_year": Globals.current_year,
			"player_country": Globals.player_country,
			"time_running": time_running
		},
		"player_agent": _serialize_player_agent() if player_agent else null,
		"country_data": Globals.country_data
	}
	
	# Salvar em arquivo
	var save_file = FileAccess.open("user://autosave.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		save_file.close()
		
		if DEBUG_MODE:
			print("💾 Auto-save realizado")

func _serialize_player_agent() -> Dictionary:
	if not player_agent:
		return {}
		
	return {
		"agent_name": player_agent.agent_name,
		"country": player_agent.country,
		# CORREÇÃO: Salvamos o 'position_level' (o número), que é o dado principal.
		"position_level": player_agent.position_level,
		"attributes": {
			"charisma": player_agent.charisma,
			"intelligence": player_agent.intelligence,
			"connections": player_agent.connections,
			"wealth": player_agent.wealth,
			"military_knowledge": player_agent.military_knowledge
		},
		# CORREÇÃO: Usamos o dicionário 'personal_support' diretamente.
		"support": player_agent.personal_support,
		"stats": {
			"political_experience": player_agent.political_experience,
			"condor_threat_level": player_agent.condor_threat_level
			# O 'total_support' não precisa ser salvo, pois ele é sempre calculado.
		}
	}
	if not player_agent:
		return {}
		
	return {
		"agent_name": player_agent.agent_name,
		"country": player_agent.country,
		"current_position": player_agent.current_position,
		"attributes": {
			"charisma": player_agent.charisma,
			"intelligence": player_agent.intelligence,
			"connections": player_agent.connections,
			"wealth": player_agent.wealth,
			"military_knowledge": player_agent.military_knowledge
		},
		"support": {
			"military": player_agent.military_support,
			"business": player_agent.business_support,
			"intellectual": player_agent.intellectual_support,
			"worker": player_agent.worker_support,
			"student": player_agent.student_support,
			"church": player_agent.church_support,
			"peasant": player_agent.peasant_support
		},
		"stats": {
			"political_experience": player_agent.political_experience,
			"condor_threat_level": player_agent.condor_threat_level,
			"total_support": player_agent.total_support
		}
	}

# =====================================
#  SISTEMA DE INPUT
# =====================================

func _input(event: InputEvent) -> void:
	# Ação de pausa pelo teclado
	if event.is_action_pressed("ui_accept"):
		# Marcamos o evento como "manuseado" para que outras funções
		# como _unhandled_input não o processem novamente.
		get_viewport().set_input_as_handled()
		_on_pause_pressed()
func _unhandled_input(event: InputEvent) -> void:
	# Atalhos de teclado
	if event.is_action_pressed("ui_right"): # Seta direita
		if not time_running:
			_on_next_month_pressed()
	elif event.is_action_pressed("ui_cancel"): # ESC
		_toggle_game_menu()

	# Atalhos de debug (apenas em modo debug)
	if DEBUG_MODE:
		if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_F1:
					_debug_show_game_state()
				KEY_F2:
					_debug_advance_phase()
				KEY_F3:
					_debug_add_resources()
				KEY_F5:
					_on_auto_save()

func _toggle_game_menu() -> void:
	# Implementar menu de pausa/opções
	print("🎮 Menu toggle (não implementado)")

# =====================================
#  FUNÇÕES DE DEBUG
# =====================================
func _debug_show_game_state() -> void:
	print("\n=== DEBUG: ESTADO DO JOGO ===")
	print("Fase: %s" % GamePhase.keys()[current_phase])
	print("Data: %s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year])
	print("País: %s" % Globals.player_country)
	
	if player_agent:
		print("Nome: %s" % player_agent.agent_name)
		print("Posição: %s" % player_agent.get_position_name())
		print("Apoio Total: %d/700" % player_agent.total_support)
		print("Ameaça Condor: %d%%" % player_agent.condor_threat_level)

	
	print("\n--- PAÍS ---")
	var country_data = Globals.get_player_data()
	for key in country_data:
		print("%s: %s" % [key, country_data[key]])
	print("=============================\n")

func _debug_advance_phase() -> void:
	if current_phase == GamePhase.POLITICAL_AGENT and player_agent:
		player_agent.set_position_level(5) # Define o nível do jogador como 5 (Presidente)
		_transition_to_leader_phase()
		print("🔧 DEBUG: Avançado para Fase 2")

func _debug_add_resources() -> void:
	match current_phase:
		GamePhase.POLITICAL_AGENT:
			if player_agent:
				player_agent.wealth = min(100, player_agent.wealth + 20)
				player_agent.political_experience += 50
				print("🔧 DEBUG: +20 riqueza, +50 experiência")
		GamePhase.NATIONAL_LEADER:
			Globals.adjust_country_value(Globals.player_country, "money", 10000)
			Globals.adjust_country_value(Globals.player_country, "stability", 10)
			print("🔧 DEBUG: +$10k, +10 estabilidade")
	_update_all_ui()

# =====================================
#  FUNÇÕES UTILITÁRIAS
# =====================================
func _format_number(num: int) -> String:
	"""Formata números grandes de forma legível"""
	if num >= 1_000_000_000:
		return "%.1fB" % (num / 1_000_000_000.0)
	elif num >= 1_000_000:
		return "%.1fM" % (num / 1_000_000.0)
	elif num >= 1_000:
		return "%.1fK" % (num / 1_000.0)
	else:
		return str(num)

func _get_phase_name() -> String:
	"""Retorna o nome legível da fase atual"""
	match current_phase:
		GamePhase.POLITICAL_AGENT:
			return "Agente Político"
		GamePhase.NATIONAL_LEADER:
			return "Líder Nacional"
		_:
			return "Desconhecida"

func _validate_game_state() -> bool:
	"""Valida o estado atual do jogo"""
	var is_valid = true
	
	# Verificar componentes essenciais
	if not notification_system:
		push_error("Sistema de notificações não inicializado!")
		is_valid = false
	
	if not ui_manager:
		push_error("UI Manager não inicializado!")
		is_valid = false
	
	if current_phase == GamePhase.POLITICAL_AGENT and not player_agent:
		push_error("PlayerAgent não inicializado na fase de agente!")
		is_valid = false
	
	# Verificar dados globais
	if not Globals.country_data.has(Globals.player_country):
		push_error("Dados do país do jogador não encontrados!")
		is_valid = false
	
	return is_valid

# =====================================
#  GETTERS PÚBLICOS
# =====================================
func get_current_date() -> String:
	return "%s/%d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]

func get_current_money() -> int:
	match current_phase:
		GamePhase.POLITICAL_AGENT:
			# CORREÇÃO: Usando um bloco if/else padrão
			if player_agent:
				return player_agent.wealth * 100
			else:
				return 0
		GamePhase.NATIONAL_LEADER:
			return Globals.get_country_value(Globals.player_country, "money", 0)
	return 0
func get_current_stability() -> int:
	match current_phase:
		GamePhase.POLITICAL_AGENT:
			# CORREÇÃO: Usando um bloco if/else padrão
			if player_agent:
				return player_agent.total_support
			else:
				return 0
		GamePhase.NATIONAL_LEADER:
			return Globals.get_country_value(Globals.player_country, "stability", 50)
	return 50

func is_time_running() -> bool:
	return time_running

func get_current_phase() -> GamePhase:
	return current_phase

func get_player_agent() -> PlayerAgent:
	return player_agent

# =====================================
#  CLEANUP
# =====================================
func _exit_tree() -> void:
	# Salvar antes de sair
	if auto_save_enabled:
		_on_auto_save()
	
	# Limpar referencias
	if timer:
		timer.stop()
	if auto_save_timer:
		auto_save_timer.stop()
	
	print("🎮 Sistema principal finalizado")
# =====================================
#  CALLBACKS DO MENU DE PAUSA
# =====================================

# Esta função é chamada quando o botão "Retomar" do menu é pressionado.
func _on_resume_game() -> void:
	_toggle_game_menu() # Apenas chama a função de alternar o menu novamente para fechar e despausar.

# Esta função é chamada quando o botão "Sair" é pressionado.
func _on_quit_to_main_menu() -> void:
	# Importante: Sempre despause o jogo antes de trocar de cena para evitar bugs.
	get_tree().paused = false
	
	# Mude o caminho abaixo se sua cena de menu principal tiver outro nome/caminho.
	# Se você ainda não tem um menu principal, esta linha dará erro, o que é normal.
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
