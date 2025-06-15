extends Control

# =====================================
#  CONSTANTES
# =====================================
const MONTH_NAMES := ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]

# =====================================
#  VARIÁVEIS DE ESTADO
# =====================================
var time_running := true
var player_agent: PlayerAgent = null
var current_phase: int = 1  # 1 = Agente, 2 = Presidente

# =====================================
#  NÓS DO JOGO
# =====================================
@onready var market = $Market
@onready var events = $Events
@onready var politics = $Politics
@onready var combat = $Combat

# =====================================
#  NÓS DA UI - USANDO ESTRUTURA EXISTENTE
# =====================================
@onready var date_label: Label = $CanvasLayer/TopBar/HBoxContainer/DateLabel
@onready var money_label: Label = $CanvasLayer/TopBar/HBoxContainer/MoneyLabel
@onready var stability_label: Label = $CanvasLayer/TopBar/HBoxContainer/StabilityLabel
@onready var pause_button: Button = $CanvasLayer/BottomBar/HBoxContainer/PauseButton
@onready var next_button: Button = $CanvasLayer/BottomBar/HBoxContainer/NextButton
@onready var info_container: VBoxContainer = $CanvasLayer/Sidepanel/InfoContainer

@onready var auto_timer: Timer = $AutoTimer

# =====================================
#  READY
# =====================================
func _ready() -> void:
        print("=== INICIANDO JOGO ===")

        _setup_timer()
        _setup_ui_styles()
        _connect_ui_buttons()
        _setup_country_clicks()

        _init_player_agent()
        _update_ui()
	
	print("Date Label: ", date_label != null)
	print("Money Label: ", money_label != null)
	print("Stability Label: ", stability_label != null)
	print("Pause Button: ", pause_button != null)
	print("Next Button: ", next_button != null)
	print("Info Container: ", info_container != null)
	
	# Mostrar informação inicial
	_show_country_info("Clique em um país para ver informações")
	
	# Sincronizar dados globais com sistema antigo
	_sync_global_data()
	
	print("=== JOGO INICIADO ===")

# =====================================
#  SINCRONIZAÇÃO COM SISTEMA CENTRALIZADO
# =====================================
func _sync_global_data() -> void:
	# Sincronizar tempo com Globals
	Globals.current_month = Globals.current_month
	Globals.current_year = Globals.current_year
	
	# Notificar outros sistemas para usarem Globals
	if politics and politics.has_method("use_global_data"):
		politics.use_global_data()
	if combat and combat.has_method("use_global_data"):
		combat.use_global_data()

# =====================================
#  CONFIGURAR ESTILOS DA UI
# =====================================
func _setup_ui_styles() -> void:
	# Configurar TopBar
	var top_bar = get_node_or_null("CanvasLayer/TopBar")
	if top_bar:
		var top_style = StyleBoxFlat.new()
		top_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
		top_style.border_width_bottom = 2
		top_style.border_color = Color(0.4, 0.4, 0.4)
		top_bar.add_theme_stylebox_override("panel", top_style)
	
	# Configurar BottomBar
	var bottom_bar = get_node_or_null("CanvasLayer/BottomBar")
	if bottom_bar:
		var bottom_style = StyleBoxFlat.new()
		bottom_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
		bottom_style.border_width_top = 2
		bottom_style.border_color = Color(0.4, 0.4, 0.4)
		bottom_bar.add_theme_stylebox_override("panel", bottom_style)
	
	# Configurar Sidepanel
	var side_panel = get_node_or_null("CanvasLayer/Sidepanel")
	if side_panel:
		var side_style = StyleBoxFlat.new()
		side_style.bg_color = Color(0.05, 0.05, 0.05, 0.95)
		side_style.border_width_left = 3
		side_style.border_color = Color(0.4, 0.4, 0.4)
		side_panel.add_theme_stylebox_override("panel", side_style)
	
	# Configurar HBoxContainer espaçamento
	var top_hbox = get_node_or_null("CanvasLayer/TopBar/HBoxContainer")
	if top_hbox:
		top_hbox.add_theme_constant_override("separation", 50)
	
	var bottom_hbox = get_node_or_null("CanvasLayer/BottomBar/HBoxContainer")
	if bottom_hbox:
		bottom_hbox.add_theme_constant_override("separation", 20)
	
	# Configurar spacers para expandir
	var spacers = [
		get_node_or_null("CanvasLayer/TopBar/HBoxContainer/Spacer1"),
		get_node_or_null("CanvasLayer/TopBar/HBoxContainer/Spacer2"),
		get_node_or_null("CanvasLayer/BottomBar/HBoxContainer/LeftSpacer"),
		get_node_or_null("CanvasLayer/BottomBar/HBoxContainer/RightSpacer")
	]
	
	for spacer in spacers:
		if spacer:
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

