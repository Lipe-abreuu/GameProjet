# res://scripts/main.gd
# Versão corrigida com NotificationSystem local

extends Node

# --- Constantes e Enums ---
const GameMenu = preload("res://scenes/GameMenu.tscn")
const MONTH_NAMES = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]

enum GamePhase { POLITICAL_AGENT = 1, NATIONAL_LEADER = 2 }
enum GameSpeed { PAUSED = 0, SLOW = 4, NORMAL = 2, FAST = 1 }

# --- Variáveis de Jogo ---
var game_speed: GameSpeed = GameSpeed.NORMAL
var current_phase: GamePhase = GamePhase.POLITICAL_AGENT
var current_year: int = 1973
var current_month: int = 1

# --- Referências de Nós da Cena (UI) ---
@export_category("UI References")
@export var canvas_layer: CanvasLayer
@export var date_label: Label
@export var money_label: Label
@export var support_label: Label
@export var position_label: Label
@export var militants_label: Label
@export var influence_label: Label
@export var speed_label: Label
@export var info_container: VBoxContainer
@export var map_node: Node2D
@export var pause_button: Button
@export var normal_speed_button: Button
@export var fast_speed_button: Button
@export var narrative_panel: PanelContainer
@export var investigate_button: Button
@export var narrativas_button: Button

# --- Nós Criados Dinamicamente ---
var party_controller: Node
var notification_system: Node
var game_timer: Timer
var heat_ui: Control

# Enum do NotificationSystem (temporário até registrar como autoload)
enum NotificationType { INFO, SUCCESS, ERROR }

# ===================================================================
# FUNÇÕES DE INICIALIZAÇÃO DO GODOT
# ===================================================================

func _ready():
	print("=== INICIALIZANDO JOGO ===")
	
	# Corrigir escala do Control se necessário
	var control = get_node_or_null("Control")
	if control and control.scale != Vector2.ONE:
		print("⚠️ Corrigindo escala do Control: %s → (1, 1)" % control.scale)
		control.scale = Vector2.ONE
	
	_create_systems()
	_setup_party()
	_connect_signals()
	_start_game()
	_update_all_ui()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

# ===================================================================
# CONFIGURAÇÃO INICIAL DOS SISTEMAS
# ===================================================================

func _create_systems():
	# NotificationSystem já está como autoload
	notification_system = get_node("/root/NotificationSystem")
	
	# Aguardar um frame para garantir que a UI esteja pronta
	await get_tree().process_frame
	
	# Procurar o CanvasLayer na estrutura
	var canvas = get_node_or_null("CanvasLayer")
	if not canvas:
		# Tentar no Control principal
		var control = get_node_or_null("Control")
		if control:
			canvas = control.get_node_or_null("CanvasLayer")
	
	if canvas:
		notification_system.setup(canvas)
		print("✅ NotificationSystem configurado com CanvasLayer")
	else:
		print("❌ CanvasLayer não encontrado para NotificationSystem")

	# Timer Principal do Jogo
	game_timer = Timer.new()
	game_timer.name = "GameTimer"
	game_timer.wait_time = float(game_speed)
	game_timer.timeout.connect(_on_month_timer_timeout)
	add_child(game_timer)

	# Interface do Heat
	var heat_ui_path = "res://scenes/HeatUIComponent.tscn"
	if ResourceLoader.exists(heat_ui_path):
		var heat_ui_scene = load(heat_ui_path)
		heat_ui = heat_ui_scene.instantiate()
		heat_ui.name = "HeatUI"
		if is_instance_valid(canvas_layer):
			canvas_layer.add_child(heat_ui)
		else:
			add_child(heat_ui)
	else:
		print("⚠️ HeatUIComponent.tscn não encontrado")

func _setup_party():
	party_controller = preload("res://scripts/PartyController.gd").new()
	party_controller.name = "PartyController"
	add_child(party_controller)
	
	# Registrar no Globals para outros sistemas encontrarem
	if Globals.has("party_controller"):
		Globals.party_controller = party_controller
	else:
		Globals.set("party_controller", party_controller)
	
	print("✅ PartyController criado e registrado no Globals")

