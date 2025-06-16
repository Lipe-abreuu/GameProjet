extends Node

# =====================================
#  CONSTANTES
# =====================================
const MONTH_NAMES: Array[String] = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]

# =====================================
#  VARIÁVEIS DE ESTADO
# =====================================
var time_running: bool = true

# =====================================
#  REFERÊNCIAS DA UI
# =====================================
var date_label: Label
var money_label: Label
var stability_label: Label
var pause_button: Button
var next_button: Button
var info_container: VBoxContainer
var timer: Timer

# =====================================
#  SISTEMA DE NOTIFICAÇÕES INTEGRADO
# =====================================
var notification_panel: PanelContainer
var notification_box: VBoxContainer
var notification_history: Array[Dictionary] = []
var max_notifications: int = 3  # ALTERADO: Máximo de 3 notificações visíveis

# =====================================
#  INICIALIZAÇÃO
# =====================================
func _ready() -> void:
	print("🎮 Iniciando sistema com notificações integradas...")
	await get_tree().process_frame

	_setup_ui_references()
	_setup_notification_system()
	_setup_timer()
	_start_game()

func _setup_ui_references() -> void:
	# Buscar especificamente nos caminhos da sua estrutura
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

# =====================================
#  CONFIGURAR SISTEMA DE NOTIFICAÇÕES
# =====================================
func _setup_notification_system() -> void:
	print("🔍 Procurando NotificationPanel na cena...")
	
	# Busca específica por nome
	notification_panel = _find_node_by_name(get_tree().root, "NotificationPanel")
	if notification_panel:
		print("✅ NotificationPanel encontrado: %s" % notification_panel.get_path())
		notification_box = _find_node_by_name(notification_panel, "NotificationBox")
		if notification_box:
			print("✅ NotificationBox encontrado: %s" % notification_box.get_path())
		else:
			print("🔧 NotificationBox não encontrado, criando dentro do painel existente...")
			notification_box = VBoxContainer.new()
			notification_box.name = "NotificationBox"
			notification_panel.add_child(notification_box)
	else:
		print("❌ NotificationPanel não encontrado em lugar nenhum!")
		print("🔧 Criando sistema de notificações programaticamente...")
		_create_notification_system()
	
	# NOVA POSIÇÃO: No canto superior esquerdo
	_apply_new_positioning()
	
	print("✅ Sistema de notificações configurado!")

# Função para buscar um nó por nome em toda a árvore
func _find_node_by_name(root_node: Node, target_name: String) -> Node:
	if root_node.name == target_name:
		return root_node
	
	for child in root_node.get_children():
		var found = _find_node_by_name(child, target_name)
		if found:
			return found
	
	return null

func _create_notification_system() -> void:
	print("🔧 Criando sistema de notificações programaticamente...")
	
	# Criar o painel principal
	notification_panel = PanelContainer.new()
	notification_panel.name = "NotificationPanel_Created"
	
	# Adicionar ao CanvasLayer
	var canvas_layer = get_node_or_null("CanvasLayer")
	if canvas_layer:
		canvas_layer.add_child(notification_panel)
	else:
		add_child(notification_panel)
	
	# Criar o container de notificações
	notification_box = VBoxContainer.new()
	notification_box.name = "NotificationBox_Created"
	notification_panel.add_child(notification_box)
	
	print("🔧 Sistema criado programaticamente")

# =====================================
#  NOVA FUNÇÃO DE POSICIONAMENTO
# =====================================
func _apply_new_positioning() -> void:
	if not notification_panel:
		return

	# Pega o tamanho da viewport para posicionar à direita
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_width = notification_panel.custom_minimum_size.x
	var margin_right = 300
	var margin_top = 10

	# Calcula X e Y usando as variáveis
	var x_pos = viewport_size.x - panel_width - margin_right
	var y_pos = margin_top
	notification_panel.position = Vector2(x_pos, y_pos)

	# Ajusta tamanho, z-index e visibilidade
	notification_panel.custom_minimum_size = Vector2(350, 200)
	notification_panel.z_index = 100
	notification_panel.visible = true
	notification_panel.show()

	# Estilo do painel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.3, 0.5, 0.7, 0.9)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	notification_panel.add_theme_stylebox_override("panel", style_box)

	print("📍 Notificações reposicionadas: Canto superior direito")

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
	timer.timeout.connect(_on_timer_timeout)

	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
		pause_button.text = "⏸ Pausar"
		print("✅ Pause button configurado")
	if next_button:
		next_button.pressed.connect(_on_next_month_pressed)
		next_button.text = "▶️ Próximo Mês"
		print("✅ Next button configurado")

