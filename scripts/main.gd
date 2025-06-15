# =====================================
#  MAIN.GD - SISTEMA PRINCIPAL INTEGRADO
#  Atualização para incluir PlayerAgent + Sistema existente
# =====================================
extends Node

# =====================================
#  CONSTANTES
# =====================================
const MONTH_NAMES := ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]

# =====================================
#  VARIÁVEIS DE ESTADO
# =====================================
var time_running := true
var game_started := false

# =====================================
#  COMPONENTES DO SISTEMA
# =====================================
var player_manager: PlayerManager
var character_creation: Control
var main_ui: Control

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
func _ready() -> void:
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
	player_manager = PlayerManager.new()
	player_manager.name = "PlayerManager"
	add_child(player_manager)
	
	# Conectar sinais
	player_manager.player_position_changed.connect(_on_player_position_changed)
	player_manager.player_gained_power.connect(_on_player_gained_power)
	player_manager.action_completed.connect(_on_action_completed)
	
	print("✅ PlayerManager configurado")

func _setup_character_creation():
	character_creation = preload("res://scenes/CharacterCreation.tscn").instantiate()
	# Se não tiver .tscn, criar dinamicamente:
	if character_creation == null:
		character_creation = CharacterCreation.new()
		character_creation.name = "CharacterCreation"
	
	add_child(character_creation)
	character_creation.character_created.connect(_on_character_created)
	character_creation.visible = false
	
	print("✅ CharacterCreation configurado")

# =====================================
#  DETECÇÃO DA UI EXISTENTE
# =====================================
func _detect_ui_structure() -> void:
	print("🔍 Detectando estrutura de UI...")
	
	# Buscar especificamente nos caminhos da sua estrutura
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
func _setup_timer() -> void:
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

func _setup_buttons() -> void:
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

func _on_character_created(agent: PlayerAgent):
	print("👤 Personagem criado: %s" % agent.name)
	
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
	
	print("🎮 Jogo iniciado! Fase: %d" % player_manager.get_current_phase())

# =====================================
#  CALLBACKS DOS SINAIS DO PLAYER MANAGER
# =====================================
func _on_player_position_changed(old_position: String, new_position: String):
	print("🎖️ %s avançou de %s para %s!" % [player_manager.get_player_agent().name, old_position, new_position])
	
	# Mostrar notificação
	_show_advancement_notification(old_position, new_position)
	
	# Atualizar UI
	_update_ui()

func _on_player_gained_power():
	print("🏛️ JOGADOR GANHOU O PODER!")
	
	# Transição visual
	_show_power_transition()
	
	# Atualizar UI para Fase 2
	_update_ui()

func _on_action_completed(action_name: String, success: bool):
	print("🎯 Ação '%s' %s" % [action_name, "bem-sucedida" if success else "falhou"])
	
	# Atualizar UI
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
func _on_auto_timer_timeout() -> void:
	if not game_started:
		return
	
	print("⏰ Timer timeout! time_running = ", time_running)
	if time_running:
		print("⏭️ Avançando mês automaticamente...")
		_advance_month()

func _on_pause_pressed() -> void:
	time_running = !time_running
	print("🎮 Pausar pressionado! time_running agora é: ", time_running)
	
	if pause_button:
		pause_button.text = "⏸ Pausar" if time_running else "▶️ Retomar"
	
	if timer:
		if time_running:
			timer.start()
		else:
			timer.stop()

func _on_next_month_pressed() -> void:
	if not game_started:
		return
	
	print("🎮 Próximo mês pressionado! time_running é: ", time_running)
	if not time_running:
		print("⏭️ Avançando mês manualmente...")
		_advance_month()

func _advance_month() -> void:
	# Avançar tempo global
	Globals.current_month += 1
	if Globals.current_month > 12:
		Globals.current_month = 1
		Globals.current_year += 1

	# Avançar PlayerAgent se existir
	if player_manager and player_manager.get_player_agent():
		player_manager.advance_month()

	# Simulação passiva de todos os países
	Globals.simulate_monthly_changes()
	
	# Chance de evento aleatório (15%)
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
	var event = Globals.apply_random_event(random_country)
	print("📰 EVENTO: %s em %s" % [event.get("name", "Evento"), random_country])