func _connect_signals():
	# Conecta a UI ao Singleton HeatSystem de forma segura.
	var heat_system = get_node_or_null("/root/HeatSystem")
	if is_instance_valid(heat_ui) and is_instance_valid(heat_system) and heat_ui.has_method("connect_to_heat_system"):
		heat_ui.connect_to_heat_system(heat_system)

	# Sinais do Controlador do Partido
	if party_controller:
		party_controller.treasury_changed.connect(_on_treasury_changed)
		party_controller.phase_advanced.connect(_on_phase_advanced)
		party_controller.support_changed.connect(_on_support_changed)
		party_controller.action_executed.connect(_on_action_executed)

	# Sinais dos Singletons Globais
	if is_instance_valid(heat_system):
		heat_system.raid_triggered.connect(_on_raid_triggered)
		if heat_system.has_signal("close_call_triggered"):
			heat_system.close_call_triggered.connect(_on_close_call)
	
	var narrative_system = get_node_or_null("/root/NarrativeSystem")
	if is_instance_valid(narrative_system):
		narrative_system.narrative_consequence_triggered.connect(_on_narrative_consequence_triggered)
			
	var chile_events = get_node_or_null("/root/ChileEvents")
	if is_instance_valid(chile_events):
		chile_events.historical_event_notification.connect(_on_historical_event_notification)

	# Sinais da UI - verificar se existem antes de conectar
	_connect_map_signals()
	
	if pause_button:
		pause_button.pressed.connect(set_game_speed.bind(GameSpeed.PAUSED))
	if normal_speed_button:
		normal_speed_button.pressed.connect(set_game_speed.bind(GameSpeed.NORMAL))
	if fast_speed_button:
		fast_speed_button.pressed.connect(set_game_speed.bind(GameSpeed.FAST))
	if investigate_button:
		investigate_button.pressed.connect(_on_investigar_redes_pressed)
	if narrativas_button:
		narrativas_button.pressed.connect(_on_narrativas_button_pressed)

func _start_game():
	game_timer.start()
	print("=== JOGO INICIADO ===")
	if notification_system:
		notification_system.show_notification(
			"Um Novo Início",
			"O seu partido, '%s', começa a sua jornada no Chile." % party_controller.party_data.party_name,
			NotificationType.INFO
		)

# ===================================================================
# FLUXO PRINCIPAL E LÓGICA DO JOGO
# ===================================================================

func _on_month_timer_timeout():
	advance_month()

func advance_month():
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
		if notification_system:
			notification_system.show_notification("Novo Ano", "Chegamos a %d!" % current_year, NotificationType.INFO)

	if is_instance_valid(party_controller): 
		party_controller.advance_month()
	
	var heat_system = get_node_or_null("/root/HeatSystem")
	if heat_system: 
		heat_system.process_monthly_turn()
	
	var chile_events = get_node_or_null("/root/ChileEvents")
	if chile_events: 
		chile_events.check_for_events(current_year, current_month)
	
	var narrative_system = get_node_or_null("/root/NarrativeSystem")
	if narrative_system:
		narrative_system.process_narrative_spread()
		narrative_system.check_narrative_consequences()
	
	_update_all_ui()

func toggle_pause():
	var tree = get_tree()
	tree.paused = not tree.paused
	var menu_instance = get_node_or_null("GameMenu")
	if tree.paused and not is_instance_valid(menu_instance):
		menu_instance = GameMenu.instantiate()
		menu_instance.name = "GameMenu"
		add_child(menu_instance)
		menu_instance.resume_game.connect(toggle_pause)
	elif not tree.paused and is_instance_valid(menu_instance):
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

# ===================================================================
# ATUALIZAÇÃO DA INTERFACE (UI)
# ===================================================================

func _update_all_ui():
	if date_label: 
		date_label.text = "%s %d" % [MONTH_NAMES[current_month - 1], current_year]
	
	if is_instance_valid(party_controller) and party_controller.party_data:
		_set_treasury_label(party_controller.party_data.treasury)
		_set_support_label(party_controller.party_data.get_average_support())
		_set_position_label(party_controller.party_data.get_phase_name())
		_set_militants_label(party_controller.party_data.militants)
		_set_influence_label(party_controller.party_data.influence)
	
	_update_speed_display()