func _start_game() -> void:
	timer.start()
	_update_all_ui()
	_add_notification("🎮 Jogo iniciado", "Sistema carregado com sucesso!", "success")
	print("🎮 Jogo iniciado com notificações!")

# =====================================
#  LOOP PRINCIPAL
# =====================================
func _on_timer_timeout() -> void:
	if time_running:
		_advance_month()

func _advance_month() -> void:
	Globals.current_month += 1
	if Globals.current_month > 12:
		Globals.current_month = 1
		Globals.current_year += 1
		_add_notification("📅 Novo Ano", "Chegamos a %d!" % Globals.current_year, "success")

	# Simulação passiva de todos os países
	if Globals.has_method("simulate_monthly_changes"):
		Globals.simulate_monthly_changes()
	
	# Chance de evento aleatório (15%)
	if randi() % 100 < 15:
		var countries = Globals.country_data.keys()
		if countries.size() > 0:
			var random_country = countries[randi() % countries.size()]
			if Globals.has_method("apply_random_event"):
				var event = Globals.apply_random_event(random_country)
				var event_name = event.get("name", "Evento")
				_add_notification("📰 " + event_name, "Aconteceu em " + random_country, "info")

	_update_all_ui()

	# Notificação de mudança de mês
	var month_name = MONTH_NAMES[Globals.current_month - 1]
	_add_notification("📅 " + month_name, "Mês avançou para %s %d" % [month_name, Globals.current_year], "info")

	print("📅 %s %d" % [month_name, Globals.current_year])

# =====================================
#  CONTROLES
# =====================================
func _on_pause_pressed() -> void:
	time_running = not time_running
	if pause_button:
		pause_button.text = "⏸ Pausar" if time_running else "▶️ Retomar"
	if time_running:
		timer.start()
		_add_notification("⏰ Tempo", "Jogo retomado", "info")
	else:
		timer.stop()
		_add_notification("⏸️ Pausa", "Jogo pausado", "warning")

func _on_next_month_pressed() -> void:
	if not time_running:
		_advance_month()

# =====================================
#  SISTEMA DE UI
# =====================================
func _update_all_ui() -> void:
	_update_date_display()
	_update_resource_display()
	_update_stability_display()
	_update_map_colors()

func _update_date_display() -> void:
	if date_label:
		date_label.text = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
		date_label.modulate = Color.WHITE

func _update_resource_display() -> void:
	if money_label:
		var player_data = Globals.get_player_data()
		var money_value = player_data.get("money", 0)
		money_label.text = "$ %s" % _format_number(money_value)
		money_label.modulate = Color.GREEN

func _update_stability_display() -> void:
	if stability_label:
		var player_data = Globals.get_player_data()
		var stability_value = player_data.get("stability", 50)
		stability_label.text = "⚖️ Estabilidade: %d%%" % stability_value
		if stability_value > 70:
			stability_label.modulate = Color.GREEN
		elif stability_value > 40:
			stability_label.modulate = Color.YELLOW
		else:
			stability_label.modulate = Color.RED

func _update_map_colors() -> void:
	var map = get_node_or_null("NodeMapaSVG2D")
	if not map:
		return
	for child in map.get_children():
		if not child is Polygon2D:
			continue
		var country_name = child.name
		var country_data = Globals.get_country(country_name)
		if country_data.is_empty():
			continue
		var stability = country_data.get("stability", 50)
		var color = _get_stability_color(stability)
		if country_name == Globals.player_country:
			color = color.lightened(0.4)
		child.color = color

func _get_stability_color(stability: int) -> Color:
	if stability < 25:
		return Color.RED.darkened(0.2)
	elif stability < 50:
		return Color.ORANGE.darkened(0.1)
	elif stability < 75:
		return Color.YELLOW.darkened(0.1)
	else:
		return Color.GREEN.darkened(0.1)

# =====================================
#  INFORMAÇÕES DO PAÍS
# =====================================
func show_country_info(country_name: String) -> void:
	if not info_container:
		return
	for child in info_container.get_children():
		child.queue_free()
	var country_data = Globals.get_country(country_name)
	if country_data.is_empty():
		_show_no_country_data(country_name)
		return
	_build_country_info_ui(country_name, country_data)
	_add_notification("🏛️ " + country_name, "Visualizando informações", "info")

func _show_no_country_data(country_name: String) -> void:
	var label = Label.new()
	label.text = "❌ Dados não disponíveis para %s" % country_name
	label.modulate = Color.RED
	info_container.add_child(label)

