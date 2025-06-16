# =====================================
#  MAIN.GD - VERSÃO ROBUSTA SÊNIOR
#  Arquitetura limpa com sistema de notificações e UI Manager integrados
# =====================================
extends Node

# Carregar os scripts dos componentes
# NOTA: Removido 'const UIManager = preload("res://scripts/UIManager.gd")'
# porque Godot já o registra como classe global (SHADOWED_GLOBAL_IDENTIFIER)
# REMOVIDO: const PlayerAgent = preload("res://scripts/PlayerAgent.gd") # Não é mais necessário devido a class_name

const NotificationSystem = preload("res://scripts/NotificationSystem.gd") # Certifique-se que este preload existe!

# =====================================
#  CONSTANTES E CONFIGURAÇÕES
# =====================================
const MONTH_NAMES: Array[String] = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]
const AUTO_SAVE_INTERVAL: float = 30.0
const DEBUG_MODE: bool = true

# =====================================
#  ENUMS
# =====================================
enum GamePhase {
	POLITICAL_AGENT = 1,
	NATIONAL_LEADER = 2
}

# NotificationType foi movido para NotificationSystem.gd, mas mantido aqui se precisar como fallback
# enum NotificationType {
# 	INFO,
# 	WARNING,
# 	SUCCESS,
# 	ERROR
# }

# =====================================
#  SINAIS
# =====================================
signal game_phase_changed(old_phase: GamePhase, new_phase: GamePhase)
signal month_advanced(month: int, year: int)
signal agent_status_changed()

# =====================================
#  ESTADO DO JOGO
# =====================================
@export var time_running: bool = true
@export var current_phase: GamePhase = GamePhase.POLITICAL_AGENT
@export var auto_save_enabled: bool = true

# =====================================
#  COMPONENTES PRINCIPAIS
# =====================================
var player_agent: PlayerAgent
var notification_system: NotificationSystem
var ui_manager: UIManager
var timer: Timer

# =====================================
#  REFERÊNCIAS DA UI
# =====================================
var date_label: Label
var money_label: Label
var stability_label: Label
var pause_button: Button
var next_button: Button
var info_container: VBoxContainer

# =====================================
#  INICIALIZAÇÃO
# =====================================
func _ready() -> void:
	# Inicializar o agente político
	Globals.init_player_agent()
	_initialize_systems()
	_setup_ui_references()
	_setup_timer()
	_setup_input_handling()
	_create_default_agent()
	_start_game_loop()

func _initialize_systems() -> void:
	notification_system = NotificationSystem.new()
	add_child(notification_system)
	
	# UIManager agora é acessado diretamente pelo nome da classe global
	ui_manager = UIManager.new()
	ui_manager.setup(self)
	add_child(ui_manager)
	
	print("🎮 Sistemas inicializados")

func _setup_ui_references() -> void:
	# Busca os elementos da UI de forma robusta
	var ui_paths = [
		["CanvasLayer/TopBar/HBoxContainer/DateLabel", "TopBar/HBoxContainer/DateLabel"], # Ordem pode importar, mais específico primeiro
		["CanvasLayer/TopBar/HBoxContainer/MoneyLabel", "TopBar/HBoxContainer/MoneyLabel"],
		["CanvasLayer/TopBar/HBoxContainer/StabilityLabel", "TopBar/HBoxContainer/StabilityLabel"],
		["CanvasLayer/BottomBar/HBoxContainer/PauseButton", "BottomBar/HBoxContainer/PauseButton"],
		["CanvasLayer/BottomBar/HBoxContainer/NextButton", "BottomBar/HBoxContainer/NextButton"],
		["CanvasLayer/Sidepanel/InfoContainer", "Sidepanel/InfoContainer"]
	]
	
	var references = [
		"date_label", "money_label", "stability_label",
		"pause_button", "next_button", "info_container"
	]
	
	for i in range(ui_paths.size()):
		var found_node = null
		# Tentar encontrar o nó pelos caminhos alternativos
		for path in ui_paths[i]:
			found_node = get_node_or_null(path)
			if found_node:
				break
		
		set(references[i], found_node)
		print("UI %s: %s" % [references[i], "✅ Encontrado" if found_node else "❌ Não encontrado"])

