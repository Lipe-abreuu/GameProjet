# res://scripts/main.gd
# Versão completa, corrigida e refatorada.

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
# ATENÇÃO: Arraste cada nó da sua cena para o campo correspondente no Inspetor do Godot.
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
var notification_system: Node # Referência ao Autoload
var game_timer: Timer
var heat_ui: Control

# Enum do NotificationSystem
enum NotificationType { INFO, SUCCESS, ERROR }

# ===================================================================
# FUNÇÕES DE INICIALIZAÇÃO DO GODOT
# ===================================================================

func _ready():
	print("=== INICIALIZANDO JOGO ===")
	
	# Garante que os sistemas principais sejam criados antes de qualquer outra coisa.
	_create_systems()
	_setup_party()
	
	# Conecta todos os sinais após a criação dos sistemas.
	_connect_signals()
	
	# Inicia o jogo e atualiza a UI.
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
	# 1. Pega referência dos Singletons (Autoloads)
	notification_system = get_node("/root/NotificationSystem")
	
	# 2. Configura o NotificationSystem com o CanvasLayer
	# A verificação 'is_instance_valid' previne erros se o nó não for atribuído no editor.
	if is_instance_valid(notification_system) and is_instance_valid(canvas_layer):
		notification_system.setup(canvas_layer)
		print("✅ NotificationSystem configurado com CanvasLayer")
	else:
		print("❌ ERRO: NotificationSystem ou CanvasLayer não encontrados/atribuídos.")

	# 3. Cria o Timer Principal do Jogo
	game_timer = Timer.new()
	game_timer.name = "GameTimer"
	game_timer.wait_time = float(game_speed)
	add_child(game_timer) # Adiciona o timer à cena para que ele funcione

	# 4. Cria a Interface do 'Heat'
	var heat_ui_path = "res://scenes/HeatUIComponent.tscn"
	if ResourceLoader.exists(heat_ui_path):
		var heat_ui_scene = load(heat_ui_path)
		heat_ui = heat_ui_scene.instantiate()
		heat_ui.name = "HeatUI"
		if is_instance_valid(canvas_layer):
			canvas_layer.add_child(heat_ui)
		else:
			add_child(heat_ui) # Adiciona como fallback se o canvas não for encontrado
	else:
		print("⚠️ HeatUIComponent.tscn não encontrado")

func _setup_party():
	party_controller = preload("res://scripts/PartyController.gd").new()
	party_controller.name = "PartyController"
	add_child(party_controller)
	
	# Registra o party_controller no Globals.
	# Garanta que a variável 'party_controller' exista no script Globals.gd
	if Globals:
		Globals.party_controller = party_controller
		print("✅ PartyController criado e registrado no Globals")

func _connect_signals():
	# Conecta o sinal do timer principal
	if is_instance_valid(game_timer) and not game_timer.timeout.is_connected(_on_month_timer_timeout):
		game_timer.timeout.connect(_on_month_timer_timeout)

	# Conecta a UI ao Singleton HeatSystem de forma segura
	var heat_system = get_node_or_null("/root/HeatSystem")
	if is_instance_valid(heat_ui) and is_instance_valid(heat_system) and heat_ui.has_method("connect_to_heat_system"):
		heat_ui.connect_to_heat_system(heat_system)

	# Sinais do Controlador do Partido
	if is_instance_valid(party_controller):
		party_controller.treasury_changed.connect(_on_treasury_changed)
		party_controller.phase_advanced.connect(_on_phase_advanced)
		party_controller.support_changed.connect(_on_support_changed)
		party_controller.action_executed.connect(_on_action_executed)

	# Sinais dos Singletons Globais
	if is_instance_valid(heat_system):
		if not heat_system.raid_triggered.is_connected(_on_raid_triggered):
			heat_system.raid_triggered.connect(_on_raid_triggered)
		if heat_system.has_signal("close_call_triggered") and not heat_system.close_call_triggered.is_connected(_on_close_call):
			heat_system.close_call_triggered.connect(_on_close_call)

	# Sinais de eventos históricos
	var chile_events = get_node_or_null("/root/ChileEvents")
	if is_instance_valid(chile_events) and not chile_events.historical_event_notification.is_connected(_on_historical_event_notification):
		chile_events.historical_event_notification.connect(_on_historical_event_notification)

	# Sinais da UI (botões e mapa)
	_connect_ui_buttons()
	_connect_map_signals()


