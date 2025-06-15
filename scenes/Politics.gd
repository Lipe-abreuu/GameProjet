extends Node

# =====================================
#  CONSTANTES
# =====================================
const MONTH_NAMES := ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]

# =====================================
#  VARIÁVEIS DE ESTADO
# =====================================
var time_running := true

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
	print("=== INICIANDO JOGO COM ESTRUTURA EXISTENTE ===")
	
	# Aguardar um frame
	await get_tree().process_frame
	
	# Detectar estrutura existente
	_detect_existing_ui()
	
	# Configurar timer
	_setup_timer()
	
	# Configurar botões se encontrados
	_setup_buttons()
	
	# Atualizar UI
	_update_ui()
	
	# Mostrar estrutura encontrada
	_debug_show_structure()
	
	print("=== JOGO INICIADO ===")

# =====================================
#  DETECTAR ESTRUTURA EXISTENTE
# =====================================
func _detect_existing_ui() -> void:
	print("🔍 Detectando estrutura de UI existente...")
	
	# Buscar por nomes comuns de labels de data
	var date_candidates = ["DateLabel", "Data", "Date", "TimeLabel", "MesLabel"]
	for candidate in date_candidates:
		date_label = _find_node_recursive(self, candidate)
		if date_label:
			print("✅ Data label encontrado: ", candidate)
			break
	
	# Buscar por nomes comuns de labels de dinheiro
	var money_candidates = ["MoneyLabel", "Money", "Dinheiro", "CashLabel", "GoldLabel"]
	for candidate in money_candidates:
		money_label = _find_node_recursive(self, candidate)
		if money_label:
			print("✅ Money label encontrado: ", candidate)
			break
	
	# Buscar por nomes comuns de labels de estabilidade
	var stability_candidates = ["StabilityLabel", "Stability", "Estabilidade", "StatusLabel"]
	for candidate in stability_candidates:
		stability_label = _find_node_recursive(self, candidate)
		if stability_label:
			print("✅ Stability label encontrado: ", candidate)
			break
	
	# Buscar por botões
	var pause_candidates = ["PauseButton", "Pause", "Pausar", "PlayButton"]
	for candidate in pause_candidates:
		pause_button = _find_node_recursive(self, candidate)
		if pause_button:
			print("✅ Pause button encontrado: ", candidate)
			break
	
	var next_candidates = ["NextButton", "Next", "Proximo", "AdvanceButton", "NextMonth"]
	for candidate in next_candidates:
		next_button = _find_node_recursive(self, candidate)
		if next_button:
			print("✅ Next button encontrado: ", candidate)
			break
	
	# Buscar por containers de informação
	var info_candidates = ["InfoContainer", "Info", "SidePanel", "CountryInfo", "Details"]
	for candidate in info_candidates:
		info_container = _find_node_recursive(self, candidate)
		if info_container:
			print("✅ Info container encontrado: ", candidate)
			break

# Função recursiva para buscar nós
func _find_node_recursive(node: Node, target_name: String) -> Node:
	# Verificar se o nome contém o target (busca parcial)
	if node.name.to_lower().contains(target_name.to_lower()):
		return node
	
	# Buscar nos filhos
	for child in node.get_children():
		var result = _find_node_recursive(child, target_name)
		if result != null:
			return result
	
	return null

# =====================================
#  DEBUG - MOSTRAR ESTRUTURA
# =====================================
func _debug_show_structure() -> void:
	print("\n📋 ESTRUTURA DETECTADA:")
	print("  Date Label: ", date_label.name if date_label else "❌ NÃO ENCONTRADO")
	print("  Money Label: ", money_label.name if money_label else "❌ NÃO ENCONTRADO")
	print("  Stability Label: ", stability_label.name if stability_label else "❌ NÃO ENCONTRADO")
	print("  Pause Button: ", pause_button.name if pause_button else "❌ NÃO ENCONTRADO")
	print("  Next Button: ", next_button.name if next_button else "❌ NÃO ENCONTRADO")
	print("  Info Container: ", info_container.name if info_container else "❌ NÃO ENCONTRADO")
	
	print("\n🌳 ÁRVORE DE NÓSDA CENA:")
	_print_tree_structure(self, 0)

# Função para imprimir árvore de nós
func _print_tree_structure(node: Node, depth: int) -> void:
	var indent = "  ".repeat(depth)
	var type_info = " (%s)" % node.get_class()
	print("%s%s%s" % [indent, node.name, type_info])
	
	for child in node.get_children():
		_print_tree_structure(child, depth + 1)

