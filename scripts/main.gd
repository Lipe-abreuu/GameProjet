# =====================================
#  MAIN.GD - VERSÃO FINAL COM UIMANAGER
#  Arquitetura limpa com sistema de notificações e UI Manager integrados
# =====================================
extends Node

# Carregar os scripts dos componentes
const NotificationSystem = preload("res://scripts/NotificationSystem.gd")
const UIManager = preload("res://scripts/UIManager.gd")

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
var notification_system: Node
var ui_manager: UIManager # A variável agora é do tipo UIManager
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
	_initialize_systems()
	_setup_ui_references()
	_setup_timer()
	_setup_input_handling()
	_create_default_agent()
	_start_game_loop()

func _initialize_systems() -> void:
	# Instanciar nosso sistema de notificações completo
	notification_system = NotificationSystem.new()
	add_child(notification_system)
	
	# Instanciar e configurar o UI Manager (agora descomentado)
	ui_manager = UIManager.new()
	ui_manager.setup(self)
	add_child(ui_manager)
	
	print("🎮 Sistemas (Notificações e UI Manager) inicializados.")

func _setup_ui_references() -> void:
	date_label = get_node_or_null("CanvasLayer/TopBar/HBoxContainer/DateLabel")
	money_label = get_node_or_null("CanvasLayer/TopBar/HBoxContainer/MoneyLabel")
	stability_label = get_node_or_null("CanvasLayer/TopBar/HBoxContainer/StabilityLabel")
	pause_button = get_node_or_null("CanvasLayer/BottomBar/HBoxContainer/PauseButton")
	next_button = get_node_or_null("CanvasLayer/BottomBar/HBoxContainer/NextButton")
	info_container = get_node_or_null("CanvasLayer/Sidepanel/InfoContainer")
	
	print("UI DateLabel: %s" % ("✅" if date_label else "❌"))
	print("UI MoneyLabel: %s" % ("✅" if money_label else "❌"))
	print("UI StabilityLabel: %s" % ("✅" if stability_label else "❌"))
	print("UI PauseButton: %s" % ("✅" if pause_button else "❌"))
	print("UI NextButton: %s" % ("✅" if next_button else "❌"))
	print("UI InfoContainer: %s" % ("✅" if info_container else "❌"))

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
	# Esta parte depende de você ter uma classe PlayerAgent
	# Por enquanto, usaremos uma simulação simples.
	Globals.player_country = "Argentina"
	print("👤 Agente padrão / País do jogador configurado.")
	_ensure_country_data_exists()

func _ensure_country_data_exists() -> void:
	if not Globals.country_data.has(Globals.player_country):
		Globals.country_data[Globals.player_country] = {
			"money": 50000, "stability": 50, "gov_power": 50, "rebel_power": 20,
			"population": 45000000, "industry": 35, "defense": 40
		}

func _start_game_loop() -> void:
	timer.start()
	_update_all_ui()
	notification_system.show_notification("🎮 Jogo Iniciado", "Sistema carregado com sucesso!", NotificationSystem.NotificationType.SUCCESS)
	print("🎮 Jogo iniciado - Fase: %s" % GamePhase.keys()[current_phase])

# =====================================
#  LOOP PRINCIPAL DO JOGO
# =====================================
func _on_timer_timeout() -> void:
	if time_running:
		advance_month()

func advance_month() -> void:
	Globals.current_month += 1
	if Globals.current_month > 12:
		Globals.current_month = 1
		Globals.current_year += 1
		notification_system.show_notification("📅 Novo Ano", "Chegamos a %d!" % Globals.current_year, NotificationSystem.NotificationType.SUCCESS)

	# Lógica de fases
	match current_phase:
		GamePhase.POLITICAL_AGENT:
			_process_agent_phase()
		GamePhase.NATIONAL_LEADER:
			_process_leader_phase()
	
	month_advanced.emit(Globals.current_month, Globals.current_year)
	_update_all_ui()
	print("📅 %s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year])

func _process_agent_phase() -> void:
	if randf() < 0.2:
		notification_system.show_notification("📈 Atividade Política", "Agente ganhou +2 de apoio dos intelectuais.", NotificationSystem.NotificationType.INFO)

func _process_leader_phase() -> void:
	if Globals.has_method("simulate_monthly_changes"):
		Globals.simulate_monthly_changes()
	
	if randf() < 0.15:
		_trigger_random_national_event()

func _trigger_random_national_event() -> void:
	var countries = Globals.country_data.keys()
	if countries.is_empty(): return
		
	var random_country = countries[randi() % countries.size()]
	if Globals.has_method("apply_random_event"):
		var event = Globals.apply_random_event(random_country)
		notification_system.show_notification(
			"📰 " + event.get("name", "Evento"),
			"Aconteceu em " + random_country,
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
		notification_system.show_notification("⏰ Tempo", "Jogo retomado.", NotificationSystem.NotificationType.INFO)
	else:
		timer.stop()
		notification_system.show_notification("⏸️ Pausa", "Jogo pausado.", NotificationSystem.NotificationType.WARNING)

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
	# A chamada para o UI Manager, que agora existe e não dará erro.
	# ui_manager.update_phase_specific_ui(current_phase, player_agent)

func _update_date_display() -> void:
	if date_label:
		date_label.text = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]

func _update_resource_display() -> void:
	if money_label:
		var player_data = Globals.get_player_data()
		money_label.text = "$ %s" % _format_number(player_data.get("money", 0))

func _update_stability_display() -> void:
	if stability_label:
		var player_data = Globals.get_player_data()
		var stability_value = player_data.get("stability", 50)
		stability_label.text = "⚖️ Estabilidade: %d%%" % stability_value
		if stability_value > 70: stability_label.modulate = Color.GREEN
		elif stability_value > 40: stability_label.modulate = Color.YELLOW
		else: stability_label.modulate = Color.RED

# =====================================
#  SISTEMA DE INFORMAÇÕES E AÇÕES
# =====================================
func show_country_info(country_name: String) -> void:
	if not info_container: return
	for child in info_container.get_children():
		child.queue_free()
	
	var label = Label.new()
	label.text = "Exibindo informações de:\n%s" % country_name.to_upper()
	info_container.add_child(label)
	
	notification_system.show_notification("🏛️ " + country_name, "Visualizando informações", NotificationSystem.NotificationType.INFO)

# =====================================
#  INPUT E CONTROLES
# =====================================
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	match event.keycode:
		KEY_SPACE: _on_pause_pressed()
		KEY_RIGHT: _on_next_month_pressed()
		KEY_F4:
			notification_system.show_notification("🔧 DEBUG", "Isso é um teste de notificação de debug.", NotificationSystem.NotificationType.WARNING)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var country_name = _detect_country_click(event.global_position)
		if not country_name.is_empty():
			show_country_info(country_name)

func _detect_country_click(global_pos: Vector2) -> String:
	var map = get_node_or_null("NodeMapaSVG2D")
	if not map: return ""
	for child in map.get_children():
		if child is Polygon2D:
			var local_pos = child.to_local(global_pos)
			if Geometry2D.is_point_in_polygon(local_pos, child.polygon):
				return child.name
	return ""

# =====================================
#  UTILITÁRIOS
# =====================================
func _format_number(num: int) -> String:
	if num >= 1_000_000: return "%.1fM" % (float(num) / 1_000_000.0)
	elif num >= 1_000: return "%.1fK" % (float(num) / 1_000.0)
	else: return str(num)
