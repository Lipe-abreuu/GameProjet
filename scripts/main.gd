# =====================================
#  MAIN.GD - SISTEMA PRINCIPAL 
#  Versão que carrega scripts dinamicamente
# =====================================
extends Node

# =====================================
#  CONSTANTES
# =====================================
const MONTH_NAMES = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]

# =====================================
#  VARIÁVEIS DE ESTADO
# =====================================
var time_running = true
var game_started = false

# Scripts carregados dinamicamente
var PlayerManagerScript = preload("res://scripts/PlayerManager.gd")
var CharacterCreationScript = preload("res://scripts/CharacterCreation.gd")
var PlayerAgentScript = preload("res://scripts/PlayerAgent.gd")

# =====================================
#  COMPONENTES DO SISTEMA
# =====================================
var player_manager
var character_creation
var current_player_agent

# =====================================
#  NÓS DA UI - DETECTADOS DINAMICAMENTE
# =====================================
var date_label: Label
var money_label: Label
var stability_label: Label
var pause_button: Button
var next_button: Button
var info_container: VBoxContainer
var timer: Timer

# =====================================
#  READY
# =====================================
func _ready():
	print("=== INICIANDO JOGO INTEGRADO ===")
	
	# Aguardar um frame
	await get_tree().process_frame
	
	# Inicializar componentes
	_setup_player_manager()
	_setup_character_creation()
	
	# Detectar estrutura existente
	_detect_ui_structure()
	
	# Configurar timer
	_setup_timer()
	
	# Configurar botões se encontrados
	_setup_buttons()
	
	# Mostrar criação de personagem
	_show_character_creation()
	
	print("=== SISTEMA INTEGRADO PRONTO ===")

# =====================================
#  SETUP DOS COMPONENTES
# =====================================
func _setup_player_manager():
	player_manager = PlayerManagerScript.new()
	player_manager.name = "PlayerManager"
	add_child(player_manager)
	
	# Conectar sinais
	player_manager.player_position_changed.connect(_on_player_position_changed)
	player_manager.player_gained_power.connect(_on_player_gained_power)
	player_manager.action_completed.connect(_on_action_completed)
	
	print("✅ PlayerManager configurado")

func _setup_character_creation():
	character_creation = CharacterCreationScript.new()
	character_creation.name = "CharacterCreation"
	add_child(character_creation)
	character_creation.character_created.connect(_on_character_created)
	character_creation.visible = false
	
	print("✅ CharacterCreation configurado")

# =====================================
#  DETECÇÃO DA UI EXISTENTE
# =====================================
func _detect_ui_structure():
	print("🔍 Detectando estrutura de UI...")
	
	# Buscar nos caminhos da sua estrutura
	date_label = get_node_or_null("TopBar/HBoxContainer/DateLabel")
	money_label = get_node_or_null("TopBar/HBoxContainer/MoneyLabel")  
	stability_label = get_node_or_null("TopBar/HBoxContainer/StabilityLabel")
	pause_button = get_node_or_null("BottomBar/HBoxContainer/PauseButton")
	next_button = get_node_or_null("BottomBar/HBoxContainer/NextButton")
	info_container = get_node_or_null("Sidepanel/InfoContainer")
	
	# Se não encontrou, buscar em CanvasLayer
	if not date_label:
		date_label = get_node_or_null("CanvasLayer/TopBar/HBoxContainer/DateLabel")
	if not money_label:
		money_label = get_node_or_null("CanvasLayer/TopBar/HBoxContainer/MoneyLabel")
	if not stability_label:
		stability_label = get_node_or_null("CanvasLayer/TopBar/HBoxContainer/StabilityLabel")
	if not pause_button:
		pause_button = get_node_or_null("CanvasLayer/BottomBar/HBoxContainer/PauseButton")
	if not next_button:
		next_button = get_node_or_null("CanvasLayer/BottomBar/HBoxContainer/NextButton")
	if not info_container:
		info_container = get_node_or_null("CanvasLayer/Sidepanel/InfoContainer")
	
	# Resultados
	print("✅ DateLabel: ", date_label != null)
	print("✅ MoneyLabel: ", money_label != null)
	print("✅ StabilityLabel: ", stability_label != null)
	print("✅ PauseButton: ", pause_button != null)
	print("✅ NextButton: ", next_button != null)
	print("✅ InfoContainer: ", info_container != null)

# =====================================
#  CONFIGURAR TIMER E BOTÕES
# =====================================
func _setup_timer():
	timer = get_node_or_null("AutoTimer")
	if timer == null:
		timer = get_node_or_null("CanvasLayer/AutoTimer")
	
	if timer == null:
		print("⚠️ AutoTimer não encontrado, criando um novo...")
		timer = Timer.new()
		timer.name = "GameTimer"
		add_child(timer)
	else:
		print("✅ Timer encontrado: ", timer.name)
	
	timer.wait_time = 3.0
	if not timer.timeout.is_connected(_on_auto_timer_timeout):
		timer.timeout.connect(_on_auto_timer_timeout)

