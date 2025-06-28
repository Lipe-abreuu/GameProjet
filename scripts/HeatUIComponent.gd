# res://scripts/HeatUIComponent.gd
# Componente de UI para mostrar o nível de heat/perseguição

extends Control

# =====================================
# REFERÊNCIAS DE UI
# =====================================
var heat_bar: ProgressBar
var heat_label: Label
var level_label: Label
var stars_container: HBoxContainer
var warning_panel: Panel

# =====================================
# RECURSOS
# =====================================
const STAR_EMPTY = "☆"
const STAR_FILLED = "★"
const MAX_STARS = 5

# =====================================
# SETUP
# =====================================

func _ready():
	_create_ui()
	_connect_to_heat_system()
	set_process(true)

func _create_ui():
	"""Cria a interface de heat programaticamente"""
	# Container principal
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	main_container.position = Vector2(-320, 100)
	main_container.size = Vector2(300, 120)
	add_child(main_container)
	
	# Painel de fundo
	var bg_panel = Panel.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	panel_style.border_width_all = 2
	panel_style.border_color = Color(0.8, 0.2, 0.2)
	panel_style.corner_radius_all = 5
	bg_panel.add_theme_stylebox_override("panel", panel_style)
	bg_panel.custom_minimum_size = Vector2(300, 120)
	main_container.add_child(bg_panel)
	
	# Container interno
	var inner_container = VBoxContainer.new()
	inner_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_container.add_theme_constant_override("margin_all", 10)
	bg_panel.add_child(inner_container)
	
	# Título
	var title = Label.new()
	title.text = "🔥 NÍVEL DE PERSEGUIÇÃO"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.ORANGE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_container.add_child(title)
	
	# Estrelas
	stars_container = HBoxContainer.new()
	stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_container.add_theme_constant_override("separation", 5)
	inner_container.add_child(stars_container)
	
	# Criar 5 labels de estrelas
	for i in range(MAX_STARS):
		var star = Label.new()
		star.text = STAR_EMPTY
		star.add_theme_font_size_override("font_size", 24)
		star.add_theme_color_override("font_color", Color.GRAY)
		stars_container.add_child(star)
	
	# Label do nível
	level_label = Label.new()
	level_label.text = "Desconhecido"
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_container.add_child(level_label)
	
	# Barra de progresso
	heat_bar = ProgressBar.new()
	heat_bar.custom_minimum_size = Vector2(280, 20)
	heat_bar.max_value = 100.0
	heat_bar.value = 0.0
	heat_bar.show_percentage = false
	
	# Estilo da barra
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.2, 0.2, 0.2)
	bar_style.corner_radius_all = 10
	heat_bar.add_theme_stylebox_override("background", bar_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.2, 0.2)
	fill_style.corner_radius_all = 10
	heat_bar.add_theme_stylebox_override("fill", fill_style)
	
	inner_container.add_child(heat_bar)
	
	# Label de porcentagem
	heat_label = Label.new()
	heat_label.text = "0%"
	heat_label.add_theme_font_size_override("font_size", 12)
	heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_container.add_child(heat_label)
	
	# Painel de aviso (inicialmente oculto)
	_create_warning_panel()

func _create_warning_panel():
	"""Cria painel de aviso de raid"""
	warning_panel = Panel.new()
	warning_panel.visible = false
	warning_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	warning_panel.size = Vector2(400, 150)
	warning_panel.position = Vector2(-200, -75)
	
	var warning_style = StyleBoxFlat.new()
	warning_style.bg_color = Color(0.8, 0.1, 0.1, 0.9)
	warning_style.border_width_all = 3
	warning_style.border_color = Color.WHITE
	warning_style.corner_radius_all = 10
	warning_panel.add_theme_stylebox_override("panel", warning_style)
	
	var warning_label = Label.new()
	warning_label.name = "WarningText"
	warning_label.text = "⚠️ AVISO DE INTELIGÊNCIA ⚠️\nRAID IMINENTE!"
	warning_label.add_theme_font_size_override("font_size", 20)
	warning_label.add_theme_color_override("font_color", Color.WHITE)
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	warning_panel.add_child(warning_label)
	
	add_child(warning_panel)

func _connect_to_heat_system():
	"""Conecta aos sinais do HeatSystem"""
	var heat_system = get_node_or_null("/root/HeatSystem")
	if heat_system:
		heat_system.heat_changed.connect(_on_heat_changed)
		heat_system.heat_level_changed.connect(_on_level_changed)
		heat_system.raid_warning.connect(_on_raid_warning)
		heat_system.raid_triggered.connect(_on_raid_triggered)
		heat_system.close_call_triggered.connect(_on_close_call)
		
		# Atualizar valores iniciais
		var info = heat_system.get_heat_info()
		_update_display(info.current_heat, info.current_level, info.level_name)

