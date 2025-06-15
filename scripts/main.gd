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
var game_over_screen: Control

# =====================================
#  READY
# =====================================
func _ready() -> void:
	print("=== INICIANDO JOGO COM ESTRUTURA EXISTENTE ===")
	
	# Aguardar um frame
	await get_tree().process_frame
	
	# Detectar estrutura existente CORRETAMENTE
	_detect_ui_structure()
	
	# Configurar/criar tela de game over
	_setup_game_over_screen()
	
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
	
	# Buscar nos caminhos corretos conforme a estrutura mostrada
	date_label = get_node_or_null("CanvasLayer/TopBar/HBoxContainer/DateLabel")
	money_label = get_node_or_null("CanvasLayer/TopBar/HBoxContainer/MoneyLabel")  
	stability_label = get_node_or_null("CanvasLayer/TopBar/HBoxContainer/StabilityLabel")
	pause_button = get_node_or_null("CanvasLayer/BottomBar/HBoxContainer/PauseButton")
	next_button = get_node_or_null("CanvasLayer/BottomBar/HBoxContainer/NextButton")
	info_container = get_node_or_null("CanvasLayer/Sidepanel/InfoContainer")
	
	# Garantir que o país do jogador está correto (só uma vez)
	if Globals.player_country == "Brasil":  # Só corrigir se ainda estiver Brasil
		print("🔄 Corrigindo país do jogador para Argentina...")
		Globals.set_player_country("Argentina")
	
	# Resultados
	print("✅ DateLabel: ", date_label != null)
	print("✅ MoneyLabel: ", money_label != null)
	print("✅ StabilityLabel: ", stability_label != null)
	print("✅ PauseButton: ", pause_button != null)
	print("✅ NextButton: ", next_button != null)
	print("✅ InfoContainer: ", info_container != null)
	print("✅ País do jogador: ", Globals.player_country)

# =====================================
#  CONFIGURAR TELA DE GAME OVER
# =====================================
func _setup_game_over_screen() -> void:
	print("🎮 Configurando GameOver screen...")
	
	# Buscar a tela criada no Canvas
	game_over_screen = get_node_or_null("Gameover/GameOverScreen")
	
	if game_over_screen:
		print("✅ GameOver screen encontrado no Canvas")
		# Garantir que está oculto
		game_over_screen.visible = false
		
		# Configurar para funcionar quando pausado
		game_over_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		
		# Aguardar um frame para garantir que tudo está carregado
		await get_tree().process_frame
		
		# Conectar botões - método mais robusto
		_connect_gameover_buttons()
	else:
		print("⚠️ GameOver screen do Canvas não encontrado - usando popup")
	
	print("✅ GameOver screen configurado: ", game_over_screen != null)