func _build_country_info_ui(country_name: String, country_data: Dictionary) -> void:
	var title = Label.new()
	title.text = "🏛️ %s" % country_name.to_upper()
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color.GOLD
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(title)
	
	if country_name == Globals.player_country:
		var indicator = Label.new()
		indicator.text = "👑 SEU PAÍS"
		indicator.modulate = Color.CYAN
		indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_container.add_child(indicator)
	
	var data_items = [
		"💰 Dinheiro: $%s" % _format_number(country_data.get("money", 0)),
		"⚖️ Estabilidade: %d%%" % country_data.get("stability", 50),
		"🏛️ Poder Gov.: %d%%" % country_data.get("gov_power", 50),
		"🔥 Rebelião: %d%%" % country_data.get("rebel_power", 50),
		"👥 População: %s" % _format_number(country_data.get("population", 0)),
		"🏭 Indústria: %d%%" % country_data.get("industry", 0),
		"🛡️ Defesa: %d%%" % country_data.get("defense", 0)
	]
	for item in data_items:
		var label = Label.new()
		label.text = item
		label.add_theme_font_size_override("font_size", 12)
		info_container.add_child(label)
	
	_add_action_button(country_name)

func _add_action_button(country_name: String) -> void:
	var button = Button.new()
	button.custom_minimum_size = Vector2(180, 35)
	if country_name == Globals.player_country:
		button.text = "👑 Governar"
		button.pressed.connect(_govern_country.bind(country_name))
	else:
		button.text = "🤝 Negociar"
		button.pressed.connect(_negotiate_with_country.bind(country_name))
	info_container.add_child(button)

# =====================================
#  AÇÕES
# =====================================
func _govern_country(country_name: String) -> void:
	if Globals.has_method("adjust_country_value"):
		var current_money = Globals.get_country_value(country_name, "money", 0)
		if current_money >= 500:
			var bonus = randi_range(3, 8)
			Globals.adjust_country_value(country_name, "gov_power", bonus)
			Globals.adjust_country_value(country_name, "money", -500)
			_add_notification("👑 Governar", "Poder gov. +%d (-$500)" % bonus, "success")
		else:
			_add_notification("❌ Erro", "Dinheiro insuficiente (precisa $500)", "error")
		_update_all_ui()
		show_country_info(country_name)

func _negotiate_with_country(country_name: String) -> void:
	if Globals.has_method("adjust_country_value"):
		var bonus = randi_range(200, 800)
		Globals.adjust_country_value(Globals.player_country, "money", bonus)
		_add_notification("🤝 Comércio", "+$%s com %s" % [_format_number(bonus), country_name], "success")
		_update_all_ui()