func _setup_buttons():
	if pause_button:
		if pause_button.pressed.is_connected(_on_pause_pressed):
			pause_button.pressed.disconnect(_on_pause_pressed)
		pause_button.pressed.connect(_on_pause_pressed)
		pause_button.text = "⏸ Pausar"
		print("✅ Pause button configurado")
	
	if next_button:
		if next_button.pressed.is_connected(_on_next_month_pressed):
			next_button.pressed.disconnect(_on_next_month_pressed)
		next_button.pressed.connect(_on_next_month_pressed)
		next_button.text = "▶️ Próximo Mês"
		print("✅ Next button configurado")

# =====================================
#  CRIAÇÃO DE PERSONAGEM
# =====================================
func _show_character_creation():
	character_creation.visible = true
	character_creation.show_creation_screen()
	
	# Pausar o jogo até personagem ser criado
	time_running = false
	if timer:
		timer.stop()

func _on_character_created(agent):
	print("👤 Personagem criado: %s" % agent.name)
	current_player_agent = agent
	
	# Configurar PlayerManager
	player_manager.create_player_agent(agent)
	
	# Esconder criação de personagem
	character_creation.visible = false
	
	# Configurar país do jogador
	Globals.player_country = agent.country
	
	# Iniciar o jogo
	_start_game()

func _start_game():
	game_started = true
	time_running = true
	
	# Iniciar timer
	if timer:
		timer.start()
	
	# Atualizar UI
	_update_ui()
	_update_map_colors()
	
	print("🎮 Jogo iniciado! Fase: %d" % _get_current_phase())

# =====================================
#  CALLBACKS DOS SINAIS DO PLAYER MANAGER
# =====================================
func _on_player_position_changed(old_position: String, new_position: String):
	print("🎖️ Avançou de %s para %s!" % [old_position, new_position])
	_show_advancement_notification(old_position, new_position)
	_update_ui()

func _on_player_gained_power():
	print("🏛️ JOGADOR GANHOU O PODER!")
	_show_power_transition()
	_update_ui()

func _on_action_completed(action_name: String, success: bool):
	print("🎯 Ação '%s' %s" % [action_name, "bem-sucedida" if success else "falhou"])
	_update_ui()

func _show_advancement_notification(old_pos: String, new_pos: String):
	var dialog = AcceptDialog.new()
	dialog.title = "🎖️ Avanço Político!"
	dialog.dialog_text = "Parabéns! Você avançou de %s para %s!" % [old_pos, new_pos]
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func _show_power_transition():
	var dialog = AcceptDialog.new()
	dialog.title = "🏛️ PODER CONQUISTADO!"
	dialog.dialog_text = "Você conquistou a presidência! Agora controle seu país na turbulenta década de 1970."
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

# =====================================
#  CICLO DE TEMPO
# =====================================
func _on_auto_timer_timeout():
	if not game_started:
		return
	
	print("⏰ Timer timeout! time_running = ", time_running)
	if time_running:
		print("⏭️ Avançando mês automaticamente...")
		_advance_month()

func _on_pause_pressed():
	time_running = !time_running
	print("🎮 Pausar pressionado! time_running agora é: ", time_running)
	
	if pause_button:
		pause_button.text = "⏸ Pausar" if time_running else "▶️ Retomar"
	
	if timer:
		if time_running:
			timer.start()
		else:
			timer.stop()

func _on_next_month_pressed():
	if not game_started:
		return
	
	print("🎮 Próximo mês pressionado!")
	if not time_running:
		print("⏭️ Avançando mês manualmente...")
		_advance_month()

