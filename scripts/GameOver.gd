extends Control

# =====================================
#  REFERÊNCIAS DA UI (criadas dinamicamente)
# =====================================
var bg_rect: ColorRect
var container: VBoxContainer
var title_label: Label
var subtitle_label: Label
var button_container: HBoxContainer
var restart_button: Button
var quit_button: Button

# =====================================
#  CONSTANTES
# =====================================
const MONTH_NAMES := ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"]

# =====================================
#  READY
# =====================================
func _ready() -> void:
	print("🎮 GameOver screen inicializado")
	
	# Ocultar por padrão
	visible = false
	
	# Aguardar um frame
	await get_tree().process_frame
	
	# Criar UI programaticamente
	_create_ui()
	
	print("✅ GameOver screen pronto")

# =====================================
#  CRIAR UI PROGRAMATICAMENTE
# =====================================
func _create_ui() -> void:
	print("🛠️ Criando UI do GameOver...")
	
	# Limpar qualquer conteúdo existente
	for child in get_children():
		child.queue_free()
	
	# Aguardar limpeza
	await get_tree().process_frame
	
	# Configurar como fullscreen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Background semi-transparente
	bg_rect = ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.color = Color(0, 0, 0, 0.8)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)
	
	# Container principal centralizado
	container = VBoxContainer.new()
	container.name = "MainContainer"
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	container.custom_minimum_size = Vector2(600, 500)
	container.position = Vector2(-300, -250)  # Centralizar manualmente
	add_child(container)
	
	# Título principal
	title_label = Label.new()
	title_label.name = "Title"
	title_label.text = "🔥 REVOLUÇÃO!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color.RED)
	title_label.custom_minimum_size = Vector2(0, 80)
	container.add_child(title_label)
	
	# Espaçador pequeno
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	container.add_child(spacer1)
	
	# Subtítulo
	subtitle_label = Label.new()
	subtitle_label.name = "Subtitle"
	subtitle_label.text = "Seu governo foi deposto!"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color.YELLOW)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.custom_minimum_size = Vector2(0, 100)
	container.add_child(subtitle_label)
	
	# Espaçador maior
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	container.add_child(spacer2)
	
	# Container dos botões
	button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 30)
	container.add_child(button_container)
	
	# Botão Reiniciar
	restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "🔄 Reiniciar"
	restart_button.custom_minimum_size = Vector2(200, 70)
	restart_button.add_theme_font_size_override("font_size", 18)
	restart_button.pressed.connect(_on_restart_pressed)
	button_container.add_child(restart_button)
	
	# Botão Sair
	quit_button = Button.new()
	quit_button.name = "QuitButton"
	quit_button.text = "⏹️ Sair"
	quit_button.custom_minimum_size = Vector2(200, 70)
	quit_button.add_theme_font_size_override("font_size", 18)
	quit_button.pressed.connect(_on_quit_pressed)
	button_container.add_child(quit_button)
	
	print("✅ UI criada com sucesso")

# =====================================
#  MOSTRAR GAME OVER
# =====================================
func show_game_over() -> void:
	print("💀 === EXIBINDO GAME OVER ===")
	
	# Atualizar texto com informações atuais
	var current_date = "%s %d" % [MONTH_NAMES[Globals.current_month - 1], Globals.current_year]
	var country_name = Globals.player_country
	
	if subtitle_label:
		subtitle_label.text = "Seu governo foi deposto em %s!\nO país %s está em revolução!" % [current_date, country_name]
	
	# Mostrar a tela
	visible = true
	
	# Pausar o jogo
	get_tree().paused = true
	
	print("🎮 Game Over exibido - Jogo pausado")
	print("📅 Data da revolução: %s" % current_date)
	print("🏛️ País: %s" % country_name)

# =====================================
#  CALLBACKS DOS BOTÕES
# =====================================
func _on_restart_pressed() -> void:
	print("🔄 Reiniciando jogo...")
	
	# Despausar
	get_tree().paused = false
	
	# Resetar dados
	Globals.reset_game()
	
	# Recarregar cena
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	print("⏹️ Saindo do jogo...")
	
	# Despausar
	get_tree().paused = false
	
	# Sair
	get_tree().quit()

# =====================================
#  INPUT (teclas de atalho)
# =====================================
func _input(event: InputEvent) -> void:
	# Só processar input se estiver visível
	if not visible:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				_on_restart_pressed()
			KEY_Q, KEY_ESCAPE:
				_on_quit_pressed()

# =====================================
#  FUNÇÕES UTILITÁRIAS
# =====================================
func hide_game_over() -> void:
	visible = false
	get_tree().paused = false

func is_showing() -> bool:
	return visible

# =====================================
#  DEBUGGING
# =====================================
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	if not visible == false:
		warnings.append("GameOver deve começar invisível")
	return warnings
