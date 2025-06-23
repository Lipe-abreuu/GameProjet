# =====================================
#  MAIN.GD - VERSÃO CORRIGIDA E INTEGRADA
# =====================================
# IMPORTANTE: Requer os arquivos PlayerAgentResource.gd e PlayerAgentController.gd
extends Node

# --- PRELOADS E CONSTANTES ---
const NotificationSystem = preload("res://scripts/NotificationSystem.gd")
const GameMenu = preload("res://scenes/GameMenu.tscn")
const MONTH_NAMES = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]

enum GamePhase { POLITICAL_AGENT = 1, NATIONAL_LEADER = 2 }
enum GameSpeed { PAUSED = 0, SLOW = 4, NORMAL = 2, FAST = 1 }

# --- CONFIGURAÇÕES ---
@export var current_phase: GamePhase = GamePhase.POLITICAL_AGENT
@export var game_speed: GameSpeed = GameSpeed.NORMAL

# --- SISTEMAS ---
var player_controller: PlayerAgentController
var notification_system: NotificationSystem
var game_timer: Timer
var ui_manager: Node  # Será UIManager, mas declarado como Node por enquanto

# --- DADOS DO JOGO ---
var current_year: int = 1973
var current_month: int = 1

# =====================================
# INICIALIZAÇÃO
# =====================================
func _ready():
	print("=== INICIALIZANDO JOGO ===")
	_create_systems()
	_setup_player()
	_setup_ui()
	_connect_signals()
	_start_game()

func _create_systems():
	# Sistema de notificações
	notification_system = NotificationSystem.new()
	notification_system.name = "NotificationSystem"
	add_child(notification_system)
	
	# Timer do jogo
	game_timer = Timer.new()
	game_timer.name = "GameTimer"
	game_timer.wait_time = game_speed
	game_timer.timeout.connect(_on_month_timer_timeout)
	add_child(game_timer)
	
	# Gerenciador de UI - criar antes de usar
	# Como UIManager está definido mais abaixo, vamos criá-lo diretamente aqui
	ui_manager = Node.new()
	ui_manager.name = "UIManager"
	ui_manager.set_script(preload("res://scripts/UIManager.gd") if FileAccess.file_exists("res://scripts/UIManager.gd") else null)
	add_child(ui_manager)

func _setup_player():
	player_controller = PlayerAgentController.new()
	player_controller.name = "PlayerController"
	add_child(player_controller)
	
	# Conecta sinais do controlador
	player_controller.position_advanced.connect(_on_position_advanced)
	player_controller.support_changed.connect(_on_support_changed)
	player_controller.wealth_changed.connect(_on_wealth_changed)
	player_controller.action_executed.connect(_on_action_executed)

func _setup_ui():
	# Se UIManager foi carregado de arquivo separado
	if ui_manager and ui_manager.has_method("setup_ui_references"):
		ui_manager.setup_ui_references(self)
	else:
		# Caso contrário, configurar diretamente
		_setup_ui_references_direct()
	_update_all_ui()

func _setup_ui_references_direct():
	var canvas = get_node_or_null("CanvasLayer")
	if not canvas:
		push_error("CanvasLayer não encontrado!")
		return
	
	# Criar dicionário para armazenar referências
	ui_manager.set_meta("ui_refs", {
		"date_label": null,
		"money_label": null,
		"support_label": null,
		"position_label": null,
		"speed_label": null,
		"info_container": null
	})
	
	var refs = ui_manager.get_meta("ui_refs")
	
	# TopBar
	var topbar = canvas.get_node_or_null("TopBar/HBoxContainer")
	if topbar:
		refs.date_label = topbar.get_node_or_null("DateLabel")
		refs.money_label = topbar.get_node_or_null("MoneyLabel")
		refs.support_label = topbar.get_node_or_null("StabilityLabel")
		refs.position_label = topbar.get_node_or_null("PositionLabel")
		print("TopBar labels encontrados - Date: ", refs.date_label != null, " Money: ", refs.money_label != null)
	else:
		print("TopBar não encontrado!")
	
	# Speed indicator
	var bottombar = canvas.get_node_or_null("BottomBar/HBoxContainer")
	if bottombar:
		refs.speed_label = bottombar.get_node_or_null("SpeedLabel")
		print("SpeedLabel encontrado: ", refs.speed_label != null)
	else:
		print("BottomBar não encontrado!")
	
	# Info panel
	var sidepanel = canvas.get_node_or_null("Sidepanel")
	if sidepanel:
		refs.info_container = sidepanel.get_node_or_null("InfoContainer")
		print("InfoContainer encontrado: ", refs.info_container != null)
	else:
		print("Sidepanel não encontrado!")
	
	# Debug final
	print("=== UI REFS DEBUG ===")
	print("Canvas: ", canvas != null)
	print("InfoContainer path: ", refs.info_container.get_path() if refs.info_container else "NÃO ENCONTRADO")