func _connect_ui_buttons():
	# Para cada botão, verificamos se o sinal 'pressed' JÁ NÃO ESTÁ CONECTADO antes de conectar.
	if is_instance_valid(pause_button) and not pause_button.pressed.is_connected(set_game_speed.bind(GameSpeed.PAUSED)):
		pause_button.pressed.connect(set_game_speed.bind(GameSpeed.PAUSED))
		
	if is_instance_valid(normal_speed_button) and not normal_speed_button.pressed.is_connected(set_game_speed.bind(GameSpeed.NORMAL)):
		normal_speed_button.pressed.connect(set_game_speed.bind(GameSpeed.NORMAL))
		
	if is_instance_valid(fast_speed_button) and not fast_speed_button.pressed.is_connected(set_game_speed.bind(GameSpeed.FAST)):
		fast_speed_button.pressed.connect(set_game_speed.bind(GameSpeed.FAST))
		
	if is_instance_valid(investigate_button) and not investigate_button.pressed.is_connected(_on_investigar_redes_pressed):
		investigate_button.pressed.connect(_on_investigar_redes_pressed)
		
	if is_instance_valid(narrativas_button) and not narrativas_button.pressed.is_connected(_on_narrativas_button_pressed):
		narrativas_button.pressed.connect(_on_narrativas_button_pressed)


func _start_game():
	# Agora é seguro iniciar o timer
	if is_instance_valid(game_timer):
		game_timer.start()
		print("=== JOGO INICIADO ===")
	
	if is_instance_valid(notification_system) and is_instance_valid(party_controller):
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
		if notification_system and notification_system.has_method("show_notification"):
			notification_system.show_notification("Novo Ano", "Chegamos a %d!" % current_year, NotificationType.INFO)

	if is_instance_valid(party_controller) and party_controller.has_method("advance_month"):
		party_controller.advance_month()

	var heat_system = get_node_or_null("/root/HeatSystem")
	if is_instance_valid(heat_system) and heat_system.has_method("process_monthly_turn"):
		heat_system.process_monthly_turn()

	var chile_events = get_node_or_null("/root/ChileEvents")
	if is_instance_valid(chile_events) and chile_events.has_method("check_for_events"):
		chile_events.check_for_events(current_year, current_month)

	# Só chama NarrativeSystem se for autoload e tiver os métodos corretos
	if Engine.has_singleton("NarrativeSystem"):
		var narrative = Engine.get_singleton("NarrativeSystem")
		if narrative.has_method("process_narrative_spread"):
			narrative.process_narrative_spread()
		if narrative.has_method("check_narrative_consequences"):
			narrative.check_narrative_consequences()

	if has_method("_update_all_ui"):
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
	if is_instance_valid(game_timer):
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
	if is_instance_valid(date_label):
		date_label.text = "%s %d" % [MONTH_NAMES[current_month - 1], current_year]
	
	if is_instance_valid(party_controller) and party_controller.party_data:
		_set_treasury_label(party_controller.party_data.treasury)
		_set_support_label(party_controller.party_data.get_average_support())
		_set_position_label(party_controller.party_data.get_phase_name())
		_set_militants_label(party_controller.party_data.militants)
		_set_influence_label(party_controller.party_data.influence)
	
	_update_speed_display()

func _set_treasury_label(new_val: int):
	if is_instance_valid(money_label):
		money_label.text = "Dinheiro: %d" % new_val

func _set_support_label(new_val: float):
	if is_instance_valid(support_label):
		support_label.text = "Apoio: %.1f%%" % new_val

func _set_position_label(new_pos: String):
	if is_instance_valid(position_label):
		position_label.text = "Posição: " + new_pos
		
func _set_militants_label(militants: int):
	if is_instance_valid(militants_label):
		militants_label.text = "Militantes: %d" % militants
		militants_label.add_theme_color_override("font_color", Color.WHITE if militants > 100 else Color.YELLOW if militants > 50 else Color.RED)

func _set_influence_label(influence: float):
	if is_instance_valid(influence_label):
		influence_label.text = "Influência: %.1f" % influence
		influence_label.add_theme_color_override("font_color", Color.LIGHT_BLUE if influence > 10 else Color.WHITE)

func _update_speed_display():
	if is_instance_valid(speed_label):
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
	if is_instance_valid(notification_system):
		notification_system.show_notification(
			"Partido Cresceu!",
			"A sua organização avançou de '%s' para '%s'!" % [old_pos, new_pos],
			NotificationType.SUCCESS
		)

func _on_support_changed(_group: String, _old_val: int, _new_val: int):
	if is_instance_valid(party_controller):
		_set_support_label(party_controller.get_average_support())

