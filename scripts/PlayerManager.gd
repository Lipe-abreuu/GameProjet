diff --git a/scenes/Main.gd b/scenes/Main.gd
index 7c26016cc26f5713e29bfa414b627e3aa418e13f..c36607da8c45efbe94f05923dde1d85943502a15 100644
--- a/scenes/Main.gd
+++ b/scenes/Main.gd
@@ -1,68 +1,72 @@
 extends Control
 
 # =====================================
 #  CONSTANTES
 # =====================================
 const MONTH_NAMES := ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]
 
 # =====================================
 #  VARIÁVEIS DE ESTADO
 # =====================================
 var time_running := true
+var player_agent: PlayerAgent = null
+var current_phase: int = 1  # 1 = Agente, 2 = Presidente
 
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
-	print("=== INICIANDO JOGO ===")
-	
-	_setup_timer()
-	_setup_ui_styles()
-	_connect_ui_buttons()
-	_setup_country_clicks()
-	_update_ui()
+        print("=== INICIANDO JOGO ===")
+
+        _setup_timer()
+        _setup_ui_styles()
+        _connect_ui_buttons()
+        _setup_country_clicks()
+
+        _init_player_agent()
+        _update_ui()
 	
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
diff --git a/scenes/Main.gd b/scenes/Main.gd
index 7c26016cc26f5713e29bfa414b627e3aa418e13f..c36607da8c45efbe94f05923dde1d85943502a15 100644
--- a/scenes/Main.gd
+++ b/scenes/Main.gd
@@ -110,63 +114,89 @@ func _setup_ui_styles() -> void:
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
-	if pause_button:
-		pause_button.text = "⏸ Pausar"
+        if pause_button:
+                pause_button.text = "⏸ Pausar"
 		pause_button.add_theme_font_size_override("font_size", 16)
 		pause_button.custom_minimum_size = Vector2(120, 40)
 		if not pause_button.pressed.is_connected(_on_pause_pressed):
 			pause_button.pressed.connect(_on_pause_pressed)
 	
 	if next_button:
 		next_button.text = "▶️ Próximo Mês"
 		next_button.add_theme_font_size_override("font_size", 16)
 		next_button.custom_minimum_size = Vector2(150, 40)