# =====================================
#  CONFIGURAR TIMER
# =====================================
func _setup_timer() -> void:
	# Buscar timer existente
	timer = _find_node_recursive(self, "Timer")
	if timer == null:
		timer = _find_node_recursive(self, "AutoTimer")
	
	if timer == null:
		print("⚠️ Timer não encontrado, criando um novo...")
		timer = Timer.new()
		timer.name = "GameTimer"
		add_child(timer)
	else:
		print("✅ Timer encontrado: ", timer.name)
	
	timer.wait_time = 3.0
	if not timer.timeout.is_connected(_on_auto_timer_timeout):
		timer.timeout.connect(_on_auto_timer_timeout)
	timer.start()

# =====================================
#  CONFIGURAR BOTÕES
# =====================================
func _setup_buttons() -> void:
	if pause_button:
		# Desconectar sinais existentes para evitar duplicação
		for connection in pause_button.pressed.get_connections():
			pause_button.pressed.disconnect(connection.callable)
		
		pause_button.pressed.connect(_on_pause_pressed)
		pause_button.text = "⏸ Pausar"
		print("✅ Pause button configurado")
	
	if next_button:
		# Desconectar sinais existentes
		for connection in next_button.pressed.get_connections():
			next_button.pressed.disconnect(connection.callable)
		
		next_button.pressed.connect(_on_next_month_pressed)
		next_button.text = "▶️ Próximo Mês"
		print("✅ Next button configurado")

# =====================================
#  CICLO DE TEMPO
# =====================================
func _on_auto_timer_timeout() -> void:
	if time_running:
		_advance_month()

func _on_pause_pressed() -> void:
	time_running = !time_running
	if pause_button:
		pause_button.text = "⏸ Pausar" if time_running else "▶️ Retomar"
	
	if time_running:
		timer.start()
	else:
		timer.stop()
	
	print("Jogo ", "despausado" if time_running else "pausado")

func _on_next_month_pressed() -> void:
	if !time_running:
		_advance_month()

func _advance_month() -> void:
	# Avançar tempo global
	Globals.current_month += 1
	if Globals.current_month > 12:
		Globals.current_month = 1
		Globals.current_year += 1

	# Simulação passiva de todos os países
	Globals.simulate_monthly_changes()
	
	# Chance de evento aleatório (15%)
	if randi() % 100 < 15:
		var countries = Globals.country_data.keys()
		var random_country = countries[randi() % countries.size()]
		var event = Globals.apply_random_event(random_country)
		print("📰 EVENTO: %s em %s" % [event.get("name", "Evento"), random_country])

	# Atualizar UI
	_update_ui()
	_update_map_colors()
	
	print("📅 %s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year])

# =====================================
#  ATUALIZAR UI EXISTENTE
# =====================================
func _update_ui() -> void:
	# Dados do jogador atual
	var player_data = Globals.get_player_data()
	
	# Atualizar data
	if date_label and date_label is Label:
		date_label.text = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
		date_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Atualizar dinheiro
	if money_label and money_label is Label:
		var money = player_data.get("money", 0)
		money_label.text = "$ %s" % _format_number(money)
		money_label.add_theme_color_override("font_color", Color.GREEN)

	# Atualizar estabilidade
	if stability_label and stability_label is Label:
		var stability = player_data.get("stability", 50)
		stability_label.text = "Estabilidade: %d%%" % stability
		var color = Color.GREEN if stability > 70 else (Color.YELLOW if stability > 40 else Color.RED)
		stability_label.add_theme_color_override("font_color", color)

# =====================================
#  ATUALIZAR CORES DO MAPA
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
				
				child.color = color

# =====================================
#  INFORMAÇÕES DO PAÍS
# =====================================
func _show_country_info(country_name: String) -> void:
	var country_data = Globals.get_country(country_name)
	if country_data.is_empty():
		print("❌ País não encontrado: ", country_name)
		return
	
	# Se temos um container de informações, usar ele
	if info_container:
		_update_info_container(country_name, country_data)
	else:
		# Senão, só imprimir no console
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
	
	# Indicador de país do jogador
	if country_name == Globals.player_country:
		var player_indicator = Label.new()
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
	
	# Botão de ação
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
#  AÇÕES DO JOGADOR
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
	if event.is_action_pressed("ui_accept"):  # Espaço
		_on_pause_pressed()
	elif event.is_action_pressed("ui_right"):  # Seta direita
		_on_next_month_pressed()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Detecta cliques em polígonos do mapa
		var country_name = _detect_polygon_click(event.global_position)
		if country_name != "":
			_show_country_info(country_name)

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
	return Globals.get_country_value(Globals.player_country, "money", 0)

func get_current_month() -> int:
	return Globals.current_month

func get_current_year() -> int:
	return Globals.current_year

func is_time_running() -> bool:
	return time_running