func _on_action_executed(action_name: String, success: bool, message: String):
	if is_instance_valid(notification_system):
		notification_system.show_notification(
			action_name,
			message,
			NotificationType.SUCCESS if success else NotificationType.ERROR
		)
	
	if success:
		var heat_system = get_node_or_null("/root/HeatSystem")
		if heat_system:
			heat_system.apply_heat_from_action(action_name, success)
	
	if is_instance_valid(party_controller):
		show_country_info(party_controller.party_data.country)

func _on_historical_event_notification(title: String, message: String, type: int):
	if is_instance_valid(notification_system):
		notification_system.show_notification(title, message, type)

func _on_narrative_consequence_triggered(group_name: String, narrative_content: String):
	if is_instance_valid(notification_system):
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
		if is_instance_valid(notification_system):
			notification_system.show_notification("Resultado da Batida", result.message, NotificationType.INFO)
	
	_update_all_ui()

func _on_close_call(event_type: String):
	# TODO: Implementar avisos de "close call"
	pass

# ===================================================================
# LÓGICA DE INTERAÇÃO COM A UI (MAPA E PAINÉIS)
# ===================================================================

func _connect_map_signals():
	if not is_instance_valid(map_node):
		print("❌ ERRO: O nó do mapa não foi atribuído no Inspetor.")
		return
	
	print("📍 Conectando sinais do mapa...")
	
	for country_node in map_node.get_children():
		# Pula nós que não são polígonos clicáveis
		if not country_node is Polygon2D:
			continue
			
		# Garante que a área de colisão exista
		var area_node = country_node.get_node_or_null("Area2D")
		if not is_instance_valid(area_node):
			print("  ⚠️ Criando Area2D para: %s" % country_node.name)
			area_node = Area2D.new()
			area_node.name = "Area2D"
			
			var collision = CollisionPolygon2D.new()
			collision.polygon = country_node.polygon
			area_node.add_child(collision)
			country_node.add_child(area_node)
		
		# Conecta o sinal de input na área
		if not area_node.is_connected("input_event", _on_country_clicked):
			area_node.input_event.connect(_on_country_clicked.bind(country_node.name))
			print("  ✅ Sinal conectado para %s" % country_node.name)

func _on_country_clicked(_viewport, event: InputEvent, _shape_idx, country_name: String):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		show_country_info(country_name)

func show_country_info(country_name: String):
	if not is_instance_valid(info_container):
		print("❌ ERRO: 'info_container' não foi atribuído no inspetor.")
		return
	
	# Limpa informações anteriores
	for child in info_container.get_children():
		child.queue_free()
	
	# Título
	var title_label = Label.new()
	title_label.text = country_name.to_upper()
	title_label.add_theme_font_size_override("font_size", 20)
	info_container.add_child(title_label)
	
	# Se for o país do jogador, mostrar informações do partido
	if country_name == "Chile" and is_instance_valid(party_controller):
		var party_info_label = Label.new()
		party_info_label.text = "\n🎯 SEU PARTIDO"
		party_info_label.add_theme_font_size_override("font_size", 16)
		party_info_label.add_theme_color_override("font_color", Color.CYAN)
		info_container.add_child(party_info_label)
		
		# Ações disponíveis
		var actions_title_label = Label.new()
		actions_title_label.text = "\nAÇÕES DISPONÍVEIS:"
		actions_title_label.add_theme_font_size_override("font_size", 14)
		info_container.add_child(actions_title_label)
		
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
	if is_instance_valid(party_controller):
		party_controller.execute_action(action_name)