# =====================================
#  ATUALIZAÇÃO DA UI
# =====================================
func _update_ui() -> void:
	if not game_started:
		return
	
	# Determinar se mostrar dados do jogador ou do país
	var display_data: Dictionary
	
	if player_manager.get_current_phase() == 1:
		# Fase 1: Mostrar dados pessoais do agente
		var agent = player_manager.get_player_agent()
		if agent:
			display_data = {
				"money": agent.wealth * 100,  # Converter para escala apropriada
				"stability": agent.get_total_support() / 7,  # Converter para 0-100
				"is_agent": true,
				"agent_name": agent.name,
				"position": agent.current_position
			}
	else:
		# Fase 2: Mostrar dados do país
		display_data = Globals.get_player_data()
		display_data["is_agent"] = false
	
	# Atualizar data
	if date_label and date_label is Label:
		date_label.text = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
		date_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Atualizar dinheiro
	if money_label and money_label is Label:
		var money = display_data.get("money", 0)
		if display_data.get("is_agent", false):
			money_label.text = "💰 Recursos: %d" % money
		else:
			money_label.text = "$ %s" % _format_number(money)
		money_label.add_theme_color_override("font_color", Color.GREEN)

	# Atualizar estabilidade
	if stability_label and stability_label is Label:
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
func _update_map_colors() -> void:
	var map := get_node_or_null("NodeMapaSVG2D")
	if map == null:
		return
	
	for child in map.get_children():
		if child is Polygon2D:
			var country_name = child.name
			var country_data = Globals.get_country(country_name)
			
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
					if player_manager.get_current_phase() == 1:
						color = Color.CYAN.lightened(0.3)
				
				child.color = color

# =====================================
#  INFORMAÇÕES DO PAÍS
# =====================================
func _show_country_info(country_name: String) -> void:
	var country_data = Globals.get_country(country_name)
	if country_data.is_empty():
		print("❌ País não encontrado: ", country_name)
		return
	
	if info_container:
		_update_info_container(country_name, country_data)
	else:
		_print_country_info(country_name, country_data)

func _update_info_container(country_name: String, country_data: Dictionary) -> void:
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
		if player_manager.get_current_phase() == 1:
			var agent = player_manager.get_player_agent()
			player_indicator.text = "👤 %s (%s)" % [agent.name if agent else "SEU AGENTE", agent.current_position if agent else ""]
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
	if player_manager.get_current_phase() == 2:
		var action_button = Button.new()
		if country_name == Globals.player_country:
			action_button.text = "👑 Governar"
			action_button.pressed.connect(_on_govern_country.bind(country_name))
		else:
			action_button.text = "🤝 Negociar"
			action_button.pressed.connect(_on_trade_with_country.bind(country_name))
		
		action_button.custom_minimum_size = Vector2(200, 40)
		info_container.add_child(action_button)

func _print_country_info(country_name: String, country_data: Dictionary) -> void:
	print("\n🏛️ === %s ===" % country_name.to_upper())
	print("💰 Dinheiro: $%s" % _format_number(country_data.get("money", 0)))
	print("⚖️ Estabilidade: %d%%" % country_data.get("stability", 50))
	print("🏛️ Gov. Power: %d%%" % country_data.get("gov_power", 50))
	print("🔥 Rebelião: %d%%" % country_data.get("rebel_power", 50))
	print("================\n")

# =====================================
#  AÇÕES DO JOGADOR (FASE 2)
# =====================================
func _on_govern_country(country_name: String) -> void:
	print("👑 Governando: ", country_name)
	Globals.adjust_country_value(country_name, "gov_power", randi_range(3, 8))
	Globals.adjust_country_value(country_name, "money", -500)
	_update_ui()
	_show_country_info(country_name)