func _connect_gameover_buttons() -> void:
	print("🔗 Conectando botões do GameOver...")
	
	# Buscar botões com diferentes possibilidades de nomes
	var restart_btn = get_node_or_null("Gameover/GameOverScreen/CenterContainer/VBoxContainer/HBoxContainer/RestartBtn")
	var quit_btn = get_node_or_null("Gameover/GameOverScreen/CenterContainer/VBoxContainer/HBoxContainer/QuitBtn")
	
	# Se QuitBtn não for encontrado, tentar outras variações
	if not quit_btn:
		quit_btn = get_node_or_null("Gameover/GameOverScreen/CenterContainer/VBoxContainer/HBoxContainer/QuitBtn (")
		if quit_btn:
			print("🔍 QuitBtn encontrado com nome alternativo")
	
	# Se ainda não encontrou, listar todos os botões do container
	if not quit_btn:
		var button_container = get_node_or_null("Gameover/GameOverScreen/CenterContainer/VBoxContainer/HBoxContainer")
		if button_container:
			print("🔍 Listando todos os filhos do HBoxContainer:")
			for i in range(button_container.get_child_count()):
				var child = button_container.get_child(i)
				print("  [%d] %s (%s)" % [i, child.name, child.get_class()])
				
				# Se for um botão e não for o restart, assumir que é o quit
				if child is Button and child != restart_btn:
					quit_btn = child
					print("🔍 Assumindo que este é o QuitBtn: %s" % child.name)
					break
	
	print("RestartBtn encontrado: ", restart_btn != null)
	print("QuitBtn encontrado: ", quit_btn != null)
	
	if restart_btn:
		# Configurar para funcionar quando pausado
		restart_btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		
		# Verificar se já está conectado antes de conectar
		if not restart_btn.pressed.is_connected(_restart_game):
			restart_btn.pressed.connect(_restart_game)
			print("✅ RestartBtn conectado à função _restart_game")
		else:
			print("⚠️ RestartBtn já estava conectado")
		
		# Definir texto para garantir
		restart_btn.text = "🔄 Reiniciar"
	else:
		print("❌ RestartBtn não encontrado no caminho especificado")
	
	if quit_btn:
		# Configurar para funcionar quando pausado
		quit_btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		
		# Verificar se já está conectado antes de conectar
		if not quit_btn.pressed.is_connected(_quit_game):
			quit_btn.pressed.connect(_quit_game)
			print("✅ QuitBtn conectado à função _quit_game")
		else:
			print("⚠️ QuitBtn já estava conectado")
		
		# Definir texto para garantir
		quit_btn.text = "⏹️ Sair"
	else:
		print("❌ QuitBtn não encontrado - criando um novo...")
		_create_quit_button()

func _create_quit_button() -> void:
	var button_container = get_node_or_null("Gameover/GameOverScreen/CenterContainer/VBoxContainer/HBoxContainer")
	if button_container:
		var quit_btn = Button.new()
		quit_btn.name = "QuitBtn_Created"
		quit_btn.text = "⏹️ Sair"
		quit_btn.custom_minimum_size = Vector2(180, 60)
		quit_btn.add_theme_font_size_override("font_size", 18)
		quit_btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		
		button_container.add_child(quit_btn)
		quit_btn.pressed.connect(_quit_game)
		
		print("✅ QuitBtn criado e conectado dinamicamente")
	else:
		print("❌ Não foi possível criar QuitBtn - container não encontrado")

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
	
	# VERIFICAR REVOLUÇÃO NO PAÍS DO JOGADOR
	_check_revolution()
	
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
#  VERIFICAR REVOLUÇÃO
# =====================================
func _check_revolution() -> void:
	var player_data = Globals.get_country(Globals.player_country)
	if player_data.is_empty():
		return
	
	var rebel_power = player_data.get("rebel_power", 0)
	print("🔥 Poder rebelde em %s: %d%%" % [Globals.player_country, rebel_power])
	
	if rebel_power >= 100:
		print("💀 REVOLUÇÃO! Poder rebelde atingiu 100%!")
		_trigger_game_over()

func _trigger_game_over() -> void:
	print("🎮 Acionando Game Over...")
	
	# Parar timer imediatamente
	if timer:
		timer.stop()
	time_running = false
	
	# Tentar usar a tela do Canvas primeiro
	if game_over_screen:
		_show_canvas_game_over()
	else:
		# Fallback para popup
		_show_reliable_game_over()