# =====================================
#  TIMER & BOTÕES
# =====================================
func _setup_timer() -> void:
	auto_timer.wait_time = 3.0
	auto_timer.timeout.connect(_on_auto_timer_timeout)
	auto_timer.start()

func _connect_ui_buttons() -> void:
        if pause_button:
                pause_button.text = "⏸ Pausar"
		pause_button.add_theme_font_size_override("font_size", 16)
		pause_button.custom_minimum_size = Vector2(120, 40)
		if not pause_button.pressed.is_connected(_on_pause_pressed):
			pause_button.pressed.connect(_on_pause_pressed)
	
	if next_button:
		next_button.text = "▶️ Próximo Mês"
		next_button.add_theme_font_size_override("font_size", 16)
		next_button.custom_minimum_size = Vector2(150, 40)
                if not next_button.pressed.is_connected(_on_next_month_pressed):
                        next_button.pressed.connect(_on_next_month_pressed)

func _init_player_agent():
        player_agent = PlayerAgent.new()
        player_agent.name = "Test Agent"
        player_agent.country = "Argentina"
        player_agent.background = "Intelectual"
        player_agent.ideology = "Social-Democrata"
        player_agent.charisma = 60
        player_agent.intelligence = 70
        player_agent.connections = 50
        player_agent.wealth = 40
        player_agent.military_knowledge = 30

        player_agent.support = {
                "military": 20,
                "business": 25,
                "intellectuals": 45,
                "workers": 35,
                "students": 40,
                "church": 15,
                "peasants": 20
        }

        Globals.player_country = player_agent.country

        print("👤 Agente político criado: %s" % player_agent.name)

# =====================================
#  CLIQUES NO MAPA
# =====================================
func _setup_country_clicks() -> void:
	var map := get_node_or_null("NodeMapaSVG2D")
	if map == null: 
		print("Aviso: NodeMapaSVG2D não encontrado")
		return
	
	for c in map.get_children():
		if c is CanvasItem:
			c.set_meta("country_name", c.name)

# Função para detectar cliques em Polygon2D manualmente
func _detect_polygon_click(global_pos: Vector2) -> String:
	var map := get_node_or_null("NodeMapaSVG2D")
	if map == null:
		return ""
	
	for c in map.get_children():
		if c is Polygon2D:
			# Converte posição global para local do polygon
			var local_pos = c.to_local(global_pos)
			# Verifica se o ponto está dentro do polígono
			if Geometry2D.is_point_in_polygon(local_pos, c.polygon):
				return c.get_meta("country_name", c.name)
	
	return ""

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
		auto_timer.start()
	else:
		auto_timer.stop()

func _on_next_month_pressed() -> void:
	if !time_running:
		_advance_month()