func _on_trade_with_country(country_name: String) -> void:
	print("🤝 Negociando com: ", country_name)
	var trade_bonus = randi_range(200, 800)
	Globals.adjust_country_value(Globals.player_country, "money", trade_bonus)
	Globals.adjust_relation(Globals.player_country, country_name, randi_range(2, 8))
	_update_ui()
	_show_country_info(country_name)

# =====================================
#  INPUT GLOBAL
# =====================================
func _input(event: InputEvent) -> void:
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
					player_manager.debug_advance_to_president()
				KEY_F2:
					print(player_manager.get_debug_info())
				KEY_F3:
					_show_character_creation()

func _detect_polygon_click(global_pos: Vector2) -> String:
	var map := get_node_or_null("NodeMapaSVG2D")
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

# =====================================
#  GETTERS (COMPATIBILIDADE)
# =====================================
func get_current_date() -> String:
	return "%s/%d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]

func get_current_money() -> int:
	if player_manager.get_current_phase() == 1:
		var agent = player_manager.get_player_agent()
		return agent.wealth * 100 if agent else 0
	else:
		return Globals.get_country_value(Globals.player_country, "money", 0)

func get_current_month() -> int:
	return Globals.current_month

func get_current_year() -> int:
	return Globals.current_year

func is_time_running() -> bool:
	return time_running

func get_player_manager() -> PlayerManager:
	return player_manager

func get_game_phase() -> int:
	return player_manager.get_current_phase() if player_manager else 1

# =====================================
#  SAVE/LOAD DO JOGO COMPLETO
# =====================================
func save_game() -> Dictionary:
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"global_data": {
			"current_month": Globals.current_month,
			"current_year": Globals.current_year,
			"player_country": Globals.player_country,
			"country_data": Globals.country_data,
			"relations": Globals.relations if Globals.has_method("get_relations") else {}
		},
		"game_state": {
			"time_running": time_running,
			"game_started": game_started
		},
		"player_data": player_manager.save_player_data() if player_manager else {}
	}
	
	print("💾 Jogo salvo")
	return save_data

func load_game(save_data: Dictionary) -> bool:
        if not save_data.has("version"):
                print("❌ Arquivo de save inválido")
                return false

        # Restaurar dados globais
        var global_data = save_data.get("global_data", {})
        Globals.current_month = global_data.get("current_month", 1)
        Globals.current_year = global_data.get("current_year", 1973)
        Globals.player_country = global_data.get("player_country", "")
        Globals.country_data = global_data.get("country_data", {})

        # Restaurar estado do jogo
        var game_state = save_data.get("game_state", {})
        time_running = game_state.get("time_running", true)
        game_started = game_state.get("game_started", false)

        # Restaurar dados do jogador
        var player_data = save_data.get("player_data", {})
        if not player_data.is_empty() and player_manager:
                player_manager.load_player_data(player_data)

        # Atualizar UI
        _update_ui()
        _update_map_colors()

        print("📁 Jogo carregado com sucesso")
        return true

# =====================================
#  SISTEMA DE CONQUISTAS/ACHIEVEMENTS
# =====================================
func check_achievements():
	if not player_manager or not player_manager.get_player_agent():
		return
	
	var agent = player_manager.get_player_agent()
	
	# Conquista: Primeiro cargo político
	if agent.current_position == "Ativista" and not _has_achievement("first_position"):
		_unlock_achievement("first_position", "🎖️ Primeiro Passo", "Tornou-se um ativista político")
	
	# Conquista: Presidente jovem
	if agent.current_position == "Presidente" and agent.age < 35 and not _has_achievement("young_president"):
		_unlock_achievement("young_president", "👑 Jovem Líder", "Tornou-se presidente antes dos 35 anos")
	
	# Conquista: Sobrevivente da Operação Condor
	if agent.condor_target_level > 80 and not agent.is_imprisoned and not _has_achievement("condor_survivor"):
		_unlock_achievement("condor_survivor", "⚡ Sobrevivente", "Escapou da Operação Condor")
	
	# Conquista: Apoio total máximo
	if agent.get_total_support() >= 600 and not _has_achievement("mass_support"):
		_unlock_achievement("mass_support", "🌟 Carismático", "Conquistou apoio massivo de todos os grupos")