func _show_canvas_game_over() -> void:
	print("🎮 Usando GameOver do Canvas...")
	
	var current_date = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
	
	# Atualizar textos
	var title_label = get_node_or_null("Gameover/GameOverScreen/CenterContainer/VBoxContainer/Title")
	var subtitle_label = get_node_or_null("Gameover/GameOverScreen/CenterContainer/VBoxContainer/Subtitle")
	
	if title_label:
		title_label.text = "🔥 REVOLUÇÃO!"
	
	if subtitle_label:
		subtitle_label.text = "Seu governo foi deposto em %s!\nO país %s está em revolução!" % [current_date, Globals.player_country.to_upper()]
	
	# Configurar botões para funcionar quando pausado
	var restart_btn = get_node_or_null("Gameover/GameOverScreen/CenterContainer/VBoxContainer/HBoxContainer/RestartBtn")
	var quit_btn = get_node_or_null("Gameover/GameOverScreen/CenterContainer/VBoxContainer/HBoxContainer/QuitBtn")
	
	if restart_btn:
		restart_btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		print("✅ RestartBtn configurado para funcionar quando pausado")
	
	if quit_btn:
		quit_btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		print("✅ QuitBtn configurado para funcionar quando pausado")
	
	# Configurar o GameOver screen também
	if game_over_screen:
		game_over_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		print("✅ GameOver screen configurado para funcionar quando pausado")
	
	# Mostrar a tela
	game_over_screen.visible = true
	
	# Pausar o jogo
	get_tree().paused = true
	
	print("✅ GameOver do Canvas exibido")

func _show_reliable_game_over() -> void:
	print("💀 === GAME OVER ===")
	print("🔥 Revolução em %s!" % Globals.player_country)
	
	var current_date = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
	print("📅 Data: %s" % current_date)
	print("================")
	
	# Usar ConfirmationDialog que é mais confiável
	var dialog = ConfirmationDialog.new()
	dialog.title = "🔥 REVOLUÇÃO!"
	
	dialog.dialog_text = """REVOLUÇÃO EM %s!

Seu governo foi deposto em %s!
O país está em caos total.

A partida terminou.

Deseja reiniciar?""" % [Globals.player_country.to_upper(), current_date]
	
	# Configurar botões
	dialog.get_ok_button().text = "🔄 Reiniciar"
	dialog.get_cancel_button().text = "⏹️ Sair"
	
	# Conectar sinais corretos
	dialog.confirmed.connect(_restart_game)
	dialog.canceled.connect(_quit_game)
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Pausar árvore
	get_tree().paused = true

func _quit_game() -> void:
	print("⏹️ Saindo do jogo...")
	get_tree().paused = false
	get_tree().quit()

func _restart_game() -> void:
	print("🔄 Reiniciando jogo...")
	get_tree().paused = false
	Globals.reset_game()
	get_tree().reload_current_scene()

# =====================================
#  ATUALIZAR UI EXISTENTE
# =====================================
func _update_ui() -> void:
	# Dados do jogador atual (não forçar Argentina aqui)
	var player_data = Globals.get_player_data()
	
	print("🔄 Atualizando UI - País: %s, Dados: %s" % [Globals.player_country, player_data])
	
	# Atualizar data
	if date_label and date_label is Label:
		date_label.text = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
		date_label.add_theme_color_override("font_color", Color.WHITE)
		print("📅 Data atualizada: %s" % date_label.text)
	else:
		print("❌ DateLabel não encontrado ou inválido")
	
	# Atualizar dinheiro
	if money_label and money_label is Label:
		var money = player_data.get("money", 0)
		money_label.text = "$ %s" % _format_number(money)
		money_label.add_theme_color_override("font_color", Color.GREEN)
		print("💰 Dinheiro atualizado: %s" % money_label.text)
	else:
		print("❌ MoneyLabel não encontrado ou inválido")

	# Atualizar estabilidade
	if stability_label and stability_label is Label:
		var stability = player_data.get("stability", 50)
		stability_label.text = "Estabilidade: %d%%" % stability
		var color = Color.GREEN if stability > 70 else (Color.YELLOW if stability > 40 else Color.RED)
		stability_label.add_theme_color_override("font_color", color)
		print("⚖️ Estabilidade atualizada: %s" % stability_label.text)
	else:
		print("❌ StabilityLabel não encontrado ou inválido")