func _advance_month() -> void:
        # Avançar tempo global
        Globals.current_month += 1
        if Globals.current_month > 12:
                Globals.current_month = 1
                Globals.current_year += 1

        if current_phase == 1 and player_agent:
                _advance_agent_month()

	# Simulação passiva de todos os países
	Globals.simulate_monthly_changes()
	
	# Chance de evento aleatório
	if randi() % 100 < 15:  # 15% de chance por mês
		var countries = Globals.country_data.keys()
		var random_country = countries[randi() % countries.size()]
		Globals.apply_random_event(random_country)

	# Chamar sistemas antigos (se ainda existirem)
	if market and market.has_method("next_month"):
		market.next_month()
	if events and events.has_method("pick_random"):
		events.pick_random()
	if politics and politics.has_method("apply_shift"):
		politics.apply_shift(-1, 1)
	if politics and politics.has_method("check_revolution"):
		politics.check_revolution()
	if combat and combat.has_method("resolve_combat"):
		combat.resolve_combat()

	_update_ui()
	_update_map_colors()

# =====================================
#  UI REFRESH
# =====================================
func _update_ui() -> void:
        var money = 0
        var stability = 50
        var additional_info = ""

        if current_phase == 1 and player_agent:
                money = player_agent.wealth * 100
                stability = player_agent.get_total_support() / 7
                additional_info = " (%s)" % player_agent.current_position
        else:
                var player_data = Globals.get_player_data()
                money = player_data.get("money", 0)
                stability = player_data.get("stability", 50)

        if date_label and date_label is Label:
                date_label.text = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
                date_label.add_theme_color_override("font_color", Color.WHITE)

        if money_label and money_label is Label:
                if current_phase == 1:
                        money_label.text = "💰 Recursos: %d" % money
                else:
                        money_label.text = "$ %s" % _format_number(money)
                money_label.add_theme_color_override("font_color", Color.GREEN)

        if stability_label and stability_label is Label:
                if current_phase == 1:
                        stability_label.text = "📊 Apoio: %d%%%s" % [stability, additional_info]
                else:
                        stability_label.text = "Estabilidade: %d%%" % stability

                var color = Color.GREEN if stability > 70 else (Color.YELLOW if stability > 40 else Color.RED)
                stability_label.add_theme_color_override("font_color", color)

# Formatar números grandes
func _format_number(num: int) -> String:
	if num >= 1_000_000:
		return "%.1fM" % (num / 1_000_000.0)
	elif num >= 1_000:
		return "%.1fK" % (num / 1_000.0)
	else:
		return str(num)

# =====================================
#  ATUALIZAÇÃO VISUAL DO MAPA
# =====================================
func _update_map_colors() -> void:
	var map := get_node_or_null("NodeMapaSVG2D")
	if map == null:
		return
	
	for c in map.get_children():
		if c is Polygon2D:
			var country_name = c.get_meta("country_name", c.name)
			var country_data = Globals.get_country(country_name)
			
			if not country_data.is_empty():
				var stability = country_data.get("stability", 50)
				var gov_power = country_data.get("gov_power", 50)
				
				# Colorir baseado na estabilidade e poder governamental
				var color: Color
				if stability < 30:
					color = Color.RED  # Muito instável
				elif stability < 50:
					color = Color.ORANGE  # Instável
				elif stability < 70:
					color = Color.YELLOW  # Estável
				else:
					color = Color.GREEN  # Muito estável
				
				# Ajustar alpha baseado no poder governamental
				color.a = 0.3 + (gov_power / 100.0) * 0.4
				
				# Destacar país do jogador
				if country_name == Globals.player_country:
					color = color.lightened(0.3)
					c.texture_scale = Vector2(1.1, 1.1)
				else:
					c.texture_scale = Vector2(1.0, 1.0)
				
				c.color = color