# =====================================
# CALLBACKS
# =====================================

func _on_heat_changed(_old_value: float, new_value: float):
	"""Atualiza quando heat muda"""
	heat_bar.value = new_value
	heat_label.text = "%.0f%%" % new_value
	
	# Animar barra se mudança significativa
	if abs(new_value - _old_value) > 5:
		_animate_heat_bar()

func _on_level_changed(_old_level: int, new_level: int):
	"""Atualiza quando nível muda"""
	var heat_system = get_node("/root/HeatSystem")
	var level_name = heat_system.get_current_level_name()
	
	_update_stars(new_level)
	level_label.text = level_name
	
	# Efeitos visuais para mudança de nível
	if new_level > _old_level:
		_flash_stars(Color.RED)
	else:
		_flash_stars(Color.GREEN)

func _on_raid_warning(turns_until: int):
	"""Mostra aviso de raid iminente"""
	warning_panel.visible = true
	var warning_text = warning_panel.get_node("WarningText")
	warning_text.text = "⚠️ INTELIGÊNCIA ⚠️\nRAID em %d turnos!" % turns_until
	
	# Animação de piscar
	var tween = create_tween()
	tween.set_loops(5)
	tween.tween_property(warning_panel, "modulate:a", 0.3, 0.3)
	tween.tween_property(warning_panel, "modulate:a", 1.0, 0.3)
	
	# Esconder após 3 segundos
	await get_tree().create_timer(3.0).timeout
	warning_panel.visible = false

func _on_raid_triggered():
	"""Efeito visual quando raid acontece"""
	# Flash vermelho na tela toda
	var flash = ColorRect.new()
	flash.color = Color(1, 0, 0, 0.6)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)
	
	# Som de sirene (se tiver sistema de áudio)
	# AudioManager.play_sound("siren")

func _on_close_call(event_type: String):
	"""Mostra evento de close call"""
	var messages = {
		"surveillance_spotted": "👁️ Vigilância detectada!",
		"phone_tapped": "📞 Telefone pode estar grampeado!",
		"militant_followed": "🚶 Militante sendo seguido!",
		"strange_car": "🚗 Carro suspeito na rua!",
		"neighbor_asking": "🏠 Vizinho fazendo perguntas!"
	}
	
	var message = messages.get(event_type, "⚠️ Atividade suspeita!")
	_show_quick_warning(message)

# =====================================
# FUNÇÕES AUXILIARES
# =====================================

func _update_display(heat: float, level: int, level_name: String):
	"""Atualiza toda a display"""
	heat_bar.value = heat
	heat_label.text = "%.0f%%" % heat
	level_label.text = level_name
	_update_stars(level)

func _update_stars(level: int):
	"""Atualiza as estrelas baseado no nível"""
	var stars = stars_container.get_children()
	for i in range(MAX_STARS):
		if i < level:
			stars[i].text = STAR_FILLED
			stars[i].add_theme_color_override("font_color", _get_star_color(level))
		else:
			stars[i].text = STAR_EMPTY
			stars[i].add_theme_color_override("font_color", Color.GRAY)

func _get_star_color(level: int) -> Color:
	"""Retorna cor baseada no nível"""
	match level:
		1: return Color.YELLOW
		2: return Color.ORANGE
		3: return Color.ORANGE_RED
		4: return Color.RED
		5: return Color.DARK_RED
		_: return Color.GRAY

func _animate_heat_bar():
	"""Anima a barra de heat"""
	var tween = create_tween()
	tween.tween_property(heat_bar, "modulate", Color(2, 2, 2), 0.2)
	tween.tween_property(heat_bar, "modulate", Color.WHITE, 0.2)

func _flash_stars(color: Color):
	"""Flash nas estrelas quando nível muda"""
	var tween = create_tween()
	for star in stars_container.get_children():
		tween.tween_property(star, "modulate", color, 0.2)
	tween.tween_interval(0.3)
	for star in stars_container.get_children():
		tween.tween_property(star, "modulate", Color.WHITE, 0.2)

func _show_quick_warning(message: String):
	"""Mostra aviso rápido que desaparece"""
	var quick_warning = Label.new()
	quick_warning.text = message
	quick_warning.add_theme_font_size_override("font_size", 16)
	quick_warning.add_theme_color_override("font_color", Color.YELLOW)
	quick_warning.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	quick_warning.position.y = 200
	add_child(quick_warning)
	
	var tween = create_tween()
	tween.tween_property(quick_warning, "position:y", 180, 0.5)
	tween.tween_interval(2.0)
	tween.tween_property(quick_warning, "modulate:a", 0.0, 0.5)
	tween.tween_callback(quick_warning.queue_free)