func _setup_timer() -> void:
	timer = Timer.new()
	timer.name = "GameTimer"
	timer.wait_time = 3.0
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
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
	print("DEBUG: Criando PlayerAgent padrão...")
	# PlayerAgent agora é reconhecido globalmente devido a class_name
	player_agent = PlayerAgent.create_preset("intelectual_democrata", "Argentina")
	
	if player_agent == null:
		print("CRITICAL ERROR: PlayerAgent.create_preset retornou null! O PlayerAgent.gd pode ter um erro grave ou não foi carregado.")
		return
	if not player_agent is PlayerAgent:
		print("CRITICAL ERROR: player_agent NÃO É uma instância de PlayerAgent! Tipo atual: %s" % player_agent.get_class())
		return
		
	player_agent.agent_name = "Carlos Rodriguez" # Garante que o nome está definido
	
	# Conectar sinais do agente
	# Adicionado verificação para evitar erro se signals já estiverem conectados
	if not player_agent.position_advanced.is_connected(_on_agent_position_advanced):
		player_agent.position_advanced.connect(_on_agent_position_advanced)
	if not player_agent.support_changed.is_connected(_on_agent_support_changed):
		player_agent.support_changed.connect(_on_agent_support_changed)
	
	# Configurar país no sistema global
	Globals.player_country = player_agent.country
	_ensure_country_data_exists()
	
	print("👤 Agente criado: %s (%s)" % [player_agent.agent_name, player_agent.position_name])
	print("DEBUG: Atributos do PlayerAgent na criação:")
	print("  Carisma:", player_agent.charisma)
	print("  Inteligência:", player_agent.intelligence)
	print("  Conexões:", player_agent.connections)
	print("  Apoio Militar:", player_agent.military_support)
	print("  Apoio Empresarial:", player_agent.business_support)
	print("  Apoio Intelectual:", player_agent.intellectual_support)
	print("  Apoio Trabalhadores:", player_agent.worker_support)
	print("  Apoio Estudantes:", player_agent.student_support)
	print("  Apoio Igreja:", player_agent.church_support)
	print("  Apoio Camponeses:", player_agent.peasant_support)


func _ensure_country_data_exists() -> void:
	# Garante que os dados do país do jogador existem em Globals
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
	# Adicionado verificação antes de chamar show_notification
	if notification_system:
		notification_system.show_notification("🎮 Jogo Iniciado", "Sistema carregado com sucesso!", NotificationSystem.NotificationType.SUCCESS)
	print("🎮 Jogo iniciado - Fase: %s" % GamePhase.keys()[current_phase])