# =====================================
#  INFO LATERAL - USANDO DADOS REAIS
# =====================================
func _show_country_info(country_name: String) -> void:
	if info_container == null:
		print("Aviso: info_container não encontrado")
		return
	
	# Limpa informações anteriores
	for child in info_container.get_children():
		child.queue_free()
	
	# Se for mensagem genérica
	if country_name.begins_with("Clique"):
		var instruction_label := Label.new()
		instruction_label.text = "🏛️ Clique Em Um País\nPara Ver Informações"
		instruction_label.add_theme_font_size_override("font_size", 20)
		instruction_label.add_theme_color_override("font_color", Color.GOLD)
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_container.add_child(instruction_label)
		return
	
	# Obter dados reais do país
	var country_data = Globals.get_country(country_name)
	if country_data.is_empty():
		var error_label := Label.new()
		error_label.text = "❌ País não encontrado:\n" + country_name
		error_label.add_theme_font_size_override("font_size", 16)
		error_label.add_theme_color_override("font_color", Color.RED)
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_container.add_child(error_label)
		return
	
	# === TÍTULO DO PAÍS ===
	var country_title_label := Label.new()
	country_title_label.text = "🏛️ " + country_name.capitalize()
	country_title_label.add_theme_font_size_override("font_size", 26)
	country_title_label.add_theme_color_override("font_color", Color.GOLD)
	country_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(country_title_label)
	
	# === INDICADOR DE PAÍS DO JOGADOR ===
	if country_name == Globals.player_country:
		var player_indicator := Label.new()
		player_indicator.text = "👑 SEU PAÍS"
		player_indicator.add_theme_font_size_override("font_size", 14)
		player_indicator.add_theme_color_override("font_color", Color.CYAN)
		player_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_container.add_child(player_indicator)
	
	# === SEÇÃO INFORMAÇÕES COM FUNDO ===
	var info_section_bg = Panel.new()
	info_section_bg.custom_minimum_size.y = 35
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.4, 0.6, 0.3)
	bg_style.corner_radius_top_left = 5
	bg_style.corner_radius_top_right = 5
	bg_style.corner_radius_bottom_left = 5
	bg_style.corner_radius_bottom_right = 5
	info_section_bg.add_theme_stylebox_override("panel", bg_style)
	
	var info_title_label := Label.new()
	info_title_label.text = "📊 Informações Gerais"
	info_title_label.add_theme_font_size_override("font_size", 18)
	info_title_label.add_theme_color_override("font_color", Color.CYAN)
	info_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_title_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_section_bg.add_child(info_title_label)
	
	info_container.add_child(info_section_bg)
	
	# === CONTAINER DAS INFORMAÇÕES ===
	var info_list_container = VBoxContainer.new()
	info_list_container.add_theme_constant_override("separation", 8)
	
	# Dados reais do país
	var population = country_data.get("population", 0)
	var gdp = country_data.get("gdp", 0)
	var stability = country_data.get("stability", 0)
	var industry = country_data.get("industry", 0)
	var agriculture = country_data.get("agriculture", 0)
	var defense = country_data.get("defense", 0)
	var money = country_data.get("money", 0)
	var gov_power = country_data.get("gov_power", 0)
	var rebel_power = country_data.get("rebel_power", 0)
	
	var info_data = [
		["👥", "População", _format_population(population)],
		["💰", "Dinheiro", "$" + _format_number(money)],
		["📈", "PIB", "$" + _format_gdp(gdp)], 
		["⚖️", "Estabilidade", str(stability) + "%"],
		["🏛️", "Gov. Power", str(gov_power) + "%"],
		["🔥", "Rebelião", str(rebel_power) + "%"],
		["🏭", "Indústria", str(industry) + "%"],
		["🌾", "Agricultura", str(agriculture) + "%"],
		["🛡️", "Defesa", str(defense) + "%"]
	]
	
	for data in info_data:
		# Container com fundo para cada linha
		var line_bg = Panel.new()
		line_bg.custom_minimum_size.y = 30
		var line_style = StyleBoxFlat.new()
		line_style.bg_color = Color(0.1, 0.1, 0.1, 0.2)
		line_bg.add_theme_stylebox_override("panel", line_style)
		
		var line_container = HBoxContainer.new()
		line_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		line_container.add_theme_constant_override("separation", 10)
		
		var icon_label = Label.new()
		icon_label.text = data[0] + " "
		icon_label.add_theme_font_size_override("font_size", 16)
		icon_label.custom_minimum_size.x = 35
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line_container.add_child(icon_label)
		
		var name_label = Label.new()
		name_label.text = data[1] + ":"
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.custom_minimum_size.x = 90
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line_container.add_child(name_label)
		
		var value_label = Label.new()
		value_label.text = data[2]
		value_label.add_theme_font_size_override("font_size", 15)
		
		# Colorir valores baseado no tipo
		var value_color = Color.LIGHT_GREEN
		if data[1] in ["Estabilidade", "Gov. Power"]:
			var val = int(data[2].replace("%", ""))
			value_color = Color.GREEN if val > 70 else (Color.YELLOW if val > 40 else Color.RED)
		elif data[1] == "Rebelião":
			var val = int(data[2].replace("%", ""))
			value_color = Color.RED if val > 60 else (Color.YELLOW if val > 30 else Color.GREEN)
		
		value_label.add_theme_color_override("font_color", value_color)
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line_container.add_child(value_label)
		
		line_bg.add_child(line_container)
		info_list_container.add_child(line_bg)
	
	info_container.add_child(info_list_container)
	
	# === SEÇÃO RELAÇÕES DIPLOMÁTICAS ===
	var relations_section_bg = Panel.new()
	relations_section_bg.custom_minimum_size.y = 35
	var relations_bg_style = StyleBoxFlat.new()
	relations_bg_style.bg_color = Color(0.4, 0.2, 0.6, 0.3)
	relations_bg_style.corner_radius_top_left = 5
	relations_bg_style.corner_radius_top_right = 5
	relations_bg_style.corner_radius_bottom_left = 5
	relations_bg_style.corner_radius_bottom_right = 5
	relations_section_bg.add_theme_stylebox_override("panel", relations_bg_style)
	
	var relations_title_label = Label.new()
	relations_title_label.text = "🤝 Relações Diplomáticas"
	relations_title_label.add_theme_font_size_override("font_size", 18)
	relations_title_label.add_theme_color_override("font_color", Color.MAGENTA)
	relations_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relations_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	relations_title_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	relations_section_bg.add_child(relations_title_label)
	
	info_container.add_child(relations_section_bg)
	
	# Lista de relações
	var relations_container = VBoxContainer.new()
	relations_container.add_theme_constant_override("separation", 5)
	
	for other_country in Globals.country_data.keys():
		if other_country != country_name:
			var relation_value = Globals.get_relation(country_name, other_country)
			
			var relation_bg = Panel.new()
			relation_bg.custom_minimum_size.y = 25
			var rel_style = StyleBoxFlat.new()
			rel_style.bg_color = Color(0.05, 0.05, 0.05, 0.2)
			relation_bg.add_theme_stylebox_override("panel", rel_style)
			
			var relation_line = HBoxContainer.new()
			relation_line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			relation_line.add_theme_constant_override("separation", 10)
			
			var flag_label = Label.new()
			flag_label.text = _get_country_flag(other_country)
			flag_label.add_theme_font_size_override("font_size", 14)
			flag_label.custom_minimum_size.x = 25
			flag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			relation_line.add_child(flag_label)
			
			var country_label = Label.new()
			country_label.text = other_country
			country_label.add_theme_font_size_override("font_size", 13)
			country_label.add_theme_color_override("font_color", Color.WHITE)
			country_label.custom_minimum_size.x = 80
			country_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			relation_line.add_child(country_label)
			
			var relation_label = Label.new()
			relation_label.text = str(relation_value)
			relation_label.add_theme_font_size_override("font_size", 13)
			
			# Colorir relação
			var rel_color = Color.GREEN if relation_value > 20 else (Color.YELLOW if relation_value > -20 else Color.RED)
			relation_label.add_theme_color_override("font_color", rel_color)
			relation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			relation_line.add_child(relation_label)
			
			relation_bg.add_child(relation_line)
			relations_container.add_child(relation_bg)
	
	info_container.add_child(relations_container)
	
	# === SEÇÃO AÇÕES COM FUNDO ===
	var actions_section_bg = Panel.new()
	actions_section_bg.custom_minimum_size.y = 35
	var actions_bg_style = StyleBoxFlat.new()
	actions_bg_style.bg_color = Color(0.6, 0.4, 0.2, 0.3)
	actions_bg_style.corner_radius_top_left = 5
	actions_bg_style.corner_radius_top_right = 5
	actions_bg_style.corner_radius_bottom_left = 5
	actions_bg_style.corner_radius_bottom_right = 5
	actions_section_bg.add_theme_stylebox_override("panel", actions_bg_style)
	
	var actions_title_label = Label.new()
	actions_title_label.text = "⚔️ Ações Disponíveis"
	actions_title_label.add_theme_font_size_override("font_size", 18)
	actions_title_label.add_theme_color_override("font_color", Color.YELLOW)
	actions_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	actions_title_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	actions_section_bg.add_child(actions_title_label)
	
	info_container.add_child(actions_section_bg)
	
	# === CONTAINER DOS BOTÕES ===
	var buttons_container = VBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 12)
	
	# Botões diferentes para país do jogador vs outros países
	if country_name == Globals.player_country:
		var player_button_data = [
			["🏛️ Governar", _on_govern_country],
			["💰 Investir", _on_invest_in_country],
			["🛡️ Fortificar", _on_fortify_country]
		]
		
		for data in player_button_data:
			var btn = Button.new()
			btn.text = data[0]
			btn.custom_minimum_size = Vector2(250, 45)
			btn.add_theme_font_size_override("font_size", 16)
			btn.pressed.connect(data[1].bind(country_name))
			buttons_container.add_child(btn)
	else:
		var action_button_data = [
			["🗡️ Atacar", _on_attack_country],
			["🤝 Negociar", _on_trade_with_country],
			["🕵️ Espionar", _on_spy_country]
		]
		
		for data in action_button_data:
			var btn = Button.new()
			btn.text = data[0]
			btn.custom_minimum_size = Vector2(250, 45)
			btn.add_theme_font_size_override("font_size", 16)
			btn.pressed.connect(data[1].bind(country_name))
			buttons_container.add_child(btn)
	
	info_container.add_child(buttons_container)