func _advance_month():
	# Avançar tempo global
	Globals.current_month += 1
	if Globals.current_month > 12:
		Globals.current_month = 1
		Globals.current_year += 1

	# Avançar PlayerAgent se existir
	if player_manager and player_manager.has_method("advance_month"):
		player_manager.advance_month()

	# Simulação passiva de todos os países
	if Globals.has_method("simulate_monthly_changes"):
		Globals.simulate_monthly_changes()
	
	# Chance de evento aleatório
	if randi() % 100 < 15:
		_trigger_random_event()

	# Atualizar UI
	_update_ui()
	_update_map_colors()
	
	print("📅 %s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year])

func _trigger_random_event():
	var countries = Globals.country_data.keys()
	if countries.size() == 0:
		return
		
	var random_country = countries[randi() % countries.size()]
	var event = {}
	if Globals.has_method("apply_random_event"):
		event = Globals.apply_random_event(random_country)
	print("📰 EVENTO: %s em %s" % [event.get("name", "Evento"), random_country])

# =====================================
#  ATUALIZAÇÃO DA UI
# =====================================
func _update_ui():
	if not game_started:
		return
	
	# Determinar dados a mostrar
	var display_data = {}
	
	if _get_current_phase() == 1:
		# Fase 1: Dados pessoais do agente
		if current_player_agent:
			display_data = {
				"money": current_player_agent.wealth * 100,
				"stability": current_player_agent.get_total_support() / 7,
				"is_agent": true,
				"agent_name": current_player_agent.name,
				"position": current_player_agent.current_position
			}
	else:
		# Fase 2: Dados do país
		display_data = Globals.get_player_data()
		display_data["is_agent"] = false
	
	# Atualizar data
	if date_label:
		date_label.text = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
		date_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Atualizar dinheiro
	if money_label:
		var money = display_data.get("money", 0)
		if display_data.get("is_agent", false):
			money_label.text = "💰 Recursos: %d" % money
		else:
			money_label.text = "$ %s" % _format_number(money)
		money_label.add_theme_color_override("font_color", Color.GREEN)

	# Atualizar estabilidade
	if stability_label:
		var stability = display_data.get("stability", 50)
		if display_data.get("is_agent", false):
			stability_label.text = "📊 Apoio: %d%%" % int(stability)
		else:
			stability_label.text = "Estabilidade: %d%%" % stability
		
		var color = Color.GREEN if stability > 70 else (Color.YELLOW if stability > 40 else Color.RED)
		stability_label.add_theme_color_override("font_color", color)

# =====================================
#  MAPA E VISUALIZAÇÃO
# =====================================
func _update_map_colors():
	var map = get_node_or_null("NodeMapaSVG2D")
	if map == null:
		return
	
	for child in map.get_children():
		if child is Polygon2D:
			var country_name = child.name
			var country_data = {}
			if Globals.has_method("get_country"):
				country_data = Globals.get_country(country_name)
			
			if not country_data.is_empty():
				var stability = country_data.get("stability", 50)
				var gov_power = country_data.get("gov_power", 50)
				
				# Colorir baseado na estabilidade
				var color: Color
				if stability < 25:
					color = Color.RED.darkened(0.2)
				elif stability < 50:
					color = Color.ORANGE.darkened(0.1)
				elif stability < 75:
					color = Color.YELLOW.darkened(0.1)
				else:
					color = Color.GREEN.darkened(0.1)
				
				# Opacidade baseada no poder governamental
				color.a = 0.5 + (gov_power / 200.0)
				
				# Destacar país do jogador
				if country_name == Globals.player_country:
					color = color.lightened(0.4)
					
					# Na Fase 1, adicionar borda especial
					if _get_current_phase() == 1:
						color = Color.CYAN.lightened(0.3)
				
				child.color = color

# =====================================
#  INFORMAÇÕES DO PAÍS
# =====================================
func _show_country_info(country_name: String):
	var country_data = {}
	if Globals.has_method("get_country"):
		country_data = Globals.get_country(country_name)
	
	if country_data.is_empty():
		print("❌ País não encontrado: ", country_name)
		return
	
	if info_container:
		_update_info_container(country_name, country_data)
	else:
		_print_country_info(country_name, country_data)

func _update_info_container(country_name: String, country_data: Dictionary):
	# Limpar container existente
	for child in info_container.get_children():
		child.queue_free()
	
	# Título
	var title = Label.new()
	title.text = "🏛️ " + country_name.to_upper()
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(title)
	
	# Indicador especial se for país do jogador
	if country_name == Globals.player_country:
		var player_indicator = Label.new()
		if _get_current_phase() == 1:
			player_indicator.text = "👤 %s (%s)" % [current_player_agent.name if current_player_agent else "SEU AGENTE", current_player_agent.current_position if current_player_agent else ""]
		else:
			player_indicator.text = "👑 SEU PAÍS"
		player_indicator.add_theme_color_override("font_color", Color.CYAN)
		player_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_container.add_child(player_indicator)
	
	# Dados principais
	var data_lines = [
		"💰 Dinheiro: $%s" % _format_number(country_data.get("money", 0)),
		"⚖️ Estabilidade: %d%%" % country_data.get("stability", 50),
		"🏛️ Gov. Power: %d%%" % country_data.get("gov_power", 50),
		"🔥 Rebelião: %d%%" % country_data.get("rebel_power", 50),
		"👥 População: %s" % _format_number(country_data.get("population", 0)),
		"🏭 Indústria: %d%%" % country_data.get("industry", 0),
		"🛡️ Defesa: %d%%" % country_data.get("defense", 0)
	]
	
	for line in data_lines:
		var label = Label.new()
		label.text = line
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.WHITE)
		info_container.add_child(label)
	
	# Botão de ação (apenas na Fase 2)
	if _get_current_phase() == 2:
		var action_button = Button.new()
		if country_name == Globals.player_country:
			action_button.text = "👑 Governar"
			action_button.pressed.connect(_on_govern_country.bind(country_name))
		else:
			action_button.text = "🤝 Negociar"
			action_button.pressed.connect(_on_trade_with_country.bind(country_name))
		
		action_button.custom_minimum_size = Vector2(200, 40)
		info_container.add_child(action_button)

