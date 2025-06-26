# res://scripts/main.gd
# Script principal que gerencia o fluxo do jogo, a UI e a coordenação dos sistemas.

extends Node

const GameMenu = preload("res://scenes/GameMenu.tscn")
const MONTH_NAMES = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]

enum GamePhase { POLITICAL_AGENT = 1, NATIONAL_LEADER = 2 }
enum GameSpeed { PAUSED = 0, SLOW = 4, NORMAL = 2, FAST = 1 }

@export_category("UI References")
@export var canvas_layer: CanvasLayer
@export var date_label: Label
@export var money_label: Label
@export var support_label: Label
@export var position_label: Label
@export var speed_label: Label
@export var info_container: VBoxContainer
@export var map_node: Node2D
@export var pause_button: Button
@export var normal_speed_button: Button
@export var fast_speed_button: Button
@export var narrative_panel: PanelContainer
@export var investigate_button: Button # Adicione o botão "Investigar Redes" aqui
@export var narrativas_button: Button # 

var current_phase: GamePhase = GamePhase.POLITICAL_AGENT
var game_speed: GameSpeed = GameSpeed.NORMAL

var party_controller: PartyController
var notification_system: Node
var game_timer: Timer

var current_year: int = 1973
var current_month: int = 1

# =====================================
# INICIALIZAÇÃO
# =====================================
func _ready():
	print("=== INICIALIZANDO JOGO ===")
	_create_systems()
	_setup_party()
	_connect_signals()
	_start_game()
	_update_all_ui()

func _create_systems():
	notification_system = preload("res://scripts/NotificationSystem.gd").new()
	notification_system.name = "NotificationSystem"
	add_child(notification_system)
	if is_instance_valid(canvas_layer):
		notification_system.setup(canvas_layer)
	else:
		printerr("ERRO: CanvasLayer não foi atribuído no inspetor do nó Main!")

	game_timer = Timer.new()
	game_timer.name = "GameTimer"
	game_timer.wait_time = float(game_speed)
	game_timer.timeout.connect(_on_month_timer_timeout)
	add_child(game_timer)

func _setup_party():
	party_controller = PartyController.new()
	party_controller.name = "PartyController"
	add_child(party_controller)
	
	party_controller.treasury_changed.connect(_on_treasury_changed)
	party_controller.phase_advanced.connect(_on_phase_advanced)
	party_controller.support_changed.connect(_on_support_changed)
	party_controller.action_executed.connect(_on_action_executed)

func _connect_signals():
	_connect_map_signals()
	
	# Conecta os botões de velocidade
	if pause_button and not pause_button.is_connected("pressed", set_game_speed):
		pause_button.pressed.connect(set_game_speed.bind(GameSpeed.PAUSED))
	if normal_speed_button and not normal_speed_button.is_connected("pressed", set_game_speed):
		normal_speed_button.pressed.connect(set_game_speed.bind(GameSpeed.NORMAL))
	if fast_speed_button and not fast_speed_button.is_connected("pressed", set_game_speed):
		fast_speed_button.pressed.connect(set_game_speed.bind(GameSpeed.FAST))
	
	# Conecta os sinais dos Autoloads
	if NarrativeSystem and not NarrativeSystem.is_connected("narrative_consequence_triggered", _on_narrative_consequence_triggered):
		NarrativeSystem.narrative_consequence_triggered.connect(_on_narrative_consequence_triggered)
		
	if ChileEvents and not ChileEvents.is_connected("historical_event_notification", _on_historical_event_notification):
		ChileEvents.historical_event_notification.connect(_on_historical_event_notification)
		
	# Conecta os botões de ação da UI
	if investigate_button and not investigate_button.is_connected("pressed", _on__investigar_redes_pressed):
		investigate_button.pressed.connect(_on__investigar_redes_pressed)
	
	# --- ADICIONE ESTA CONEXÃO PARA O BOTÃO DE NARRATIVAS ---
	if narrativas_button and not narrativas_button.is_connected("pressed", _on_narrativas_button_pressed):
		narrativas_button.pressed.connect(_on_narrativas_button_pressed)

func _start_game():
	game_timer.start()
	print("=== JOGO INICIADO ===")
	notification_system.show_notification(
		"Um Novo Início", 
		"Seu partido, '%s', começa sua jornada no Chile." % party_controller.party_data.party_name,
		NotificationSystem.NotificationType.INFO
	)

# =====================================
# GAME LOOP
# =====================================
func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func _on_month_timer_timeout():
	advance_month()

func advance_month():
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
		notification_system.show_notification("Novo Ano", "Chegamos a %d!" % current_year, NotificationSystem.NotificationType.INFO)
	
	party_controller.advance_month()
	
	# Chama os sistemas a cada mês
	ChileEvents.check_for_events(current_year, current_month)
	NarrativeSystem.process_narrative_spread()
	NarrativeSystem.check_narrative_consequences()
	
	_update_all_ui()

# =====================================
# GERENCIAMENTO DE UI E PAUSA
# =====================================

func toggle_pause():
	var tree = get_tree()
	tree.paused = not tree.paused
	var menu_instance = get_node_or_null("GameMenu")
	if tree.paused:
		if not menu_instance:
			menu_instance = GameMenu.instantiate()
			menu_instance.name = "GameMenu"
			add_child(menu_instance)
			menu_instance.resume_game.connect(toggle_pause)
			# Adicione aqui outras conexões se necessário (ex: Sair)
	else:
		if menu_instance:
			menu_instance.queue_free()

func set_game_speed(speed: GameSpeed):
	if get_tree().paused: return
	game_speed = speed
	if speed == GameSpeed.PAUSED:
		game_timer.stop()
	else:
		game_timer.wait_time = float(speed)
		if game_timer.is_stopped():
			game_timer.start()
	_update_speed_display()

