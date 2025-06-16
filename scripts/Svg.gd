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
	
	# Detectar estrutura existente CORRETAMENTE
	_detect_ui_structure()
	
	# Configurar timer
	_setup_timer()
	
	# Configurar botões se encontrados
	_setup_buttons()
	
	# Atualizar UI
	_update_ui()
	
	print("=== JOGO INICIADO ===")

# =====================================
#  DETECTAR ESTRUTURA EXISTENTE
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
#  CONFIGURAR TIMER
# =====================================
func _setup_timer() -> void:
	# Buscar timer existente primeiro
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
	timer.start()

# =====================================
#  CONFIGURAR BOTÕES
# =====================================
func _setup_buttons() -> void:
	if pause_button:
		# Limpar conexões existentes
		if pause_button.pressed.is_connected(_on_pause_pressed):
			pause_button.pressed.disconnect(_on_pause_pressed)
		
		# Conectar novo sinal
		pause_button.pressed.connect(_on_pause_pressed)
		pause_button.text = "⏸ Pausar"
		print("✅ Pause button configurado")
	else:
		print("❌ Pause button não encontrado")
	
	if next_button:
		# Limpar conexões existentes
		if next_button.pressed.is_connected(_on_next_month_pressed):
			next_button.pressed.disconnect(_on_next_month_pressed)
		
		# Conectar novo sinal
		next_button.pressed.connect(_on_next_month_pressed)
		next_button.text = "▶️ Próximo Mês"
		print("✅ Next button configurado")
	else:
		print("❌ Next button não encontrado")

# =====================================
#  CICLO DE TEMPO
# =====================================
func _on_auto_timer_timeout() -> void:
	print("⏰ Timer timeout! time_running = ", time_running)
	if time_running:
		print("⏭️ Avançando mês automaticamente...")
		_advance_month()
	else:
		print("⏸️ Jogo pausado, não avançando mês")

func _on_pause_pressed() -> void:
	time_running = !time_running
	print("🎮 Pausar pressionado! time_running agora é: ", time_running)
	
	if pause_button:
		pause_button.text = "⏸ Pausar" if time_running else "▶️ Retomar"
		print("📝 Texto do botão alterado para: ", pause_button.text)
	
	if timer:
		if time_running:
			timer.start()
			print("⏰ Timer iniciado")
		else:
			timer.stop()
			print("⏰ Timer parado")
	else:
		print("❌ Timer não encontrado!")

func _on_next_month_pressed() -> void:
	print("🎮 Próximo mês pressionado! time_running é: ", time_running)
	if not time_running:
		print("⏭️ Avançando mês manualmente...")
		_advance_month()
	else:
		print("⚠️ Jogo não está pausado, botão ignorado")

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

<<<<<<< HEAD
func _print_country_info(country_name: String, country_data: Dictionary) -> void:
	print("\n🏛️ === %s ===" % country_name.to_upper())
	print("💰 Dinheiro: $%s" % _format_number(country_data.get("money", 0)))
	print("⚖️ Estabilidade: %d%%" % country_data.get("stability", 50))
	print("🏛️ Gov. Power: %d%%" % country_data.get("gov_power", 50))
	print("🔥 Rebelião: %d%%" % country_data.get("rebel_power", 50))
	print("================\n")
