# res://scripts/main.gd
# Script principal que gerencia o fluxo do jogo, a UI e a coordenação dos sistemas.

extends Node

const GameMenu = preload("res://scenes/GameMenu.tscn")
const MONTH_NAMES = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]

# --- ENUMS E VARIÁVEIS DE MEMBRO ---
# A declaração do enum e da variável game_speed foi movida para o topo do script,
# tornando-os acessíveis a todas as funções.
enum GamePhase { POLITICAL_AGENT = 1, NATIONAL_LEADER = 2 }
enum GameSpeed { PAUSED = 0, SLOW = 4, NORMAL = 2, FAST = 1 }
var game_speed: GameSpeed = GameSpeed.NORMAL

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
@export var investigate_button: Button
@export var narrativas_button: Button
@onready var ChileEvents: Node = get_node("/root/ChileEvents")
@onready var NarrativeSystem: Node = get_node("/root/NarrativeSystem")
@export var militants_label: Label
@export var influence_label: Label

var current_phase: GamePhase = GamePhase.POLITICAL_AGENT
var party_controller: PartyController
var notification_system: Node
var game_timer: Timer

var current_year: int = 1973
var current_month: int = 1

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
	
	if pause_button and not pause_button.is_connected("pressed", set_game_speed):
		pause_button.pressed.connect(set_game_speed.bind(GameSpeed.PAUSED))
	if normal_speed_button and not normal_speed_button.is_connected("pressed", set_game_speed):
		normal_speed_button.pressed.connect(set_game_speed.bind(GameSpeed.NORMAL))
	if fast_speed_button and not fast_speed_button.is_connected("pressed", set_game_speed):
		fast_speed_button.pressed.connect(set_game_speed.bind(GameSpeed.FAST))
	
	if NarrativeSystem and not NarrativeSystem.is_connected("narrative_consequence_triggered", _on_narrative_consequence_triggered):
		NarrativeSystem.narrative_consequence_triggered.connect(_on_narrative_consequence_triggered)
		
	if ChileEvents and not ChileEvents.is_connected("historical_event_notification", _on_historical_event_notification):
		ChileEvents.historical_event_notification.connect(_on_historical_event_notification)
		
	if investigate_button and not investigate_button.is_connected("pressed", _on__investigar_redes_pressed):
		investigate_button.pressed.connect(_on__investigar_redes_pressed)
	
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
	
	# Verificação segura para ChileEvents
	var chile_events = get_node_or_null("/root/ChileEvents")
	if chile_events and chile_events.has_method("check_for_events"):
		chile_events.check_for_events(current_year, current_month)
	
	# Verificação segura para NarrativeSystem  
	var narrative_system = get_node_or_null("/root/NarrativeSystem")
	if narrative_system:
		if narrative_system.has_method("process_narrative_spread"):
			narrative_system.process_narrative_spread()
		if narrative_system.has_method("check_narrative_consequences"):
			narrative_system.check_narrative_consequences()
	
	_update_all_ui()

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
	if date_label: date_label.text = "%s %d" % [MONTH_NAMES[current_month - 1], current_year]
	if party_controller and party_controller.party_data:
		_set_treasury_label(party_controller.party_data.treasury)
		_set_support_label(party_controller.party_data.get_average_support())
		_set_position_label(party_controller.party_data.get_phase_name())
		
		# ADICIONAR ESTAS 2 LINHAS:
		_set_militants_label(party_controller.party_data.militants)
		_set_influence_label(party_controller.party_data.influence)
	
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

func _on_treasury_changed(_old_val: int, new_val: int):
	_set_treasury_label(new_val)

func _on_phase_advanced(old_pos: String, new_pos: String):
	notification_system.show_notification("🎉 Partido Cresceu!", "Sua organização avançou de '%s' para '%s'!" % [old_pos, new_pos], NotificationSystem.NotificationType.SUCCESS)

func _on_support_changed(_group: String, _old_val: int, _new_val: int):
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

func _on_narrativas_button_pressed():
	if not narrative_panel: return
	narrative_panel.visible = not narrative_panel.visible
	if not narrative_panel.visible: return
	var narrative_list = narrative_panel.get_node_or_null("NarrativeList")
	if not narrative_list: return
	for c in narrative_list.get_children(): c.queue_free()
	var title = Label.new()
	title.text = "NARRATIVAS ATIVAS"
	narrative_list.add_child(title)
	if NarrativeSystem.active_narratives.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Nenhuma narrativa importante circulando."
		narrative_list.add_child(empty_label)
		return
	for narrative in NarrativeSystem.active_narratives:
		var narrative_box = HBoxContainer.new()
		narrative_box.add_theme_constant_override("separation", 15)
		var content_label = Label.new()
		content_label.text = '"' + narrative.content + '"'
		content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var buttons_vbox = VBoxContainer.new()
		var counter_btn = Button.new()
		counter_btn.text = "Contra-narrativa"
		counter_btn.pressed.connect(_on_create_counter_narrative.bind(narrative))
		var amplify_btn = Button.new()
		amplify_btn.text = "Amplificar"
		amplify_btn.pressed.connect(_on_amplify_narrative.bind(narrative))
		buttons_vbox.add_child(counter_btn)
		buttons_vbox.add_child(amplify_btn)
		narrative_box.add_child(content_label)
		narrative_box.add_child(buttons_vbox)
		narrative_list.add_child(narrative_box)
		narrative_list.add_child(HSeparator.new())

func _on_create_counter_narrative(original_narrative):
	var cost = 100
	if party_controller.party_data.treasury < cost:
		notification_system.show_notification("Sem Fundos", "Custa %d para criar uma contra-narrativa." % cost, NotificationSystem.NotificationType.ERROR)
		return
	party_controller.party_data.treasury -= cost
	var counter_content = "Fontes seguras desmentem os rumores de que '%s'" % original_narrative.content.to_lower()
	var counter_narrative = NarrativeSystem.Narrative.new({
		"content": counter_content,
		"source_group": "party_media",
		"intensity": 40 + (party_controller.party_data.influence / 2),
		"credibility": party_controller.party_data.militants / 1000.0,
		"target_groups": original_narrative.target_groups
	})
	NarrativeSystem.active_narratives.append(counter_narrative)
	notification_system.show_notification("Mídia", "Contra-narrativa lançada!", NotificationSystem.NotificationType.SUCCESS)
	_on_narrativas_button_pressed()
	_on_narrativas_button_pressed()

func _on_amplify_narrative(_narrative):
	notification_system.show_notification("Ação Indisponível", "A lógica para amplificar narrativas ainda não foi implementada.", NotificationSystem.NotificationType.INFO)

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
		
func _set_militants_label(militants: int):
	if militants_label: 
		militants_label.text = "👥 %d" % militants
		# Cor baseada na quantidade
		if militants > 200:
			militants_label.add_theme_color_override("font_color", Color.GREEN)
		elif militants > 100:
			militants_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			militants_label.add_theme_color_override("font_color", Color.RED)

func _set_influence_label(influence: float):
	if influence_label:
		influence_label.text = "⚡ %.1f" % influence
		# Cor baseada na influência
		if influence > 10:
			influence_label.add_theme_color_override("font_color", Color.GREEN)
		elif influence > 5:
			influence_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			influence_label.add_theme_color_override("font_color", Color.RED)