func _update_all_ui():
	if date_label:
		date_label.text = "%s %d" % [MONTH_NAMES[current_month - 1], current_year]
	if party_controller and party_controller.party_data:
		_set_treasury_label(party_controller.party_data.treasury)
		_set_support_label(party_controller.party_data.get_average_support())
		_set_position_label(party_controller.party_data.get_phase_name())
	_update_speed_display()

func _set_treasury_label(new_val: int):
	if money_label: money_label.text = "💰 %d" % new_val

func _set_support_label(new_val: float):
	if support_label: support_label.text = "📊 %.1f%%" % new_val

func _set_position_label(new_pos: String):
	if position_label: position_label.text = "🚩 " + new_pos
		
func _update_speed_display():
	if speed_label:
		match game_speed:
			GameSpeed.PAUSED: speed_label.text = "⏸️ Pausado"
			GameSpeed.SLOW: speed_label.text = "▶ Devagar"
			GameSpeed.NORMAL: speed_label.text = "▶▶ Normal"
			GameSpeed.FAST: speed_label.text = "▶▶▶ Rápido"

# =====================================
# HANDLERS DE SINAIS
# =====================================

func _on_treasury_changed(_old_val: int, new_val: int):
	_set_treasury_label(new_val)

func _on_phase_advanced(old_pos: String, new_pos: String):
	notification_system.show_notification("🎉 Partido Cresceu!", "Sua organização avançou de '%s' para '%s'!" % [old_pos, new_pos], NotificationSystem.NotificationType.SUCCESS)

func _on_support_changed(_group: String, _old_val: int, _new_val: int):
	# A notificação de mudança de apoio individual pode ser muito repetitiva.
	# Vamos apenas atualizar a média geral na UI.
	if party_controller:
		_set_support_label(party_controller.get_average_support())

func _on_action_executed(action_name: String, success: bool, message: String):
	var type = NotificationSystem.NotificationType.SUCCESS if success else NotificationSystem.NotificationType.ERROR
	notification_system.show_notification(action_name, message, type)
	await get_tree().process_frame
	if party_controller:
		show_country_info(party_controller.party_data.country)

func _on_historical_event_notification(title: String, message: String, type: int):
	notification_system.show_notification(title, message, type)

func _on_narrative_consequence_triggered(group_name: String, narrative_content: String):
	notification_system.show_notification("Reação Política!", "O grupo '%s' foi convencido pela narrativa de que '%s' e está a mudar o seu comportamento." % [group_name.capitalize(), narrative_content], NotificationSystem.NotificationType.INFO)

# =====================================
# LÓGICA DE INTERAÇÃO (MAPA E PAINÉIS)
# =====================================

func _connect_map_signals():
	if not map_node: return
	for country_node in map_node.get_children():
		if country_node.has_node("Area2D"):
			var area_node = country_node.get_node("Area2D")
			if not area_node.is_connected("input_event", _on_country_clicked):
				area_node.input_event.connect(_on_country_clicked.bind(country_node.name))

func _on_country_clicked(_viewport, event: InputEvent, _shape_idx, country_name: String):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		show_country_info(country_name)

func show_country_info(country_name: String):
	if not info_container: return
	for c in info_container.get_children(): c.queue_free()

	var title = Label.new()
	title.text = "🏛️ " + country_name.to_upper()
	info_container.add_child(title)

	if party_controller and party_controller.party_data and country_name == party_controller.party_data.country:
		var info = Label.new()
		info.text = "🚩 %s (%s)" % [party_controller.party_data.party_name, party_controller.party_data.get_phase_name()]
		info_container.add_child(info)
		
		var actions_title = Label.new()
		actions_title.text = "\n🎯 Ações do Partido:"
		info_container.add_child(actions_title)

		var actions = party_controller.get_available_actions()
		for action in actions:
			var btn = Button.new()
			btn.text = "%s (Custo: %d)" % [action.name, action.cost]
			btn.disabled = not party_controller.can_execute_action(action.name)
			btn.pressed.connect(party_controller.execute_action.bind(action.name))
			info_container.add_child(btn)
	else:
		var info_label = Label.new()
		info_label.text = "\nEste é um país vizinho. No futuro, poderá ver informações diplomáticas aqui."
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		info_container.add_child(info_label)

func _on__investigar_redes_pressed():
	if not info_container: return
	for c in info_container.get_children(): c.queue_free()
	
	var title = Label.new()
	title.text = "REDES DE PODER INVISÍVEIS"
	info_container.add_child(title)
	
	for network_id in PowerNetworks.hidden_networks:
		var network = PowerNetworks.hidden_networks[network_id]
		var network_box = VBoxContainer.new()
		
		if network["discovered"]:
			var name_label = Label.new()
			name_label.text = "✅ %s" % network["name"]
			var members_label = Label.new()
			members_label.text = "Membros: %s" % ", ".join(network["members"])
			network_box.add_child(name_label)
			network_box.add_child(members_label)
		else:
			var hint_label = Label.new()
			hint_label.text = "❓ Rede Suspeita (%s)" % network["connection_type"]
			network_box.add_child(hint_label)
			
			var investigate_btn = Button.new()
			investigate_btn.text = "Investigar (Custo: 50)"
			investigate_btn.pressed.connect(party_controller.attempt_network_discovery.bind(network_id))
			network_box.add_child(investigate_btn)
			
		info_container.add_child(network_box)
		info_container.add_child(HSeparator.new())

func _on_narrativas_button_pressed():
	# Lógica para o painel de narrativas...
	pass