=======
func parse_svg_path(d: String) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var current_pos: Vector2 = Vector2.ZERO
	var start_pos: Vector2 = Vector2.ZERO
	
	# Remove espaços extras e normaliza
	d = d.strip_edges().replace("\n", " ").replace("\t", " ")
	
	var i: int = 0
	while i < d.length():
		# Pula espaços
		while i < d.length() and d[i] in " ,\t\n":
			i += 1
		
		if i >= d.length():
			break
		
		# Pega o comando
		var command: String = d[i]
		i += 1
		
		# Pula espaços após comando
		while i < d.length() and d[i] in " ,\t\n":
			i += 1
		
		var is_absolute: bool = command == command.to_upper()
		
		match command.to_upper():
			"M": # MoveTo
				var coords = parse_coordinates(d, i, 2)
				if coords.size() >= 2:
					if is_absolute:
						current_pos = Vector2(coords[0], coords[1])
					else:
						current_pos += Vector2(coords[0], coords[1])
					start_pos = current_pos
					points.append(current_pos)
					i = coords[2]
					
					# MoveTo com múltiplos pontos vira LineTo
                                        while true:
                                                var more_coords = parse_coordinates(d, i, 2)
                                                if more_coords.size() < 2:
                                                        i = more_coords[more_coords.size() - 1]
                                                        break
						if is_absolute:
							current_pos = Vector2(more_coords[0], more_coords[1])
						else:
							current_pos += Vector2(more_coords[0], more_coords[1])
						points.append(current_pos)
						i = more_coords[2]
			
			"L": # LineTo
                                while true:
                                        var coords = parse_coordinates(d, i, 2)
                                        if coords.size() < 2:
                                                i = coords[coords.size() - 1]
                                                break
					if is_absolute:
						current_pos = Vector2(coords[0], coords[1])
					else:
						current_pos += Vector2(coords[0], coords[1])
					points.append(current_pos)
					i = coords[2]
			
			"H": # Horizontal LineTo
                                while true:
                                        var coords = parse_coordinates(d, i, 1)
                                        if coords.size() < 1:
                                                i = coords[coords.size() - 1]
                                                break
					if is_absolute:
						current_pos.x = coords[0]
					else:
						current_pos.x += coords[0]
					points.append(current_pos)
					i = coords[1]
			
			"V": # Vertical LineTo
                                while true:
                                        var coords = parse_coordinates(d, i, 1)
                                        if coords.size() < 1:
                                                i = coords[coords.size() - 1]
                                                break
					if is_absolute:
						current_pos.y = coords[0]
					else:
						current_pos.y += coords[0]
					points.append(current_pos)
					i = coords[1]
			
			"C": # Cubic Bezier
                                while true:
                                        var coords = parse_coordinates(d, i, 6)
                                        if coords.size() < 6:
                                                i = coords[coords.size() - 1]
                                                break
					
					# Adiciona alguns pontos intermediários para melhor aproximação
					var p0 = current_pos
					var p1 = Vector2(coords[0], coords[1])
					var p2 = Vector2(coords[2], coords[3])
					var p3 = Vector2(coords[4], coords[5])
					
					if not is_absolute:
						p1 = p0 + p1
						p2 = p0 + p2
						p3 = p0 + p3
					
					# Aproxima a curva com vários pontos
					for t in range(1, 11):
						var t_norm = float(t) / 10.0
						var one_minus_t = 1.0 - t_norm
						
						var point = p0 * pow(one_minus_t, 3) + \
								   p1 * 3 * pow(one_minus_t, 2) * t_norm + \
								   p2 * 3 * one_minus_t * pow(t_norm, 2) + \
								   p3 * pow(t_norm, 3)
						
						points.append(point)
					
					current_pos = p3
					i = coords[6]
			
			"S": # Smooth Cubic Bezier
                                while true:
                                        var coords = parse_coordinates(d, i, 4)
                                        if coords.size() < 4:
                                                i = coords[coords.size() - 1]
                                                break
					
					# Aproxima com pontos intermediários
					var p0 = current_pos
					var p2 = Vector2(coords[0], coords[1])
					var p3 = Vector2(coords[2], coords[3])
					
					if not is_absolute:
						p2 = p0 + p2
						p3 = p0 + p3
					
					# Adiciona pontos intermediários
					for j in range(1, 6):
						var t = float(j) / 5.0
						var point = p0.lerp(p3, t)
						points.append(point)
					
					current_pos = p3
					i = coords[4]
			
			"Q": # Quadratic Bezier
                                while true:
                                        var coords = parse_coordinates(d, i, 4)
                                        if coords.size() < 4:
                                                i = coords[coords.size() - 1]
                                                break
					
					# Aproxima a curva quadrática
					var p0 = current_pos
					var p1 = Vector2(coords[0], coords[1])
					var p2 = Vector2(coords[2], coords[3])
					
					if not is_absolute:
						p1 = p0 + p1
						p2 = p0 + p2
					
					# Adiciona pontos intermediários
					for j in range(1, 6):
						var t = float(j) / 5.0
						var one_minus_t = 1.0 - t
						
						var point = p0 * pow(one_minus_t, 2) + \
								   p1 * 2 * one_minus_t * t + \
								   p2 * pow(t, 2)
						
						points.append(point)
					
					current_pos = p2
					i = coords[4]
			
			"T": # Smooth Quadratic Bezier
                                while true:
                                        var coords = parse_coordinates(d, i, 2)
                                        if coords.size() < 2:
                                                i = coords[coords.size() - 1]
                                                break
					if is_absolute:
						current_pos = Vector2(coords[0], coords[1])
					else:
						current_pos += Vector2(coords[0], coords[1])
					points.append(current_pos)
					i = coords[2]
			
			"A": # Arc (simplificado - apenas pega o ponto final)
                                while true:
                                        var coords = parse_coordinates(d, i, 7)
                                        if coords.size() < 7:
                                                i = coords[coords.size() - 1]
                                                break
					if is_absolute:
						current_pos = Vector2(coords[5], coords[6])
					else:
						current_pos += Vector2(coords[5], coords[6])
					points.append(current_pos)
					i = coords[7]
			
			"Z", "z": # ClosePath
				if points.size() > 0 and current_pos.distance_to(start_pos) > 0.1:
					points.append(start_pos)
				current_pos = start_pos
			
			_:
				push_warning("Comando SVG não reconhecido: " + command)
	
	return points
>>>>>>> b7036897f6f09c269ae71b231fed92a9a47a0556

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
		print("⌨️ Espaço pressionado!")
		_on_pause_pressed()
	elif event.is_action_pressed("ui_right"):  # Seta direita
		print("⌨️ Seta direita pressionada!")
		_on_next_month_pressed()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Detecta cliques em polígonos do mapa
		var country_name = _detect_polygon_click(event.global_position)
		if country_name != "":
			print("🖱️ Clique detectado em: ", country_name)
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