# =====================================
#  FUNÇÕES DE FORMATAÇÃO
# =====================================
func _format_population(pop: int) -> String:
	if pop >= 1_000_000:
		return "%.1fM" % (pop / 1_000_000.0)
	elif pop >= 1_000:
		return "%.1fK" % (pop / 1_000.0)
	else:
		return str(pop)

func _format_gdp(gdp: int) -> String:
	if gdp >= 1_000_000_000_000:
		return "%.1fT" % (gdp / 1_000_000_000_000.0)
	elif gdp >= 1_000_000_000:
		return "%.1fB" % (gdp / 1_000_000_000.0)
	elif gdp >= 1_000_000:
		return "%.1fM" % (gdp / 1_000_000.0)
	else:
		return str(gdp)

func _get_country_flag(country: String) -> String:
	match country:
		"Argentina": return "🇦🇷"
		"Brazil": return "🇧🇷"
		"Chile": return "🇨🇱"
		"Uruguay": return "🇺🇾"
		"Paraguay": return "🇵🇾"
		"Bolivia": return "🇧🇴"
		_: return "🏳️"

# =====================================
#  INPUT GLOBAL
# =====================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_pause_pressed()
	elif event.is_action_pressed("ui_right"):
		_on_next_month_pressed()
	elif event.is_action_pressed("ui_left"):
		# Salvar jogo
		Globals.save_game_data()
	elif event.is_action_pressed("ui_up"):
		# Carregar jogo
		Globals.load_game_data()
		_update_ui()
        elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
                # Detecta cliques em polígonos do mapa
                var country_name = _detect_polygon_click(event.global_position)
                if country_name != "":
                        _show_country_info(country_name)
        if OS.is_debug_build() and event is InputEventKey and event.pressed:
                match event.keycode:
                        KEY_F1:
                                if player_agent:
                                        player_agent.current_position = "Presidente"
                                        _transition_to_phase_2()
                        KEY_F2:
                                if player_agent:
                                        print("=== AGENTE DEBUG ===")
                                        print("Nome: %s" % player_agent.name)
                                        print("Posição: %s" % player_agent.current_position)
                                        print("Apoio Total: %d/700" % player_agent.get_total_support())
                                        print("Fase: %d" % current_phase)
                        KEY_F3:
                                if player_agent and current_phase == 1:
                                        for group in player_agent.support:
                                                player_agent.support[group] = min(100, player_agent.support[group] + 10)
                                        print("📈 Apoio aumentado!")