# =====================================
#  ATUALIZAR CORES DO MAPA
# =====================================
func _update_map_colors() -> void:
	var map := get_node_or_null("NodeMapaSVG2D")
	if map == null:
		return
	
	for country_node in map.get_children():
		if country_node is Polygon2D:
			# Buscar Sprite2D dentro do Polygon2D
			for child in country_node.get_children():
				if child is Sprite2D:
					var country_name = country_node.name  # Nome do país vem do Polygon2D pai
					var country_data = Globals.get_country(country_name)
					
					if not country_data.is_empty():
						# Verificar se está em revolução (prioridade máxima)
						if country_data.get("in_revolution", false):
							child.modulate = Color(0.8, 0.1, 0.1, 0.8)  # Vermelho revolução
							print("🔴 %s em revolução - cor vermelha aplicada" % country_name)
							break
						
						var stability = country_data.get("stability", 50)
						var gov_power = country_data.get("gov_power", 50)
						
						# Colorir baseado na estabilidade
						var color: Color
						if stability < 25:
							color = Color.RED
						elif stability < 50:
							color = Color.ORANGE
						elif stability < 75:
							color = Color.YELLOW
						else:
							color = Color.GREEN
						
						# Opacidade baseada no poder governamental
						color.a = 0.5 + (gov_power / 200.0)
						
						# Destacar país do jogador
						if country_name == Globals.player_country:
							color = color.lightened(0.4)
						
						# Aplicar cor ao Sprite2D
						child.modulate = color
					break  # Só precisamos do primeiro Sprite2D

# =====================================
#  INFORMAÇÕES DO PAÍS
# =====================================
func _show_country_info(country_name: String) -> void:
	print("🔍 Mostrando informações de: %s" % country_name)
	
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
	
	var current_money = Globals.get_country_value(country_name, "money", 0)
	
	if current_money >= 500:
		# Custo da ação
		Globals.adjust_country_value(country_name, "money", -500)
		
		# Benefícios (balanceados)
		Globals.adjust_country_value(country_name, "gov_power", randi_range(3, 6))
		Globals.adjust_country_value(country_name, "rebel_power", randi_range(-2, -4))
		Globals.adjust_country_value(country_name, "stability", randi_range(1, 3))
		
		print("✅ Ação 'Governar' executada com sucesso (-$500)")
	else:
		print("❌ Dinheiro insuficiente para governar (precisa $500)")
	
	_update_ui()
	_show_country_info(country_name)

func _on_trade_with_country(country_name: String) -> void:
	print("🤝 Negociando com: ", country_name)
	
	var trade_bonus = randi_range(200, 500)  # Mais conservador
	var relation_bonus = randi_range(2, 5)   # Mais conservador
	
	Globals.adjust_country_value(Globals.player_country, "money", trade_bonus)
	Globals.adjust_relation(Globals.player_country, country_name, relation_bonus)
	
	print("✅ Comércio realizado: +$%d, relação +%d" % [trade_bonus, relation_bonus])
	
	_update_ui()
	_show_country_info(country_name)

# =====================================
#  FUNÇÕES DE TESTE (temporárias)
# =====================================
func _test_revolution() -> void:
	print("🧪 === TESTE DE REVOLUÇÃO ===")
	Globals.set_country_value(Globals.player_country, "rebel_power", 100)
	_check_revolution()
	print("🧪 === FIM DO TESTE ===")

func _debug_ui_structure() -> void:
	print("🔍 === DEBUG DA ESTRUTURA DA UI ===")
	_print_children_recursive(self, 0)
	print("🔍 === FIM DO DEBUG ===")