func _print_country_info(country_name: String, country_data: Dictionary):
	print("\n🏛️ === %s ===" % country_name.to_upper())
	print("💰 Dinheiro: $%s" % _format_number(country_data.get("money", 0)))
	print("⚖️ Estabilidade: %d%%" % country_data.get("stability", 50))
	print("🏛️ Gov. Power: %d%%" % country_data.get("gov_power", 50))
	print("🔥 Rebelião: %d%%" % country_data.get("rebel_power", 50))
	print("================\n")

# =====================================
#  AÇÕES DO JOGADOR (FASE 2)
# =====================================
func _on_govern_country(country_name: String):
	print("👑 Governando: ", country_name)
	if Globals.has_method("adjust_country_value"):
		Globals.adjust_country_value(country_name, "gov_power", randi_range(3, 8))
		Globals.adjust_country_value(country_name, "money", -500)
	_update_ui()
	_show_country_info(country_name)

func _on_trade_with_country(country_name: String):
	print("🤝 Negociando com: ", country_name)
	var trade_bonus = randi_range(200, 800)
	if Globals.has_method("adjust_country_value"):
		Globals.adjust_country_value(Globals.player_country, "money", trade_bonus)
	if Globals.has_method("adjust_relation"):
		Globals.adjust_relation(Globals.player_country, country_name, randi_range(2, 8))
	_update_ui()
	_show_country_info(country_name)

# =====================================
#  INPUT GLOBAL
# =====================================
func _input(event: InputEvent):
	if not game_started:
		return
	
	if event.is_action_pressed("ui_accept"):  # Espaço
		_on_pause_pressed()
	elif event.is_action_pressed("ui_right"):  # Seta direita
		_on_next_month_pressed()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var country_name = _detect_polygon_click(event.global_position)
		if country_name != "":
			print("🖱️ Clique detectado em: ", country_name)
			_show_country_info(country_name)
	
	# Teclas de debug
	if OS.is_debug_build():
		if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_F1:
					_debug_advance_to_president()
				KEY_F2:
					_debug_print_info()
				KEY_F3:
					_show_character_creation()

func _detect_polygon_click(global_pos: Vector2) -> String:
	var map = get_node_or_null("NodeMapaSVG2D")
	if map == null:
		return ""
	
	for child in map.get_children():
		if child is Polygon2D:
			var local_pos = child.to_local(global_pos)
			if Geometry2D.is_point_in_polygon(local_pos, child.polygon):
				return child.name
	
	return ""

# =====================================
#  FUNÇÕES UTILITÁRIAS
# =====================================
func _format_number(num: int) -> String:
	if num >= 1_000_000:
		return "%.1fM" % (num / 1_000_000.0)
	elif num >= 1_000:
		return "%.1fK" % (num / 1_000.0)
	else:
		return str(num)

func _get_current_phase() -> int:
	if player_manager and player_manager.has_method("get_current_phase"):
		return player_manager.get_current_phase()
	return 1

# =====================================
#  GETTERS (COMPATIBILIDADE)
# =====================================
func get_current_date() -> String:
	return "%s/%d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]

func get_current_money() -> int:
	if _get_current_phase() == 1:
		return current_player_agent.wealth * 100 if current_player_agent else 0
	else:
		if Globals.has_method("get_country_value"):
			return Globals.get_country_value(Globals.player_country, "money", 0)
		return 0

func get_current_month() -> int:
	return Globals.current_month

func get_current_year() -> int:
	return Globals.current_year

func is_time_running() -> bool:
	return time_running

# =====================================
#  DEBUG E DESENVOLVIMENTO
# =====================================
func _debug_advance_to_president():
	if player_manager and player_manager.has_method("debug_advance_to_president"):
		player_manager.debug_advance_to_president()

func _debug_print_info():
	if player_manager and player_manager.has_method("get_debug_info"):
		print(player_manager.get_debug_info())
	elif current_player_agent:
		print("Agente: %s - Posição: %s" % [current_player_agent.name, current_player_agent.current_position])

func quick_start_game(country: String = "Argentina", preset: String = "intelectual_democrata"):
	if OS.is_debug_build():
		var agent = PlayerAgentScript.create_preset_character(preset, country)
		_on_character_created(agent)
		print("🔧 DEBUG: Jogo iniciado rapidamente com %s" % agent.name)