-		if not next_button.pressed.is_connected(_on_next_month_pressed):
-			next_button.pressed.connect(_on_next_month_pressed)
+                if not next_button.pressed.is_connected(_on_next_month_pressed):
+                        next_button.pressed.connect(_on_next_month_pressed)
+
+func _init_player_agent():
+        player_agent = PlayerAgent.new()
+        player_agent.name = "Test Agent"
+        player_agent.country = "Argentina"
+        player_agent.background = "Intelectual"
+        player_agent.ideology = "Social-Democrata"
+        player_agent.charisma = 60
+        player_agent.intelligence = 70
+        player_agent.connections = 50
+        player_agent.wealth = 40
+        player_agent.military_knowledge = 30
+
+        player_agent.support = {
+                "military": 20,
+                "business": 25,
+                "intellectuals": 45,
+                "workers": 35,
+                "students": 40,
+                "church": 15,
+                "peasants": 20
+        }
+
+        Globals.player_country = player_agent.country
+
+        print("👤 Agente político criado: %s" % player_agent.name)
 
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
diff --git a/scenes/Main.gd b/scenes/Main.gd
index 7c26016cc26f5713e29bfa414b627e3aa418e13f..c36607da8c45efbe94f05923dde1d85943502a15 100644
--- a/scenes/Main.gd
+++ b/scenes/Main.gd
@@ -175,104 +205,119 @@ func _detect_polygon_click(global_pos: Vector2) -> String:
 	
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
-	# Avançar tempo global
-	Globals.current_month += 1
-	if Globals.current_month > 12:
-		Globals.current_month = 1
-		Globals.current_year += 1
+        # Avançar tempo global
+        Globals.current_month += 1
+        if Globals.current_month > 12:
+                Globals.current_month = 1
+                Globals.current_year += 1
+
+        if current_phase == 1 and player_agent:
+                _advance_agent_month()
 
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
-	# Dados do jogador atual
-	var player_data = Globals.get_player_data()
-	
-	if date_label:
-		date_label.text = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
-		date_label.add_theme_font_size_override("font_size", 18)
-		date_label.add_theme_color_override("font_color", Color.WHITE)
-	
-	if money_label:
-		var money = player_data.get("money", 0)
-		money_label.text = "$ %s" % _format_number(money)
-		money_label.add_theme_font_size_override("font_size", 18)
-		money_label.add_theme_color_override("font_color", Color.GREEN)
-
-	if stability_label:
-		var stability = player_data.get("stability", 50)
-		stability_label.text = "Estabilidade: %d%%" % stability
-		stability_label.add_theme_font_size_override("font_size", 18)
-		var col: Color = Color.GREEN if stability > 70 else (Color.YELLOW if stability > 40 else Color.RED)
-		stability_label.add_theme_color_override("font_color", col)
+        var money = 0
+        var stability = 50
+        var additional_info = ""
+
+        if current_phase == 1 and player_agent:
+                money = player_agent.wealth * 100
+                stability = player_agent.get_total_support() / 7
+                additional_info = " (%s)" % player_agent.current_position
+        else:
+                var player_data = Globals.get_player_data()
+                money = player_data.get("money", 0)
+                stability = player_data.get("stability", 50)
+
+        if date_label and date_label is Label:
+                date_label.text = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
+                date_label.add_theme_color_override("font_color", Color.WHITE)
+
+        if money_label and money_label is Label:
+                if current_phase == 1:
+                        money_label.text = "💰 Recursos: %d" % money
+                else:
+                        money_label.text = "$ %s" % _format_number(money)
+                money_label.add_theme_color_override("font_color", Color.GREEN)
+
+        if stability_label and stability_label is Label:
+                if current_phase == 1:
+                        stability_label.text = "📊 Apoio: %d%%%s" % [stability, additional_info]
+                else:
+                        stability_label.text = "Estabilidade: %d%%" % stability
+
+                var color = Color.GREEN if stability > 70 else (Color.YELLOW if stability > 40 else Color.RED)
+                stability_label.add_theme_color_override("font_color", color)
 
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
diff --git a/scenes/Main.gd b/scenes/Main.gd
index 7c26016cc26f5713e29bfa414b627e3aa418e13f..c36607da8c45efbe94f05923dde1d85943502a15 100644
--- a/scenes/Main.gd
+++ b/scenes/Main.gd
@@ -603,55 +648,73 @@ func _format_gdp(gdp: int) -> String:
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
-	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
-		# Detecta cliques em polígonos do mapa
-		var country_name = _detect_polygon_click(event.global_position)
-		if country_name != "":
-			_show_country_info(country_name)
+        elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
+                # Detecta cliques em polígonos do mapa
+                var country_name = _detect_polygon_click(event.global_position)
+                if country_name != "":
+                        _show_country_info(country_name)
+        if OS.is_debug_build() and event is InputEventKey and event.pressed:
+                match event.keycode:
+                        KEY_F1:
+                                if player_agent:
+                                        player_agent.current_position = "Presidente"
+                                        _transition_to_phase_2()
+                        KEY_F2:
+                                if player_agent:
+                                        print("=== AGENTE DEBUG ===")
+                                        print("Nome: %s" % player_agent.name)
+                                        print("Posição: %s" % player_agent.current_position)
+                                        print("Apoio Total: %d/700" % player_agent.get_total_support())
+                                        print("Fase: %d" % current_phase)
+                        KEY_F3:
+                                if player_agent and current_phase == 1:
+                                        for group in player_agent.support:
+                                                player_agent.support[group] = min(100, player_agent.support[group] + 10)
+                                        print("📈 Apoio aumentado!")
 
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
diff --git a/scenes/Main.gd b/scenes/Main.gd
index 7c26016cc26f5713e29bfa414b627e3aa418e13f..c36607da8c45efbe94f05923dde1d85943502a15 100644
--- a/scenes/Main.gd
+++ b/scenes/Main.gd
@@ -680,59 +743,134 @@ func _on_attack_country(country_name: String) -> void:
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
-	print("Espiando: ", country_name)
-	Globals.adjust_country_value(Globals.player_country, "money", -300)
+        print("Espiando: ", country_name)
+        Globals.adjust_country_value(Globals.player_country, "money", -300)
 	
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
-	_show_country_info(country_name)
+        _show_country_info(country_name)
+
+func _advance_agent_month():
+        player_agent.political_experience += 1
+
+        if randi() % 100 < 30:
+                var groups = player_agent.support.keys()
+                var random_group = groups[randi() % groups.size()]
+                var gain = randi_range(1, 5)
+                player_agent.support[random_group] = min(100, player_agent.support[random_group] + gain)
+                print("📈 Ganhou %d de apoio com %s" % [gain, random_group])
+
+        _check_position_advancement()
+
+func _check_position_advancement():
+        if not player_agent:
+                return
+
+        var total_support = player_agent.get_total_support()
+        var old_position = player_agent.current_position
+        var advanced = false
+
+        match player_agent.current_position:
+                "Cidad\u00e3o":
+                        if total_support >= 50:
+                                player_agent.current_position = "Ativista"
+                                advanced = true
+                "Ativista":
+                        if total_support >= 100:
+                                player_agent.current_position = "Deputado"
+                                advanced = true
+                "Deputado":
+                        if total_support >= 150:
+                                player_agent.current_position = "Senador"
+                                advanced = true
+                "Senador":
+                        if total_support >= 200:
+                                player_agent.current_position = "Ministro"
+                                advanced = true
+                "Ministro":
+                        if total_support >= 250:
+                                player_agent.current_position = "Presidente"
+                                advanced = true
+                                _transition_to_phase_2()
+
+        if advanced:
+                print("🎖️ %s avançou de %s para %s!" % [player_agent.name, old_position, player_agent.current_position])
+                _show_advancement_popup(old_position, player_agent.current_position)
+
+func _transition_to_phase_2():
+        print("🏛️ TRANSIÇÃO PARA FASE 2: PRESIDENTE!")
+        current_phase = 2
+
+        var stability_bonus = (player_agent.get_total_support() - 175) / 5
+        var money_bonus = player_agent.wealth * 1000
+
+        Globals.adjust_country_value(player_agent.country, "stability", stability_bonus)
+        Globals.adjust_country_value(player_agent.country, "money", money_bonus)
+
+        _show_presidency_popup()
+
+func _show_advancement_popup(old_pos: String, new_pos: String):
+        var dialog = AcceptDialog.new()
+        dialog.title = "🎖️ Avanço Político!"
+        dialog.dialog_text = "Parabéns! %s avançou de %s para %s!" % [player_agent.name, old_pos, new_pos]
+        add_child(dialog)
+        dialog.popup_centered()
+        dialog.confirmed.connect(dialog.queue_free)
+
+func _show_presidency_popup():
+        var dialog = AcceptDialog.new()
+        dialog.title = "🏛️ PRESIDENTE ELEITO!"
+        dialog.dialog_text = "🎉 %s conquistou a presidência de %s!\n\nAgora você controla o país diretamente." % [player_agent.name, player_agent.country]
+        add_child(dialog)
+        dialog.popup_centered()
+        dialog.confirmed.connect(dialog.queue_free)
 
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