var unlocked_achievements: Array[String] = []

func _has_achievement(achievement_id: String) -> bool:
	return achievement_id in unlocked_achievements

func _unlock_achievement(achievement_id: String, title: String, description: String):
	unlocked_achievements.append(achievement_id)
	_show_achievement_notification(title, description)

func _show_achievement_notification(title: String, description: String):
	var dialog = AcceptDialog.new()
	dialog.title = "🏆 CONQUISTA DESBLOQUEADA!"
	dialog.dialog_text = "%s\n\n%s" % [title, description]
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

# =====================================
#  SISTEMA DE TUTORIAL CONTEXTUAL
# =====================================
var tutorial_shown: Array[String] = []

func show_tutorial_hint(hint_id: String, title: String, message: String):
	if hint_id in tutorial_shown:
		return
	
	tutorial_shown.append(hint_id)
	
	var dialog = AcceptDialog.new()
	dialog.title = "💡 " + title
	dialog.dialog_text = message
	dialog.custom_minimum_size = Vector2(400, 200)
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func check_tutorial_triggers():
	if not player_manager or not player_manager.get_player_agent():
		return
	
	var agent = player_manager.get_player_agent()
	
	# Tutorial: Primeiro mês
	if Globals.current_year == 1973 and Globals.current_month == 1:
		show_tutorial_hint("first_month", "Bem-vindo ao Cone Sul", 
			"Você está em 1973, no auge da Guerra Fria. Sua jornada política começa agora!\n\n" +
			"• Execute ações para ganhar apoio\n" +
			"• Cuidado com os riscos políticos\n" +
			"• Avance de posição até chegar à presidência")
	
	# Tutorial: Primeira ação
	if agent.political_experience >= 5 and not "first_action" in tutorial_shown:
		show_tutorial_hint("first_action", "Ganhando Experiência", 
			"Ótimo! Você está ganhando experiência política.\n\n" +
			"Continue executando ações para:\n" +
			"• Aumentar seus atributos\n" +
			"• Ganhar apoio dos grupos\n" +
			"• Construir sua rede de contatos")
	
	# Tutorial: Alto risco Condor
	if agent.condor_target_level > 30 and not "condor_warning" in tutorial_shown:
		show_tutorial_hint("condor_warning", "⚠️ Ameaça da Operação Condor", 
			"Cuidado! Você está chamando atenção das forças de segurança.\n\n" +
			"A Operação Condor pode:\n" +
			"• Te prender ou exilar\n" +
			"• Eliminar fisicamente\n" +
			"• Reduza atividades de alto risco por um tempo")

# =====================================
#  EVENTOS HISTÓRICOS ESPECÍFICOS
# =====================================
func trigger_historical_events():
	var current_date = "%d-%02d" % [Globals.current_year, Globals.current_month]
	
	match current_date:
		"1973-09":  # Golpe no Chile
			if Globals.player_country == "Chile":
				_handle_chile_coup_1973()
			else:
				_show_news_event("Golpe no Chile", "Augusto Pinochet toma o poder no Chile. Salvador Allende foi morto.")
		
		"1976-03":  # Golpe na Argentina
			if Globals.player_country == "Argentina":
				_handle_argentina_coup_1976()
			else:
				_show_news_event("Golpe na Argentina", "Junta militar toma o poder na Argentina. Início do 'Processo de Reorganização Nacional'.")
		
		"1982-04":  # Guerra das Malvinas
			if Globals.player_country == "Argentina":
				_handle_malvinas_war()
			else:
				_show_news_event("Guerra das Malvinas", "Argentina invade as Ilhas Malvinas. Conflito com o Reino Unido.")