func _set_treasury_label(new_val: int):
	if money_label: 
		money_label.text = "Dinheiro: %d" % new_val

func _set_support_label(new_val: float):
	if support_label: 
		support_label.text = "Apoio: %.1f%%" % new_val

func _set_position_label(new_pos: String):
	if position_label: 
		position_label.text = "Posição: " + new_pos
		
func _set_militants_label(militants: int):
	if militants_label:
		militants_label.text = "Militantes: %d" % militants
		militants_label.add_theme_color_override("font_color", Color.WHITE if militants > 100 else Color.YELLOW if militants > 50 else Color.RED)

func _set_influence_label(influence: float):
	if influence_label:
		influence_label.text = "Influência: %.1f" % influence
		influence_label.add_theme_color_override("font_color", Color.LIGHT_BLUE if influence > 10 else Color.WHITE)

func _update_speed_display():
	if speed_label:
		match game_speed:
			GameSpeed.PAUSED: speed_label.text = "Pausado"
			GameSpeed.SLOW: speed_label.text = "Lento"
			GameSpeed.NORMAL: speed_label.text = "Normal"
			GameSpeed.FAST: speed_label.text = "Rápido"

# ===================================================================
# HANDLERS DE SINAIS (EVENTOS)
# ===================================================================

func _on_treasury_changed(_old_val: int, new_val: int):
	_set_treasury_label(new_val)

func _on_phase_advanced(old_pos: String, new_pos: String):
	if notification_system:
		notification_system.show_notification(
			"Partido Cresceu!", 
			"A sua organização avançou de '%s' para '%s'!" % [old_pos, new_pos], 
			NotificationType.SUCCESS
		)

func _on_support_changed(_group: String, _old_val: int, _new_val: int):
	if party_controller:
		_set_support_label(party_controller.get_average_support())

func _on_action_executed(action_name: String, success: bool, message: String):
	if notification_system:
		notification_system.show_notification(
			action_name, 
			message, 
			NotificationType.SUCCESS if success else NotificationType.ERROR
		)
	
	if success:
		var heat_system = get_node_or_null("/root/HeatSystem")
		if heat_system:
			heat_system.apply_heat_from_action(action_name, success)
	
	await get_tree().process_frame
	show_country_info(party_controller.party_data.country)

func _on_historical_event_notification(title: String, message: String, type: int):
	if notification_system:
		notification_system.show_notification(title, message, type)

func _on_narrative_consequence_triggered(group_name: String, narrative_content: String):
	if notification_system:
		notification_system.show_notification(
			"Reação Política!", 
			"O grupo '%s' foi convencido pela narrativa de que '%s' e está a mudar o seu comportamento." % [group_name.capitalize(), narrative_content], 
			NotificationType.INFO
		)

func _on_raid_triggered():
	set_game_speed(GameSpeed.PAUSED)
	# TODO: Implementar diálogo de raid

func handle_raid_choice(choice: String):
	get_tree().paused = false
	set_game_speed(GameSpeed.NORMAL)
	
	var heat_system = get_node_or_null("/root/HeatSystem")
	if heat_system:
		var result = heat_system.handle_raid_response(choice)
		if notification_system:
			notification_system.show_notification("Resultado da Batida", result.message, NotificationType.INFO)
	
	_update_all_ui()

func _on_close_call(event_type: String):
	# TODO: Implementar avisos de "close call"
	pass

# ===================================================================
# LÓGICA DE INTERAÇÃO COM A UI (MAPA E PAINÉIS)
# ===================================================================