func _connect_signals():
	# Menu de pausa
	var menu = get_node_or_null("GameMenu")
	if menu:
		if menu.has_signal("resume_game"):
			menu.resume_game.connect(_on_resume_game)
		if menu.has_signal("quit_to_main_menu"):
			menu.quit_to_main_menu.connect(_on_quit_to_main_menu)
		if menu.has_signal("speed_changed"):
			menu.speed_changed.connect(_on_speed_changed)
	
	# MOVA PARA AQUI - FORA DO IF:
	_connect_map_signals()

func _start_game():
	game_timer.start()
	print("=== JOGO INICIADO ===")
	notification_system.show_notification(
		"Bem-vindo!", 
		"Você é %s, um %s no %s" % [
			player_controller.agent_data.agent_name,
			player_controller.agent_data.get_position_name(),
			player_controller.agent_data.country
		],
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
		player_controller.agent_data.age += 1
		notification_system.show_notification(
			"Novo Ano", 
			"Chegamos a %d!" % current_year,
			NotificationSystem.NotificationType.INFO
		)
	
	player_controller.advance_month()
	_update_all_ui()

func toggle_pause():
	if game_speed == GameSpeed.PAUSED:
		set_game_speed(GameSpeed.NORMAL)
	else:
		set_game_speed(GameSpeed.PAUSED)

func set_game_speed(speed: GameSpeed):
	game_speed = speed
	if speed == GameSpeed.PAUSED:
		game_timer.stop()
		get_tree().paused = true
	else:
		game_timer.wait_time = float(speed)
		game_timer.start()
		get_tree().paused = false
	
	_update_speed_display(speed)

func _update_wealth_display(new_val: int):
	if ui_manager and ui_manager.has_method("update_wealth_display"):
		ui_manager.update_wealth_display(new_val)
	elif ui_manager and ui_manager.has_meta("ui_refs"):
		var refs = ui_manager.get_meta("ui_refs")
		if refs.money_label:
			refs.money_label.text = "💰 %d" % new_val

func _update_speed_display(speed: GameSpeed):
	if ui_manager and ui_manager.has_method("update_speed_display"):
		ui_manager.update_speed_display(speed)
	elif ui_manager and ui_manager.has_meta("ui_refs"):
		var refs = ui_manager.get_meta("ui_refs")
		if refs.speed_label:
			match speed:
				GameSpeed.PAUSED:
					refs.speed_label.text = "⏸️ Pausado"
				GameSpeed.SLOW:
					refs.speed_label.text = "▶ Devagar"
				GameSpeed.NORMAL:
					refs.speed_label.text = "▶▶ Normal"
				GameSpeed.FAST:
					refs.speed_label.text = "▶▶▶ Rápido"

# =====================================
# CALLBACKS
# =====================================
func _on_position_advanced(old_pos: String, new_pos: String):
	notification_system.show_notification(
		"🎉 Promoção!",
		"%s avançou de %s para %s!" % [
			player_controller.agent_data.agent_name,
			old_pos,
			new_pos
		],
		NotificationSystem.NotificationType.SUCCESS
	)
	
	# Verifica mudança de fase
	if new_pos == "Presidente" and current_phase == GamePhase.POLITICAL_AGENT:
		_transition_to_national_leader()

func _on_support_changed(group: String, old_val: int, new_val: int):
	var change = new_val - old_val
	var icon = "📈" if change > 0 else "📉"
	notification_system.show_notification(
		icon + " Apoio " + group.capitalize(),
		"Mudou de %d%% para %d%%" % [old_val, new_val],
		NotificationSystem.NotificationType.INFO
	)

func _on_wealth_changed(old_val: int, new_val: int):
	_update_wealth_display(new_val)

func _on_action_executed(action_name: String, success: bool, message: String):
	var type = NotificationSystem.NotificationType.SUCCESS if success else NotificationSystem.NotificationType.ERROR
	notification_system.show_notification(action_name, message, type)

func _transition_to_national_leader():
	current_phase = GamePhase.NATIONAL_LEADER
	notification_system.show_notification(
		"🌟 Nova Fase!",
		"Você agora é o líder nacional! Novas responsabilidades aguardam.",
		NotificationSystem.NotificationType.SUCCESS
	)
	# TODO: Implementar mecânicas da fase 2

func _on_resume_game():
	toggle_pause()

func _on_quit_to_main_menu():
	get_tree().paused = false
	# get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_speed_changed(new_speed):
	game_timer.wait_time = float(new_speed)

# =====================================
# UI
# =====================================
func _update_all_ui():
	# Atualizar via UIManager se disponível
	if ui_manager and ui_manager.has_method("update_date"):
		ui_manager.update_date(MONTH_NAMES[current_month - 1], current_year)
		ui_manager.update_wealth_display(player_controller.agent_data.wealth)
		ui_manager.update_support_display(player_controller.agent_data.get_average_support())
		ui_manager.update_position_display(player_controller.agent_data.get_position_name())
	else:
		# Atualizar diretamente se UIManager não estiver disponível
		_update_ui_direct()

func _update_ui_direct():
	if not ui_manager or not ui_manager.has_meta("ui_refs"):
		return
		
	var refs = ui_manager.get_meta("ui_refs")
	
	if refs.date_label:
		refs.date_label.text = "%s %d" % [MONTH_NAMES[current_month - 1], current_year]
	
	if refs.money_label and player_controller and player_controller.agent_data:
		refs.money_label.text = "💰 %d" % player_controller.agent_data.wealth
	
	if refs.support_label and player_controller and player_controller.agent_data:
		refs.support_label.text = "📊 %.1f%%" % player_controller.agent_data.get_average_support()
	
	if refs.position_label and player_controller and player_controller.agent_data:
		refs.position_label.text = "👤 " + player_controller.agent_data.get_position_name()

# =====================================
# SISTEMA DE INTERAÇÃO COM MAPA
# =====================================
func _connect_map_signals():
	var map_node = get_node_or_null("NodeMapaSVG2D")
	if not map_node: 
		print("ERRO: Mapa não encontrado!")
		return
	
	for country_node in map_node.get_children():
		if country_node.has_node("Area2D"):
			var area_node = country_node.get_node("Area2D")
			area_node.input_event.connect(_on_country_clicked.bind(country_node.name))
			print("✅ Sinal conectado para: " + country_node.name)

func _on_country_clicked(event: InputEvent, country_name: String):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		show_country_info(country_name)

func show_country_info(country_name: String):
	if not ui_manager or not ui_manager.has_meta("ui_refs"):
		return
	
	var refs = ui_manager.get_meta("ui_refs")
	if not refs.info_container:
		return
		
	# Limpar container
	for child in refs.info_container.get_children():
		child.queue_free()
	
	# Título do país
	var title = Label.new()
	title.text = "🏛️ " + country_name.to_upper()
	refs.info_container.add_child(title)
	
	# Se for o país do jogador
	if player_controller and player_controller.agent_data and country_name == player_controller.agent_data.country:
		var info = Label.new()
		info.text = "👤 %s (%s)" % [
			player_controller.agent_data.agent_name,
			player_controller.agent_data.get_position_name()
		]
		refs.info_container.add_child(info)
		
		# Botão de ações
		var button = Button.new()
		button.text = "🎯 Ações Políticas"
		button.pressed.connect(_on_political_action_button_pressed)
		refs.info_container.add_child(button)

func _on_political_action_button_pressed():
	if not ui_manager or not ui_manager.has_meta("ui_refs"):
		return
		
	var refs = ui_manager.get_meta("ui_refs")
	if not refs.info_container:
		return
	
	# Limpar container
	for child in refs.info_container.get_children():
		child.queue_free()
	
	# Mostrar ações disponíveis
	var actions = player_controller.get_available_actions()
	for action in actions:
		var btn = Button.new()
		btn.text = "%s (Custo: %d)" % [action.name, action.cost]
		btn.disabled = not action.available
		btn.pressed.connect(_on_action_pressed.bind(action))
		refs.info_container.add_child(btn)

func _on_action_pressed(action: Dictionary):
	player_controller.execute_action(action.name)
	# Atualizar UI
	await get_tree().process_frame
	show_country_info(player_controller.agent_data.country)