func _print_children_recursive(node: Node, indent: int) -> void:
	var prefix = ""
	for i in range(indent):
		prefix += "  "
	
	print("%s%s (%s)" % [prefix, node.name, node.get_class()])
	
	for child in node.get_children():
		_print_children_recursive(child, indent + 1)

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
	elif event.is_action_pressed("ui_home"):  # Home (para teste)
		print("🧪 Testando revolução...")
		_test_revolution()
	elif event.is_action_pressed("ui_end"):  # End (para debug)
		print("🔍 Debug da estrutura da UI...")
		_debug_ui_structure()
	elif event is InputEventKey and event.pressed:
		# Atalhos específicos para teste
		if event.keycode == KEY_T:  # T = Test buttons
			print("🧪 Testando botões do GameOver...")
			_test_gameover_buttons()
		elif event.keycode == KEY_B:  # B = Balance test
			print("⚖️ Testando balanceamento...")
			_test_balance()
		elif event.keycode == KEY_C:  # C = Click test
			print("🖱️ Testando detecção de países...")
			_test_country_detection()
		elif event.keycode == KEY_I:  # I = IA test
			print("🤖 Testando IA dos países...")
			_test_ai_behavior()
		elif event.keycode == KEY_R and game_over_screen and game_over_screen.visible:
			# R quando GameOver está visível
			print("🔄 Atalho R pressionado!")
			_restart_game()
		elif event.keycode == KEY_Q and game_over_screen and game_over_screen.visible:
			# Q quando GameOver está visível  
			print("⏹️ Atalho Q pressionado!")
			_quit_game()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Debug detalhado do clique
		print("🖱️ Clique detectado em posição: %s" % event.global_position)
		
		# Detecta cliques em polígonos do mapa
		var country_name = _detect_polygon_click(event.global_position)
		print("🔍 País detectado: '%s'" % country_name)
		
		if country_name != "":
			print("✅ Mostrando informações de: %s" % country_name)
			_show_country_info(country_name)
		else:
			print("❌ Nenhum país detectado no clique")

func _test_country_detection() -> void:
	print("🧪 === TESTE DE DETECÇÃO DE PAÍSES ===")
	
	var map := get_node_or_null("NodeMapaSVG2D")
	if map == null:
		print("❌ NodeMapaSVG2D não encontrado!")
		return
	
	print("✅ NodeMapaSVG2D encontrado")
	print("📋 Países disponíveis no mapa:")
	
	for country_node in map.get_children():
		if country_node is Polygon2D:
			print("  - %s (Polygon2D)" % country_node.name)
			
			# Verificar se tem Sprite2D
			for child in country_node.get_children():
				if child is Sprite2D:
					print("    └─ %s (Sprite2D) - pos: %s" % [child.name, child.global_position])
					break
	
	print("📋 Países disponíveis nos dados:")
	for country in Globals.country_data.keys():
		print("  - %s" % country)
	
	print("🧪 === FIM DO TESTE ===")

func _test_balance() -> void:
	print("⚖️ === TESTE DE BALANCEAMENTO ===")
	
	var player_data = Globals.get_player_data()
	print("💰 Estado inicial:")
	print("  Dinheiro: $%d" % player_data.get("money", 0))
	print("  Receita: $%d/mês" % player_data.get("income", 0))
	print("  Despesa: $%d/mês" % player_data.get("expenses", 0))
	print("  Estabilidade: %d%%" % player_data.get("stability", 0))
	print("  Gov Power: %d%%" % player_data.get("gov_power", 0))
	print("  Rebel Power: %d%%" % player_data.get("rebel_power", 0))
	
	print("\n🚀 Simulando 5 meses...")
	for i in range(5):
		_advance_month()
		await get_tree().process_frame
	
	player_data = Globals.get_player_data()
	print("\n💰 Estado após 5 meses:")
	print("  Dinheiro: $%d" % player_data.get("money", 0))
	print("  Estabilidade: %d%%" % player_data.get("stability", 0))
	print("  Gov Power: %d%%" % player_data.get("gov_power", 0))
	print("  Rebel Power: %d%%" % player_data.get("rebel_power", 0))
	
	print("⚖️ === FIM TESTE BALANCEAMENTO ===")

func _force_show_country(country_name: String) -> void:
	print("🔧 FORÇANDO exibição de: %s" % country_name)
	_show_country_info(country_name)