func _handle_chile_coup_1973():
	var dialog = ConfirmationDialog.new()
	dialog.title = "🎖️ Golpe Militar no Chile - 11 de Setembro de 1973"
	dialog.dialog_text = "As Forças Armadas estão se movendo para derrubar o governo Allende. Como você reage?\n\n" +
		"• APOIAR: Ganhe influência militar, mas perca apoio popular\n" +
		"• RESISTIR: Mantenha princípios, mas corra risco de prisão"
	
	dialog.get_ok_button().text = "Apoiar Golpe"
	dialog.get_cancel_button().text = "Resistir"
	
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(_support_chile_coup)
	dialog.canceled.connect(_resist_chile_coup)

func _support_chile_coup():
	var agent = player_manager.get_player_agent()
	if agent:
		agent.support["military"] += 20
		agent.support["workers"] -= 15
		agent.support["students"] -= 10
		agent.usa_influence += 15
		agent.major_events.append("Apoiou o golpe de Pinochet (1973)")
	print("📰 Você apoiou o golpe militar no Chile")

func _resist_chile_coup():
	var agent = player_manager.get_player_agent()
	if agent:
		agent.support["workers"] += 10
		agent.support["students"] += 15
		agent.condor_target_level += 20
		agent.ussr_influence += 10
		agent.major_events.append("Resistiu ao golpe de Pinochet (1973)")
	print("📰 Você resistiu ao golpe militar no Chile")

func _handle_argentina_coup_1976():
	# Implementar evento específico da Argentina
	pass

func _handle_malvinas_war():
	# Implementar Guerra das Malvinas
	pass

func _show_news_event(title: String, description: String):
	var dialog = AcceptDialog.new()
	dialog.title = "📰 " + title
	dialog.dialog_text = description
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

# =====================================
#  SISTEMA DE ESTATÍSTICAS
# =====================================
func get_game_statistics() -> Dictionary:
	var agent = player_manager.get_player_agent() if player_manager else null
	
	return {
		"months_played": (Globals.current_year - 1973) * 12 + Globals.current_month,
		"current_position": agent.current_position if agent else "N/A",
		"total_support": agent.get_total_support() if agent else 0,
		"major_events": agent.major_events.size() if agent else 0,
		"countries_affected": Globals.country_data.size(),
		"phase": player_manager.get_current_phase() if player_manager else 1,
		"achievements": unlocked_achievements.size()
	}

func show_statistics():
	var stats = get_game_statistics()
	var dialog = AcceptDialog.new()
	dialog.title = "📊 Estatísticas do Jogo"
	
	var text = "=== ESTATÍSTICAS ===\n\n"
	text += "🗓️ Meses Jogados: %d\n" % stats["months_played"]
	text += "🎖️ Posição Atual: %s\n" % stats["current_position"]
	text += "👥 Apoio Total: %d/700\n" % stats["total_support"]
	text += "📰 Eventos Importantes: %d\n" % stats["major_events"]
	text += "🌍 Países no Jogo: %d\n" % stats["countries_affected"]
	text += "🎮 Fase Atual: %d\n" % stats["phase"]
	text += "🏆 Conquistas: %d\n" % stats["achievements"]
	
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

# =====================================
#  MAIN GAME LOOP UPDATE
# =====================================
func _process(_delta):
	if game_started:
		# Verificar conquistas periodicamente
		if Engine.get_process_frames() % 300 == 0:  # A cada 5 segundos
			check_achievements()
		
		# Verificar tutoriais
		if Engine.get_process_frames() % 180 == 0:  # A cada 3 segundos
			check_tutorial_triggers()
		
		# Verificar eventos históricos
		if Engine.get_process_frames() % 900 == 0:  # A cada 15 segundos
			trigger_historical_events()

# =====================================
#  DEBUGGING E DESENVOLVIMENTO
# =====================================
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	
	if not player_manager:
		warnings.append("PlayerManager não encontrado")
	
	if not character_creation:
		warnings.append("CharacterCreation não configurado")
	
	return warnings

# Para facilitar o desenvolvimento
func quick_start_game(country: String = "Argentina", preset: String = "intelectual_democrata"):
	if OS.is_debug_build():
		var agent = PlayerAgent.create_preset_character(preset, country)
		_on_character_created(agent)
		print("🔧 DEBUG: Jogo iniciado rapidamente com %s" % agent.name)