func _connect_map_signals():
	# Tentar encontrar o mapa em diferentes locais
	if not map_node:
		# Primeiro tenta no Control
		var control = get_node_or_null("Control")
		if control:
			map_node = control.get_node_or_null("NodeMapaSVG2D")
		
		# Se não encontrar, tenta direto no root
		if not map_node:
			map_node = get_node_or_null("NodeMapaSVG2D")
	
	if not is_instance_valid(map_node):
		print("❌ Mapa não encontrado para conectar sinais")
		return
	
	print("📍 Conectando sinais do mapa...")
	
	for country_node in map_node.get_children():
		if not country_node is Polygon2D:
			continue
			
		# Se não tem Area2D, criar uma
		if not country_node.has_node("Area2D"):
			print("  Criando Area2D para: %s" % country_node.name)
			var area = Area2D.new()
			area.name = "Area2D"
			
			var collision = CollisionPolygon2D.new()
			collision.polygon = country_node.polygon
			area.add_child(collision)
			
			country_node.add_child(area)
		
		# Conectar o sinal
		var area_node = country_node.get_node("Area2D")
		if not area_node.is_connected("input_event", _on_country_clicked):
			area_node.input_event.connect(_on_country_clicked.bind(country_node.name))
			print("  ✅ %s conectado" % country_node.name)

func _on_country_clicked(_viewport, event: InputEvent, _shape_idx, country_name: String):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		show_country_info(country_name)

func show_country_info(country_name: String):
	print("📍 Mostrando informações de: %s" % country_name)
	
	if not info_container:
		print("❌ info_container não encontrado")
		return
	
	# Limpar container
	for child in info_container.get_children():
		child.queue_free()
	
	# Título
	var title_label = Label.new()
	title_label.text = country_name.to_upper()
	title_label.add_theme_font_size_override("font_size", 20)
	info_container.add_child(title_label)
	
	# Se for o país do jogador, mostrar info do partido
	if country_name == "Chile" and party_controller:
		var party_info = Label.new()
		party_info.text = "\n🎯 SEU PARTIDO"
		party_info.add_theme_font_size_override("font_size", 16)
		party_info.add_theme_color_override("font_color", Color.CYAN)
		info_container.add_child(party_info)
		
		# Ações disponíveis
		var actions_label = Label.new()
		actions_label.text = "\nAÇÕES DISPONÍVEIS:"
		actions_label.add_theme_font_size_override("font_size", 14)
		info_container.add_child(actions_label)
		
		var actions = party_controller.get_available_actions()
		for action in actions:
			var btn = Button.new()
			btn.text = "%s ($%d)" % [action.name, action.cost]
			btn.tooltip_text = action.description
			btn.disabled = not party_controller.can_execute_action(action.name)
			btn.pressed.connect(_on_action_button_pressed.bind(action.name))
			info_container.add_child(btn)

func _on_action_button_pressed(action_name: String):
	print("🎮 Executando ação: %s" % action_name)
	if party_controller:
		party_controller.execute_action(action_name)

func _on_narrativas_button_pressed():
	# TODO: Implementar painel de narrativas
	print("Botão de narrativas pressionado")

func _on_create_counter_narrative(original_narrative):
	# TODO: Implementar contra-narrativas
	pass

func _on_amplify_narrative(_narrative):
	if notification_system:
		notification_system.show_notification(
			"Ação Indisponível", 
			"A lógica para amplificar narrativas ainda não foi implementada.", 
			NotificationType.INFO
		)

func _on_investigar_redes_pressed():
	if not is_instance_valid(info_container): 
		return
		
	for c in info_container.get_children(): 
		c.queue_free()

	var title = Label.new()
	title.text = "REDES DE PODER INVISÍVEIS"
	info_container.add_child(title)

	var power_networks_system = get_node_or_null("/root/PowerNetworks")
	if not is_instance_valid(power_networks_system):
		var error_label = Label.new()
		error_label.text = "ERRO: O sistema 'PowerNetworks' não é um Autoload."
		info_container.add_child(error_label)
		return

	if power_networks_system.hidden_networks.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Nenhuma rede suspeita encontrada."
		info_container.add_child(empty_label)
		return

	for network_id in power_networks_system.hidden_networks:
		var network = power_networks_system.hidden_networks[network_id]
		# TODO: Implementar exibição das redes
		var network_label = Label.new()
		network_label.text = network.name if network.has("name") else network_id
		info_container.add_child(network_label)