func _test_ai_behavior() -> void:
	print("🤖 === TESTE DE IA ===")
	
	print("📊 Estado antes da IA:")
	for country in ["Chile", "Uruguay", "Paraguay"]:
		var data = Globals.get_country(country)
		print("  %s: Money=%d, Stab=%d%%, Gov=%d%%, Rebel=%d%%" % [
			country, data.get("money", 0), data.get("stability", 0), 
			data.get("gov_power", 0), data.get("rebel_power", 0)
		])
	
	print("\n🚀 Simulando 3 meses de IA...")
	for i in range(3):
		print("\n--- Mês %d ---" % (i + 1))
		for country in ["Chile", "Uruguay", "Paraguay"]:
			if country != Globals.player_country:
				Globals.simulate_ai_country(country)
		await get_tree().process_frame
	
	print("\n📊 Estado após IA:")
	for country in ["Chile", "Uruguay", "Paraguay"]:
		var data = Globals.get_country(country)
		print("  %s: Money=%d, Stab=%d%%, Gov=%d%%, Rebel=%d%%" % [
			country, data.get("money", 0), data.get("stability", 0), 
			data.get("gov_power", 0), data.get("rebel_power", 0)
		])
		
		if data.get("in_revolution", false):
			print("    🔴 EM REVOLUÇÃO!")
	
	print("🤖 === FIM TESTE IA ===")
	
	# Atualizar cores do mapa
	_update_map_colors()

func _test_gameover_buttons() -> void:
	print("🧪 === TESTE DOS BOTÕES GAMEOVER ===")
	
	# Reconectar botões
	_connect_gameover_buttons()
	
	# Mostrar GameOver para teste
	if game_over_screen:
		game_over_screen.visible = true
		get_tree().paused = true
		print("GameOver exibido para teste")
		print("Pressione R para Reiniciar ou Q para Sair")
		print("Ou clique nos botões")
	else:
		print("❌ GameOver screen não encontrado")
	
	print("🧪 === FIM DO TESTE ===")

func _detect_polygon_click(global_pos: Vector2) -> String:
	print("🔍 Detectando clique em: %s" % global_pos)
	
	var map := get_node_or_null("NodeMapaSVG2D")
	if map == null:
		print("❌ NodeMapaSVG2D não encontrado!")
		return ""
	
	print("✅ NodeMapaSVG2D encontrado, verificando %d países..." % map.get_child_count())
	
	var detected_countries = []
	
	# Verificar TODOS os países e coletar os que foram clicados
	for country_node in map.get_children():
		if country_node is Polygon2D:
			print("🔍 Verificando país: %s" % country_node.name)
			
			# Método 1: Verificar polígono primeiro (mais preciso)
			var local_pos = country_node.to_local(global_pos)
			if Geometry2D.is_point_in_polygon(local_pos, country_node.polygon):
				print("✅ CLIQUE DETECTADO no polígono de %s!" % country_node.name)
				detected_countries.append({
					"name": country_node.name,
					"method": "polygon",
					"priority": 1  # Polígono tem prioridade maior
				})
				continue
			
			# Método 2: Verificar Sprite2D como fallback
			for child in country_node.get_children():
				if child is Sprite2D:
					var texture = child.texture
					if texture:
						var tex_size = texture.get_size() * child.scale
						var sprite_rect = Rect2(child.global_position - tex_size * 0.5, tex_size)
						
						if sprite_rect.has_point(global_pos):
							print("✅ CLIQUE DETECTADO no Sprite2D de %s!" % country_node.name)
							detected_countries.append({
								"name": country_node.name,
								"method": "sprite",
								"priority": 2  # Sprite tem prioridade menor
							})
					break
	
	# Se encontrou países, escolher o de maior prioridade
	if detected_countries.size() > 0:
		# Ordenar por prioridade (menor número = maior prioridade)
		detected_countries.sort_custom(func(a, b): return a.priority < b.priority)
		
		var selected_country = detected_countries[0]
		print("🎯 País selecionado: %s (método: %s)" % [selected_country.name, selected_country.method])
		
		if detected_countries.size() > 1:
			print("📋 Outros países detectados: %s" % [detected_countries.slice(1)])
		
		return selected_country.name
	
	print("❌ Nenhum país detectado no clique")
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