# =====================================
#  AÇÕES DO PAÍS DO JOGADOR
# =====================================
func _on_govern_country(country_name: String) -> void:
	print("Governando: ", country_name)
	Globals.adjust_country_value(country_name, "gov_power", randi_range(3, 8))
	Globals.adjust_country_value(country_name, "rebel_power", randi_range(-5, -2))
	Globals.adjust_country_value(country_name, "money", -500)
	_update_ui()
	_show_country_info(country_name)  # Refresh do painel

func _on_invest_in_country(country_name: String) -> void:
	print("Investindo em: ", country_name)
	var investment = randi_range(1000, 3000)
	Globals.adjust_country_value(country_name, "money", -investment)
	Globals.adjust_country_value(country_name, "industry", randi_range(2, 6))
	Globals.adjust_country_value(country_name, "stability", randi_range(1, 4))
	_update_ui()
	_show_country_info(country_name)

func _on_fortify_country(country_name: String) -> void:
	print("Fortificando: ", country_name)
	Globals.adjust_country_value(country_name, "defense", randi_range(3, 8))
	Globals.adjust_country_value(country_name, "money", -800)
	_update_ui()
	_show_country_info(country_name)

# =====================================
#  AÇÕES EM OUTROS PAÍSES
# =====================================
func _on_attack_country(country_name: String) -> void:
	print("Atacando: ", country_name)
	var player_defense = Globals.get_country_value(Globals.player_country, "defense", 10)
	var target_defense = Globals.get_country_value(country_name, "defense", 10)
	
	# Custo do ataque
	Globals.adjust_country_value(Globals.player_country, "money", -1500)
	
	# Resultado baseado na força relativa
	if player_defense > target_defense:
		# Vitória
		Globals.adjust_country_value(country_name, "gov_power", randi_range(-15, -8))
		Globals.adjust_country_value(country_name, "stability", randi_range(-12, -5))
		Globals.adjust_relation(Globals.player_country, country_name, randi_range(-25, -15))
		print("Vitória contra ", country_name)
	else:
		# Derrota
		Globals.adjust_country_value(Globals.player_country, "gov_power", randi_range(-8, -3))
		Globals.adjust_country_value(Globals.player_country, "stability", randi_range(-5, -2))
		Globals.adjust_relation(Globals.player_country, country_name, randi_range(-15, -8))
		print("Derrota contra ", country_name)
	
	_update_ui()
	_show_country_info(country_name)