func _on_narrativas_button_pressed():
	if not is_instance_valid(narrative_panel) or not is_instance_valid(info_container):
		print("ERRO: O painel de narrativas ou o container de informações não foi atribuído no inspetor.")
		return
	
	info_container.visible = false
	narrative_panel.visible = true
	
	var narrative_content_box = narrative_panel.get_node_or_null("VBoxContainer")
	if not is_instance_valid(narrative_content_box):
		narrative_content_box = VBoxContainer.new()
		narrative_panel.add_child(narrative_content_box)
	
	for c in narrative_content_box.get_children():
		c.queue_free()

	# --- TÍTULO DO PAINEL ---
	var title = Label.new()
	title.text = "NARRATIVAS EM CIRCULAÇÃO"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	narrative_content_box.add_child(title)
	narrative_content_box.add_child(HSeparator.new()) # Adiciona uma linha separadora
	
	var narrative_system = get_node_or_null("/root/NarrativeSystem")

	if not is_instance_valid(narrative_system) or not "active_narratives" in narrative_system or narrative_system.active_narratives.is_empty():
		var empty_label = Label.new()
		empty_label.text = "\nNenhuma narrativa significativa em circulação no momento."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		narrative_content_box.add_child(empty_label)
	else:
		# --- LOOP PARA CRIAR CADA ENTRADA DE NARRATIVA DE FORMA ORGANIZADA ---
		for narrative_data in narrative_system.active_narratives:
			# 1. Cria um VBox para cada entrada, para manter tudo junto
			var entry_vbox = VBoxContainer.new()
			narrative_content_box.add_child(entry_vbox)

			# 2. Cria a Label da narrativa
			var narrative_label = Label.new()
			narrative_label.text = "'%s' (Intensidade: %d)" % [narrative_data.content, narrative_data.intensity]
			narrative_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			# **A LINHA MAIS IMPORTANTE**: Manda a label ocupar todo o espaço horizontal, forçando a quebra de linha
			narrative_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			entry_vbox.add_child(narrative_label)
			
			# 3. Cria um HBox para os botões ficarem lado a lado
			var button_box = HBoxContainer.new()
			# Alinha os botões à direita para um visual mais limpo
			button_box.alignment = HBoxContainer.ALIGNMENT_END
			entry_vbox.add_child(button_box)
			
			var btn_amplify = Button.new()
			btn_amplify.text = "Amplificar"
			btn_amplify.pressed.connect(_on_amplify_narrative.bind(narrative_data))
			button_box.add_child(btn_amplify)
			
			var btn_counter = Button.new()
			btn_counter.text = "Criar Contra-Narrativa"
			btn_counter.pressed.connect(_on_create_counter_narrative.bind(narrative_data))
			button_box.add_child(btn_counter)
			
			# 4. Adiciona um separador entre as entradas de narrativas
			narrative_content_box.add_child(HSeparator.new())

func _on_investigar_redes_pressed():
	# Garante que temos as referências necessárias
	if not is_instance_valid(info_container):
		print("ERRO: 'info_container' não foi atribuído no inspetor.")
		return
		
	# Esconde o painel de narrativas e mostra o de informações
	if is_instance_valid(narrative_panel):
		narrative_panel.visible = false
	info_container.visible = true
	
	# Limpa o conteúdo antigo
	for c in info_container.get_children():
		c.queue_free()

	# Título
	var title = Label.new()
	title.text = "REDES DE PODER INVISÍVEIS"
	info_container.add_child(title)

	# Busca o sistema
	var power_networks_system = get_node_or_null("/root/PowerNetworks")
	if not is_instance_valid(power_networks_system):
		var error_label = Label.new()
		error_label.text = "ERRO: O sistema 'PowerNetworks' não foi encontrado."
		info_container.add_child(error_label)
		return

	if power_networks_system.hidden_networks.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Nenhuma rede suspeita encontrada."
		info_container.add_child(empty_label)
	else:
		for network_id in power_networks_system.hidden_networks:
			var network_data = power_networks_system.hidden_networks[network_id]
			
			var hbox = HBoxContainer.new()
			info_container.add_child(hbox)
			
			var network_label = Label.new()
			network_label.text = network_data.name if network_data.has("name") else network_id
			network_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(network_label)
			
			var btn_investigate = Button.new()
			btn_investigate.text = "Investigar"
			
			# === MUDANÇAS AQUI ===
			# 1. Conecta o sinal a uma nova função que vamos criar
			btn_investigate.pressed.connect(_on_investigate_network_button_pressed.bind(network_id))
			# 2. Garante que o botão não está mais desabilitado
			btn_investigate.disabled = false 
			# =======================
			
			hbox.add_child(btn_investigate)

# Agora, ADICIONE esta nova função no final do seu script main.gd

func _on_investigate_network_button_pressed(network_id: String):
	if is_instance_valid(notification_system):
		notification_system.show_notification(
			"Ação Indisponível",
			"A lógica para investigar a rede '%s' ainda não foi implementada." % network_id,
			NotificationType.INFO
		)
	print("Tentativa de investigar a rede: ", network_id)

func _on_amplify_narrative(narrative_data):
	if is_instance_valid(notification_system):
		notification_system.show_notification(
			"Ação Indisponível",
			"A lógica para amplificar a narrativa '%s' ainda não foi implementada." % narrative_data.content,
			NotificationType.INFO
		)
	print("Tentativa de amplificar a narrativa: ", narrative_data.content)

func _on_create_counter_narrative(narrative_data):
	if is_instance_valid(notification_system):
		notification_system.show_notification(
			"Ação Indisponível",
			"A lógica para criar uma contra-narrativa para '%s' ainda não foi implementada." % narrative_data.content,
			NotificationType.INFO
		)
	print("Tentativa de criar contra-narrativa para: ", narrative_data.content)