# =====================================
#  LOOP PRINCIPAL DO JOGO
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
		# Adicionado verificação antes de chamar show_notification
		if notification_system:
			notification_system.show_notification("📅 Novo Ano", "Chegamos a %d!" % Globals.current_year, NotificationSystem.NotificationType.SUCCESS)
	
	# Processar sistemas baseado na fase
	match current_phase:
		GamePhase.POLITICAL_AGENT:
			_process_agent_phase()
		GamePhase.NATIONAL_LEADER:
			_process_leader_phase()
	
	# Emitir sinal e atualizar UI
	month_advanced.emit(Globals.current_month, Globals.current_year)
	_update_all_ui()
	
	# Debug
	if DEBUG_MODE:
		print("📅 %s %d - Fase %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year, current_phase])

func _process_agent_phase() -> void:
	if not player_agent: # Adicionado: Verificação para garantir que player_agent não é Nil
		print("WARNING: player_agent é Nil em _process_agent_phase. Não pode processar fase do agente.")
		return
		
	# Avançar agente
	player_agent.advance_month()
	
	# Verificar transição para fase 2
	if player_agent.current_position == PlayerAgent.Position.PRESIDENT:
		_transition_to_leader_phase()
	
	# Eventos aleatórios de agente
	_process_agent_events()

func _process_leader_phase() -> void:
	# Processar como líder nacional (sistema existente)
	if Globals.has_method("simulate_monthly_changes"):
		Globals.simulate_monthly_changes()
	
	# Eventos históricos e aleatórios
	_process_national_events()

func _process_agent_events() -> void:
	if not player_agent: # Adicionado: Outra verificação de segurança
		return
		
	# Simulação de atividade política automática
	if randf() < 0.3: # 30% chance
		_simulate_political_activity()
	
	# Eventos especiais baseados no contexto
	if player_agent.condor_threat_level > 60 and randf() < 0.1:
		_trigger_condor_event()
	
	if player_agent.military_support >= 70 and randf() < 0.05:
		_offer_military_opportunity()

func _simulate_political_activity() -> void:
	if not player_agent: # Adicionado: Verificação para evitar crash se player_agent for Nil
		print("ERROR: player_agent é Nil em _simulate_political_activity. Abortando atividade.")
		return
		
	# É CRUCIAL que player_agent.charisma, intelligence, connections não sejam Nil aqui
	var activity_chance = (player_agent.charisma + player_agent.intelligence + player_agent.connections) / 300.0
	
	if randf() < activity_chance:
		var support_groups = ["military", "business", "intellectual", "worker", "student", "church", "peasant"]
		var random_group = support_groups[randi() % support_groups.size()]
		var support_attr = random_group + "_support" # Ex: "military_support"
		var gain = randi_range(1, 3)
		
		print("DEBUG: _simulate_political_activity - Atributo alvo: %s" % support_attr)
		print("DEBUG: _simulate_political_activity - Ganho: %d" % gain)
		
		var old_value = player_agent.get(support_attr)
		
		# --- LINHA QUE CAUSA O ERRO ANTERIORMENTE (OU ONDE old_value é usado) ---
		# Adicionado: Verificação para o valor retornado por get()
		if old_value == null: # Se .get() retornou Nil, significa que a propriedade não existe ou não foi inicializada.
			print("CRITICAL ERROR: player_agent.get('%s') retornou Nil! A propriedade não existe ou não foi inicializada corretamente em PlayerAgent." % support_attr)
			# Podemos tentar atribuir um valor padrão para evitar o crash imediato,
			# mas a causa raiz ainda seria a inicialização do PlayerAgent.
			old_value = 0 # Define um fallback para evitar o crash
		# --- FIM DA VERIFICAÇÃO ---

		var new_value = clamp(old_value + gain, 0, 100) # Linha 244 do seu Main.gd anterior
		player_agent.set(support_attr, new_value)
		
		# Usando NotificationSystem.NotificationType do script NotificationSystem
		# Adicionado verificação antes de chamar show_notification
		if notification_system:
			notification_system.show_notification(
				"📈 Atividade Política",
				"%s ganhou %d apoio com %s" % [player_agent.agent_name, gain, random_group],
				NotificationSystem.NotificationType.SUCCESS
			)

func _process_national_events() -> void:
	# Eventos aleatórios nacionais
	if randf() < 0.15: # 15% chance
		_trigger_random_national_event()

func _trigger_random_national_event() -> void:
	var countries = Globals.country_data.keys()
	if countries.is_empty(): # Usar is_empty() para verificar se o array está vazio
		return
		
	var random_country = countries[randi() % countries.size()]
	if Globals.has_method("apply_random_event"):
		var event = Globals.apply_random_event(random_country)
		print("📰 EVENTO: %s em %s" % [event.get("name", "Evento"), random_country])

# =====================================
#  TRANSIÇÃO ENTRE FASES
# =====================================
func _transition_to_leader_phase() -> void:
	var old_phase = current_phase
	current_phase = GamePhase.NATIONAL_LEADER
	
	# Sincronizar dados do agente com o país
	_sync_agent_to_country()
	
	# Notificar transição
	game_phase_changed.emit(old_phase, current_phase)
	
	# Adicionado verificação antes de chamar show_notification
	if notification_system:
		notification_system.show_notification(
			"🏛️ PRESIDENTE ELEITO!",
			"%s conquistou a presidência de %s!" % [player_agent.agent_name, player_agent.country],
			NotificationSystem.NotificationType.SUCCESS, # Usando NotificationSystem.NotificationType
			5.0
		)
	
	print("🏛️ Transição para Fase 2: PRESIDENTE!")

func _sync_agent_to_country() -> void:
	if not player_agent or not Globals.has_method("adjust_country_value"): # Adicionado verificação
		print("ERROR: player_agent ou Globals.adjust_country_value não disponível para sincronização.")
		return
		
	# Transferir influência do agente para dados nacionais
	var stability_modifier = int((player_agent.total_support - 175.0) / 5.0)
	var money_bonus = player_agent.wealth * 1000
	var gov_power_modifier = 50 + int(player_agent.military_support / 2.0)
	
	Globals.adjust_country_value(player_agent.country, "stability", stability_modifier)
	Globals.adjust_country_value(player_agent.country, "money", money_bonus)
	Globals.adjust_country_value(player_agent.country, "gov_power", gov_power_modifier)

# =====================================
#  CALLBACKS DOS AGENTES
# =====================================
func _on_agent_position_advanced(old_position: String, new_position: String) -> void:
	if not notification_system: return
	notification_system.show_notification(
		"🎖️ Avanço Político!",
		"%s avançou de %s para %s!" % [player_agent.agent_name, old_position, new_position],
		NotificationSystem.NotificationType.SUCCESS
	)
	agent_status_changed.emit()

func _on_agent_support_changed(group: String, old_value: int, new_value: int) -> void:
	if not notification_system: return
	if abs(new_value - old_value) >= 5: # Só notificar mudanças significativas
		var change_text = "aumentou" if new_value > old_value else "diminuiu"
		notification_system.show_notification(
			"📊 Mudança de Apoio",
			"Apoio de %s %s de %d para %d" % [group, change_text, old_value, new_value],
			NotificationSystem.NotificationType.INFO
		)

# =====================================
#  CONTROLES DO JOGO
# =====================================
func _on_pause_pressed() -> void:
	time_running = not time_running
	
	if pause_button:
		pause_button.text = "⏸ Pausar" if time_running else "▶️ Retomar"
	
	if time_running:
		timer.start()
		if notification_system: notification_system.show_notification("⏰ Tempo", "Jogo retomado.", NotificationSystem.NotificationType.INFO) # Adicionando notificação
	else:
		timer.stop()
		if notification_system: notification_system.show_notification("⏸️ Pausa", "Jogo pausado.", NotificationSystem.NotificationType.WARNING) # Adicionando notificação
	
	print("🎮 Jogo %s" % ("retomado" if time_running else "pausado"))

func _on_next_month_pressed() -> void:
	if not time_running:
		advance_month()

# =====================================
#  SISTEMA DE UI
# =====================================
func _update_all_ui() -> void:
	_update_date_display()
	_update_resource_display()
	_update_stability_display()
	if ui_manager: # Adicionado verificação
		# Certifique-se que o UIManager tem um método update_phase_specific_ui
		# e que ele usa os parâmetros '_current_phase' e '_player_agent'
		# ou remova-os se não forem realmente necessários dentro dessa função.
		ui_manager.update_phase_specific_ui(current_phase, player_agent)
	else:
		print("WARNING: UI Manager não está disponível para atualizar a UI específica da fase.")

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
			# Adicionado verificação para player_agent.wealth
			money_value = (player_agent.wealth * 100) if player_agent else 0
			money_text = "💰 Recursos: %d" % money_value
		GamePhase.NATIONAL_LEADER:
			var player_data = Globals.get_player_data()
			money_value = player_data.get("money", 0)
			money_text = "$ %s" % _format_number(money_value) # Corrigido para _format_number
	
	money_label.text = money_text
	money_label.modulate = Color.GREEN

func _update_stability_display() -> void:
	if not stability_label:
		return
		
	var stability_value: int
	var stability_text: String
	
	match current_phase:
		GamePhase.POLITICAL_AGENT:
			# Adicionado verificação para player_agent.total_support
			stability_text = "📊 Apoio: %d%% (%s)" % [stability_value, str(player_agent.position_name) if player_agent else "N/A"] # Garante que ambos são Strings
			# Linha 453 (ou próxima): INCOMPATIBLE_TERNARY
			# Garante que ambos os lados do ternário retornem string compatível.
			# `player_agent.position_name` é uma String. Se `player_agent` for Nil, a alternativa deve ser String.
			stability_text = "📊 Apoio: %d%% (%s)" % [stability_value, player_agent.position_name if player_agent else "N/A"]
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
#  SISTEMA DE INFORMAÇÕES
# =====================================
func show_country_info(country_name: String) -> void:
	if not info_container:
		print("WARNING: InfoContainer não disponível para show_country_info.")
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
	
	if notification_system: # Adicionado verificação
		notification_system.show_notification("🏛️ " + country_name, "Visualizando informações", NotificationSystem.NotificationType.INFO)


func _show_no_country_data(country_name: String) -> void:
	var label = Label.new()
	label.text = "❌ Dados não disponíveis para %s" % country_name
	label.modulate = Color.RED
	info_container.add_child(label)
	if notification_system: # Adicionado verificação
		notification_system.show_notification("⚠️ Erro", "Dados do país %s não carregados." % country_name, NotificationSystem.NotificationType.ERROR)

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
				# Adicionado verificação para player_agent
				indicator.text = "👤 %s (%s)" % [player_agent.agent_name if player_agent else "N/A", player_agent.position_name if player_agent else "N/A"]
			GamePhase.NATIONAL_LEADER:
				indicator.text = "👑 SEU PAÍS"
		indicator.modulate = Color.CYAN
		indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_container.add_child(indicator)
	
	# Dados principais
	var data_items = [
		"💰 Dinheiro: $%s" % _format_number(country_data.get("money", 0)), # Corrigido para _format_number
		"⚖️ Estabilidade: %d%%" % country_data.get("stability", 50),
		"🏛️ Poder Gov.: %d%%" % country_data.get("gov_power", 50),
		"🔥 Rebelião: %d%%" % country_data.get("rebel_power", 50),
		"👥 População: %s" % _format_number(country_data.get("population", 0)), # Corrigido para _format_number
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
	if not player_agent: # Adicionado verificação
		print("WARNING: PlayerAgent é Nil ao tentar adicionar info do agente ao painel.")
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
				if player_agent: # Adicionado verificação
					button.pressed.connect(_show_political_actions)
			GamePhase.NATIONAL_LEADER:
				button.text = "👑 Governar"
				button.pressed.connect(_govern_country.bind(country_name))
	else:
		button.text = "🤝 Negociar"
		button.pressed.connect(_negotiate_with_country.bind(country_name))
	
	info_container.add_child(button)

# =====================================
#  AÇÕES POLÍTICAS
# =====================================
func _show_political_actions() -> void:
	if current_phase != GamePhase.POLITICAL_AGENT or not player_agent:
		if notification_system: # Adicionado verificação
			notification_system.show_notification(
				"🚫 Erro de Fase",
				"Ações políticas apenas na fase de agente ou player_agent não disponível.",
				NotificationSystem.NotificationType.WARNING
			)
		return
		
	var actions = player_agent.get_available_actions()
	if actions.is_empty():
		if notification_system: # Adicionado verificação
			notification_system.show_notification(
				"🚫 Sem Ações",
				"Nenhuma ação política disponível no momento",
				NotificationSystem.NotificationType.WARNING
			)
		return
	
	# Mostrar menu de ações (simplificado - primeira ação disponível)
	var action = actions[0]
	_confirm_political_action(action)

func _confirm_political_action(action: Dictionary) -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "🎯 Ação Política"
	
	var description = "Executar: %s\n\n" % action["name"]
	description += "Descrição: %s\n" % action.get("description", "Ação política")
	description += "Risco: %d%%\n" % action.get("risk", 0)
	
	if action.has("costs") and not action["costs"].is_empty():
		description += "Custos: "
		for cost_type in action["costs"]:
			description += "%s: %d " % [cost_type, action["costs"][cost_type]]
		description += "\n"
	
	dialog.dialog_text = description
	dialog.get_ok_button().text = "Executar"
	add_child(dialog) # Adicionado antes do popup para garantir que esteja na árvore
	dialog.popup_centered()
	
	# Linha 648 (e 650): Confirmado.connect e canceled.connect
	# Re-digitar essas linhas se o erro persistir aqui.
	dialog.confirmed.connect(func():
		_execute_political_action(action)
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())

func _execute_political_action(action: Dictionary) -> void:
	if not player_agent: return # Adicionado verificação
	
	var result = player_agent.execute_action(action)
	
	# Usando NotificationSystem.NotificationType
	var notification_type = NotificationSystem.NotificationType.SUCCESS if result["success"] else NotificationSystem.NotificationType.ERROR
	var message = result["message"]
	
	if result.has("events") and not result["events"].is_empty():
		message += "\n\nEventos:\n"
		for event in result["events"]:
			message += "• %s\n" % event
	
	if notification_system: # Adicionado verificação
		notification_system.show_notification(
			"🎯 " + action["name"],
			message,
			notification_type
		)
	
	_update_all_ui()

# =====================================
#  AÇÕES NACIONAIS
# =====================================
func _govern_country(country_name: String) -> void:
	if not Globals.has_method("adjust_country_value"):
		print("WARNING: Globals.adjust_country_value não encontrado.")
		return
		
	var gov_bonus = randi_range(3, 8)
	var cost = -500
	
	Globals.adjust_country_value(country_name, "gov_power", gov_bonus)
	Globals.adjust_country_value(country_name, "money", cost)
	
	if notification_system: # Adicionado verificação
		notification_system.show_notification(
			"👑 Ação Governamental",
			"Poder governamental aumentou em %d pontos" % gov_bonus,
			NotificationSystem.NotificationType.SUCCESS
		)
	
	_update_all_ui()
	show_country_info(country_name)

func _negotiate_with_country(country_name: String) -> void:
	if not Globals.has_method("adjust_country_value"):
		print("WARNING: Globals.adjust_country_value não encontrado para negociação.")
		return
		
	var trade_bonus = randi_range(200, 800)
	var relation_bonus = randi_range(2, 8)
	
	Globals.adjust_country_value(Globals.player_country, "money", trade_bonus)
	
	if Globals.has_method("adjust_relation"):
		Globals.adjust_relation(Globals.player_country, country_name, relation_bonus)
	else:
		print("WARNING: Globals.adjust_relation não encontrado para negociação.")
	
	if notification_system: # Adicionado verificação
		notification_system.show_notification(
			"🤝 Negociação",
			"Acordo comercial rendeu $%s" % _format_number(trade_bonus), # Corrigido para _format_number
			NotificationSystem.NotificationType.SUCCESS
		)
	
	_update_all_ui()

# =====================================
#  EVENTOS ESPECIAIS
# =====================================
func _trigger_condor_event() -> void:
	if not notification_system: return
	if not player_agent: # Adicionado verificação
		print("WARNING: PlayerAgent é Nil ao tentar trigger_condor_event.")
		return
	
	notification_system.show_notification(
		"⚠️ Operação Condor",
		"%s está sendo monitorado pelas forças de segurança!" % player_agent.agent_name,
		NotificationSystem.NotificationType.WARNING,
		4.0
	)

func _offer_military_opportunity() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "🎖️ Oportunidade Militar"
	dialog.dialog_text = "Contatos militares oferecem apoio para acelerar sua ascensão política. Aceitar?"
	dialog.get_ok_button().text = "Aceitar"
	dialog.get_cancel_button().text = "Recusar"
	
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(func():
		_accept_military_support()
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		_refuse_military_support()
		dialog.queue_free()
	)

func _accept_military_support() -> void:
	if not player_agent: return # Adicionado verificação
	
	player_agent.military_support = clamp(player_agent.military_support + 15, 0, 100)
	player_agent.usa_influence = clamp(player_agent.usa_influence + 10, 0, 100)
	player_agent.worker_support = clamp(player_agent.worker_support - 10, 0, 100)
	player_agent.student_support = clamp(player_agent.student_support - 8, 0, 100)
	
	if notification_system: # Adicionado verificação
		notification_system.show_notification(
			"🎖️ Apoio Militar",
			"Acordou colaboração com as forças armadas",
			NotificationSystem.NotificationType.INFO
		)

func _refuse_military_support() -> void:
	if not player_agent: return # Adicionado verificação
	
	player_agent.intellectual_support = clamp(player_agent.intellectual_support + 5, 0, 100)
	player_agent.worker_support = clamp(player_agent.worker_support + 8, 0, 100)
	
	if notification_system: # Adicionado verificação
		notification_system.show_notification(
			"🎖️ Recusa Militar",
			"Recusou colaboração militar - manteve princípios",
			NotificationSystem.NotificationType.INFO
		)

# =====================================
#  INPUT E CONTROLES
# =====================================
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
		
	match event.keycode:
		KEY_SPACE:
			_on_pause_pressed()
		KEY_RIGHT:
			_on_next_month_pressed()
		KEY_F1:
			if DEBUG_MODE:
				_debug_advance_to_president()
		KEY_F2:
			if DEBUG_MODE:
				_debug_show_agent_info()
		KEY_F3:
			if DEBUG_MODE:
				_debug_boost_support()
		KEY_F4:
			if DEBUG_MODE:
				_show_political_actions()
		KEY_F5:
			if DEBUG_MODE:
				_debug_create_new_agent()

# =====================================
#  SISTEMA DE CLIQUES NO MAPA
# =====================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var country_name = _detect_country_click(event.global_position)
		if not country_name.is_empty():
			show_country_info(country_name)

func _detect_country_click(global_pos: Vector2) -> String:
	print("--- Debug de Clique no Mapa ---")
	print("Posição global do clique: ", global_pos)
	var map = get_node_or_null("NodeMapaSVG2D")
	if not map:
		print("❌ Erro: Nó 'NodeMapaSVG2D' não encontrado na cena.")
		return ""
	print("✅ Sucesso: Nó 'NodeMapaSVG2D' encontrado.")
	
	for child in map.get_children():
		if child is Polygon2D:
			var local_pos = child.to_local(global_pos)
			if Geometry2D.is_point_in_polygon(local_pos, child.polygon):
				print("✨ Clique detectado no Polygon2D: ", child.name)
				return child.name
		# else:
		# 	print("Filho do mapa não é Polygon2D: ", child.name, " (Tipo: ", child.get_class(), ")")
	
	print("🚫 Nenhum Polygon2D (país) foi clicado na posição.")
	return ""

# =====================================
#  FUNÇÕES DE DEBUG
# =====================================
func _debug_advance_to_president() -> void:
	if not player_agent:
		print("WARNING: player_agent é Nil ao tentar _debug_advance_to_president.")
		return
		
	player_agent.current_position = PlayerAgent.Position.PRESIDENT
	_transition_to_leader_phase()
	print("🔧 DEBUG: Avançado para presidente")

func _debug_show_agent_info() -> void:
	if not player_agent:
		print("WARNING: player_agent é Nil ao tentar _debug_show_agent_info.")
		return
		
	print(player_agent.get_status_summary())

func _debug_boost_support() -> void:
	if not player_agent or current_phase != GamePhase.POLITICAL_AGENT:
		print("WARNING: player_agent é Nil ou fase incorreta ao tentar _debug_boost_support.")
		return
		
	var boost = 10
	player_agent.military_support = clamp(player_agent.military_support + boost, 0, 100)
	player_agent.business_support = clamp(player_agent.business_support + boost, 0, 100)
	player_agent.intellectual_support = clamp(player_agent.intellectual_support + boost, 0, 100)
	player_agent.worker_support = clamp(player_agent.worker_support + boost, 0, 100)
	player_agent.student_support = clamp(player_agent.student_support + boost, 0, 100)
	player_agent.church_support = clamp(player_agent.church_support + boost, 0, 100)
	player_agent.peasant_support = clamp(player_agent.peasant_support + boost, 0, 100)
	
	if notification_system: # Adicionado verificação
		notification_system.show_notification(
			"🔧 DEBUG",
			"Apoio aumentado em +%d para todos os grupos" % boost,
			NotificationSystem.NotificationType.INFO
		)
	
	print("🔧 DEBUG: Apoio aumentado - Total: %d/700" % player_agent.total_support)

func _debug_create_new_agent() -> void:
	_create_default_agent()
	current_phase = GamePhase.POLITICAL_AGENT
	_update_all_ui()
	print("🔧 DEBUG: Novo agente criado e fase resetada para Agente Político.")

# =====================================
#  UTILITÁRIOS
# =====================================
func _format_number(num: int) -> String:
	if num >= 1_000_000: return "%.1fM" % (float(num) / 1_000_000.0)
	elif num >= 1_000: return "%.1fK" % (float(num) / 1_000.0)
	else: return str(num)

# Função auxiliar para Globals.get_country - deve estar em Globals.gd
# Esta função pode ser removida se Globals.gd já tiver 'get_country'
# ou se você a usou para simulação temporária.
func _get_country_data(country_name: String) -> Dictionary:
	if Globals.has_method("get_country"):
		return Globals.get_country(country_name)
	elif Globals.country_data.has(country_name):
		return Globals.country_data[country_name]
	return {}