func _on_trade_with_country(country_name: String) -> void:
	print("Negociando com: ", country_name)
	var relation = Globals.get_relation(Globals.player_country, country_name)
	
	# Benefício baseado na relação
	var trade_bonus = 200 + (relation * 5)  # Melhor relação = mais lucro
	
	Globals.adjust_country_value(Globals.player_country, "money", trade_bonus)
	Globals.adjust_country_value(country_name, "money", trade_bonus / 2)
	Globals.adjust_relation(Globals.player_country, country_name, randi_range(2, 8))
	
	print("Comércio rendeu $", trade_bonus)
	_update_ui()
	_show_country_info(country_name)

func _on_spy_country(country_name: String) -> void:
        print("Espiando: ", country_name)
        Globals.adjust_country_value(Globals.player_country, "money", -300)
	
	# Chance de descobrir informações valiosas
	if randi() % 100 < 30:  # 30% de chance
		var intel_value = randi_range(500, 1500)
		Globals.adjust_country_value(Globals.player_country, "money", intel_value)
		print("Espionagem descobriu informações valiosas! +$", intel_value)
	
	# Chance de ser descoberto
	if randi() % 100 < 20:  # 20% de chance
		Globals.adjust_relation(Globals.player_country, country_name, randi_range(-10, -5))
		print("Espionagem foi descoberta!")
	
	_update_ui()
        _show_country_info(country_name)