# =====================================
#  SISTEMA DE NOTIFICAÇÕES OTIMIZADO
# =====================================
func _add_notification(title: String, message: String, type: String = "info") -> void:
	if not notification_box:
		print("❌ Sistema de notificações não disponível!")
		return
	
	# REGRA NOVA: Limitar a 3 notificações máximo
	_enforce_notification_limit()
	
	# Adicionar à história
	var notification_data = {
		"title": title,
		"message": message,
		"type": type,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	notification_history.append(notification_data)
	
	# Limitar histórico
	if notification_history.size() > max_notifications:
		notification_history.remove_at(0)
	
	# Criar elemento visual
	_create_notification_item(notification_data)
	
	print("📋 Notificação: %s - %s" % [title, message])

# =====================================
#  NOVA FUNÇÃO: CONTROLE RIGOROSO DE LIMITE
# =====================================
func _enforce_notification_limit() -> void:
	if not notification_box:
		return
	
	var children = notification_box.get_children()
	var notification_count = 0
	
	# Contar apenas as notificações (não os separadores)
	for child in children:
		if child is PanelContainer:
			notification_count += 1
	
	# Se já temos 3 ou mais, remover as mais antigas
	while notification_count >= max_notifications:
		var found_notification = false
		for child in children:
			if child is PanelContainer:
				# Remover notificação mais antiga
				child.queue_free()
				
				# Remover também o separador seguinte, se existir
				var child_index = child.get_index()
				if child_index + 1 < children.size():
					var next_child = children[child_index + 1]
					if next_child is HSeparator:
						next_child.queue_free()
				
				notification_count -= 1
				found_notification = true
				break
		
		if not found_notification:
			break  # Evitar loop infinito

func _create_notification_item(data: Dictionary) -> void:
	# Container principal da notificação
	var notification_item = PanelContainer.new()
	notification_item.custom_minimum_size = Vector2(330, 50)  # Ajustado para nova largura
	
	# Estilo baseado no tipo
	var item_style = StyleBoxFlat.new()
	match data.type:
		"success":
			item_style.bg_color = Color(0.1, 0.5, 0.1, 0.95)  # Verde mais vibrante
		"warning":
			item_style.bg_color = Color(0.5, 0.4, 0.1, 0.95)  # Amarelo mais vibrante
		"error":
			item_style.bg_color = Color(0.5, 0.1, 0.1, 0.95)  # Vermelho mais vibrante
		_:  # info
			item_style.bg_color = Color(0.1, 0.3, 0.5, 0.95)  # Azul mais vibrante
	
	item_style.corner_radius_top_left = 8
	item_style.corner_radius_top_right = 8
	item_style.corner_radius_bottom_left = 8
	item_style.corner_radius_bottom_right = 8
	item_style.border_width_left = 2
	item_style.border_width_right = 2
	item_style.border_width_top = 2
	item_style.border_width_bottom = 2
	item_style.border_color = Color.WHITE.darkened(0.3)
	
	notification_item.add_theme_stylebox_override("panel", item_style)
	
	# Layout horizontal
	var hbox = HBoxContainer.new()
	notification_item.add_child(hbox)
	
	# Ícone
	var icon_label = Label.new()
	match data.type:
		"success":
			icon_label.text = "✅"
		"warning":
			icon_label.text = "⚠️"
		"error":
			icon_label.text = "❌"
		_:
			icon_label.text = "ℹ️"
	
	icon_label.add_theme_font_size_override("font_size", 18)
	icon_label.custom_minimum_size = Vector2(35, 35)
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)
	
	# Texto
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)
	
	# Título
	var title_label = Label.new()
	title_label.text = data.title
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	text_vbox.add_child(title_label)
	
	# Mensagem
	var message_label = Label.new()
	message_label.text = data.message
	message_label.add_theme_font_size_override("font_size", 11)
	message_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_vbox.add_child(message_label)
	
	# Timestamp
	var time_parts = data.timestamp.split(" ")
	var time_only = time_parts[1] if time_parts.size() > 1 else data.timestamp
	var time_label = Label.new()
	time_label.text = time_only.substr(0, 5)  # HH:MM
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.add_theme_color_override("font_color", Color.GRAY)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.custom_minimum_size = Vector2(45, 20)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(time_label)
	
	# Adicionar ao container no TOPO (notificação mais recente em cima)
	notification_box.add_child(notification_item)
	notification_box.move_child(notification_item, 0)
	
	# Separator
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(0, 2)
	separator.modulate = Color(0.4, 0.4, 0.4, 0.5)
	notification_box.add_child(separator)
	notification_box.move_child(separator, 1)
	
	# Animação de entrada mais suave
	notification_item.modulate.a = 0.0
	notification_item.scale = Vector2(0.9, 0.9)
	
	var tween = create_tween()
	tween.parallel().tween_property(notification_item, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(notification_item, "scale", Vector2(1.0, 1.0), 0.4)

# =====================================
#  INPUT E DEBUG
# =====================================
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_SPACE:
			_on_pause_pressed()
		KEY_RIGHT:
			_on_next_month_pressed()
		KEY_F4:
			_debug_test_notifications()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var country_name = _detect_country_click(event.global_position)
		if not country_name.is_empty():
			show_country_info(country_name)

func _detect_country_click(global_pos: Vector2) -> String:
	var map = get_node_or_null("NodeMapaSVG2D")
	if not map:
		return ""
	for child in map.get_children():
		if child is Polygon2D:
			var local_pos = child.to_local(global_pos)
			if Geometry2D.is_point_in_polygon(local_pos, child.polygon):
				return child.name
	return ""

# =====================================
#  FUNÇÕES DE DEBUG
# =====================================
func _debug_test_notifications() -> void:
	print("🔧 DEBUG: Testando sistema de 3 notificações...")
	_add_notification("🔧 Teste 1", "Primeira notificação de teste", "info")
	_add_notification("✅ Teste 2", "Segunda notificação de teste", "success")
	_add_notification("⚠️ Teste 3", "Terceira notificação de teste", "warning")
	_add_notification("❌ Teste 4", "Quarta notificação (deve remover a primeira)", "error")
	_add_notification("ℹ️ Teste 5", "Quinta notificação (deve remover a segunda)", "info")

# =====================================
#  UTILITÁRIOS
# =====================================
func _format_number(num: int) -> String:
	if num >= 1_000_000:
		return "%.1fM" % (float(num) / 1_000_000.0)
	elif num >= 1_000:
		return "%.1fK" % (float(num) / 1_000.0)
	else:
		return str(num)

func get_current_date() -> String:
	return "%s/%d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]

func is_time_running() -> bool:
	return time_running