func _advance_agent_month():
        player_agent.political_experience += 1

        if randi() % 100 < 30:
                var groups = player_agent.support.keys()
                var random_group = groups[randi() % groups.size()]
                var gain = randi_range(1, 5)
                player_agent.support[random_group] = min(100, player_agent.support[random_group] + gain)
                print("📈 Ganhou %d de apoio com %s" % [gain, random_group])

        _check_position_advancement()

func _check_position_advancement():
        if not player_agent:
                return

        var total_support = player_agent.get_total_support()
        var old_position = player_agent.current_position
        var advanced = false

        match player_agent.current_position:
                "Cidad\u00e3o":
                        if total_support >= 50:
                                player_agent.current_position = "Ativista"
                                advanced = true
                "Ativista":
                        if total_support >= 100:
                                player_agent.current_position = "Deputado"
                                advanced = true
                "Deputado":
                        if total_support >= 150:
                                player_agent.current_position = "Senador"
                                advanced = true
                "Senador":
                        if total_support >= 200:
                                player_agent.current_position = "Ministro"
                                advanced = true
                "Ministro":
                        if total_support >= 250:
                                player_agent.current_position = "Presidente"
                                advanced = true
                                _transition_to_phase_2()

        if advanced:
                print("🎖️ %s avançou de %s para %s!" % [player_agent.name, old_position, player_agent.current_position])
                _show_advancement_popup(old_position, player_agent.current_position)

func _transition_to_phase_2():
        print("🏛️ TRANSIÇÃO PARA FASE 2: PRESIDENTE!")
        current_phase = 2

        var stability_bonus = (player_agent.get_total_support() - 175) / 5
        var money_bonus = player_agent.wealth * 1000

        Globals.adjust_country_value(player_agent.country, "stability", stability_bonus)
        Globals.adjust_country_value(player_agent.country, "money", money_bonus)

        _show_presidency_popup()

func _show_advancement_popup(old_pos: String, new_pos: String):
        var dialog = AcceptDialog.new()
        dialog.title = "🎖️ Avanço Político!"
        dialog.dialog_text = "Parabéns! %s avançou de %s para %s!" % [player_agent.name, old_pos, new_pos]
        add_child(dialog)
        dialog.popup_centered()
        dialog.confirmed.connect(dialog.queue_free)

func _show_presidency_popup():
        var dialog = AcceptDialog.new()
        dialog.title = "🏛️ PRESIDENTE ELEITO!"
        dialog.dialog_text = "🎉 %s conquistou a presidência de %s!\n\nAgora você controla o país diretamente." % [player_agent.name, player_agent.country]
        add_child(dialog)
        dialog.popup_centered()
        dialog.confirmed.connect(dialog.queue_free)

# =====================================
#  GETTERS - COMPATIBILIDADE COM SISTEMA ANTIGO
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
