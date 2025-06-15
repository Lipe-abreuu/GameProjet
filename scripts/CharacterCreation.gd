# =====================================
#  CHARACTERCREATION.GD - TELA DE CRIAÇÃO DE PERSONAGEM
#  Interface para criar o PlayerAgent antes do jogo começar
# =====================================
extends Control

# =====================================
#  SINAIS
# =====================================
signal character_created(agent: PlayerAgent)

# =====================================
#  OPÇÕES DE CRIAÇÃO
# =====================================
const COUNTRIES = ["Argentina", "Chile", "Uruguai", "Paraguai", "Bolívia"]
const BACKGROUNDS = {
	"Militar": "Ex-oficial das Forças Armadas. +Militar +Conhecimento Militar -Trabalhadores",
	"Intelectual": "Professor ou jornalista. +Intelectuais +Estudantes +Inteligência",
	"Sindicalista": "Líder dos trabalhadores. +Trabalhadores +Camponeses +Carisma -Empresários",
	"Empresário": "Homem de negócios. +Empresários +Riqueza +Contatos -Trabalhadores",
	"Estudante": "Jovem ativista universitário. +Estudantes +Intelectuais +Carisma"
}
const IDEOLOGIES = {
	"DSN": "Doutrina de Segurança Nacional. Anticomunista, pró-militar, apoio dos EUA.",
	"Neoliberal": "Livre mercado e democracia liberal. Apoio empresarial e americano.",
	"Social-Democrata": "Democracia com justiça social. Posição moderada equilibrada.",
	"Marxista": "Revolução socialista. Apoio dos trabalhadores e URSS. Alto risco.",
	"Populista": "Poder ao povo. Carisma popular, mas economicamente instável."
}

# =====================================
#  ELEMENTOS DA UI
# =====================================
var name_input: LineEdit
var age_spinbox: SpinBox
var country_option: OptionButton
var background_option: OptionButton
var ideology_option: OptionButton
var background_description: RichTextLabel
var ideology_description: RichTextLabel
var stats_preview: RichTextLabel
var create_button: Button
var preset_buttons: HBoxContainer

# PlayerAgent sendo criado
var current_agent: PlayerAgent

# =====================================
#  INICIALIZAÇÃO
# =====================================
func _ready():
	_setup_ui()
	_create_default_agent()
	_update_preview()

func _setup_ui():
	# Container principal
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	
	# Título
	var title = Label.new()
	title.text = "🏛️ CRIAÇÃO DE PERSONAGEM - CONE SUL 1973"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "De agente político a presidente: sua jornada pelo poder na Guerra Fria"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(subtitle)
	
	main_vbox.add_child(HSeparator.new())
	
	# Container horizontal para dados e preview
	var h_container = HBoxContainer.new()
	main_vbox.add_child(h_container)
	
	# Painel esquerdo - Dados básicos
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(400, 0)
	h_container.add_child(left_panel)
	
	_setup_basic_data(left_panel)
	_setup_background_selection(left_panel)
	_setup_ideology_selection(left_panel)
	_setup_presets(left_panel)
	
	# Painel direito - Preview
	var right_panel = VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(350, 0)
	h_container.add_child(right_panel)
	
	_setup_preview(right_panel)
	_setup_create_button(main_vbox)

func _setup_basic_data(parent: VBoxContainer):
	# Nome
	var name_group = VBoxContainer.new()
	parent.add_child(name_group)
	
	var name_label = Label.new()
	name_label.text = "👤 Nome do Personagem:"
	name_group.add_child(name_label)
	
	name_input = LineEdit.new()
	name_input.placeholder_text = "Digite o nome do seu agente político"
	name_input.text_changed.connect(_on_name_changed)
	name_group.add_child(name_input)
	
	# Idade
	var age_group = HBoxContainer.new()
	parent.add_child(age_group)
	
	var age_label = Label.new()
	age_label.text = "📅 Idade em 1973:"
	age_label.custom_minimum_size.x = 120
	age_group.add_child(age_label)
	
	age_spinbox = SpinBox.new()
	age_spinbox.min_value = 25
	age_spinbox.max_value = 50
	age_spinbox.value = 30
	age_spinbox.value_changed.connect(_on_age_changed)
	age_group.add_child(age_spinbox)
	
	# País
	var country_group = VBoxContainer.new()
	parent.add_child(country_group)
	
	var country_label = Label.new()
	country_label.text = "🌎 País de Origem:"
	country_group.add_child(country_label)
	
	country_option = OptionButton.new()
	for country in COUNTRIES:
		country_option.add_item(country)
	country_option.item_selected.connect(_on_country_changed)
	country_group.add_child(country_option)

func _setup_background_selection(parent: VBoxContainer):
	parent.add_child(HSeparator.new())
	
	var bg_label = Label.new()
	bg_label.text = "🎓 Background Profissional:"
	bg_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(bg_label)
	
	background_option = OptionButton.new()
	for bg in BACKGROUNDS.keys():
		background_option.add_item(bg)
	background_option.item_selected.connect(_on_background_changed)
	parent.add_child(background_option)
	
	background_description = RichTextLabel.new()
	background_description.custom_minimum_size = Vector2(380, 60)
	background_description.fit_content = true
	background_description.bbcode_enabled = true
	parent.add_child(background_description)

func _setup_ideology_selection(parent: VBoxContainer):
	parent.add_child(HSeparator.new())
	
	var ideology_label = Label.new()
	ideology_label.text = "⚖️ Ideologia Política:"
	ideology_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(ideology_label)
	
	ideology_option = OptionButton.new()
	for ideology in IDEOLOGIES.keys():
		ideology_option.add_item(ideology)
	ideology_option.item_selected.connect(_on_ideology_changed)
	parent.add_child(ideology_option)
	
	ideology_description = RichTextLabel.new()
	ideology_description.custom_minimum_size = Vector2(380, 60)
	ideology_description.fit_content = true
	ideology_description.bbcode_enabled = true
	parent.add_child(ideology_description)

func _setup_presets(parent: VBoxContainer):
	parent.add_child(HSeparator.new())
	
	var presets_label = Label.new()
	presets_label.text = "🎭 Personagens Pré-definidos:"
	presets_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(presets_label)
	
	preset_buttons = HBoxContainer.new()
	parent.add_child(preset_buttons)
	
	var presets = [
		{"name": "Coronel", "preset": "militar_conservador"},
		{"name": "Professor", "preset": "intelectual_democrata"},
		{"name": "Sindicalista", "preset": "sindicalista_marxista"},
		{"name": "Empresário", "preset": "empresario_neoliberal"},
		{"name": "Estudante", "preset": "estudante_populista"}
	]
	
	for preset_data in presets:
		var btn = Button.new()
		btn.text = preset_data["name"]
		btn.custom_minimum_size = Vector2(70, 30)
		btn.pressed.connect(_on_preset_selected.bind(preset_data["preset"]))
		preset_buttons.add_child(btn)

func _setup_preview(parent: VBoxContainer):
	var preview_label = Label.new()
	preview_label.text = "📊 Preview dos Atributos:"
	preview_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(preview_label)
	
	stats_preview = RichTextLabel.new()
	stats_preview.custom_minimum_size = Vector2(350, 400)
	stats_preview.bbcode_enabled = true
	parent.add_child(stats_preview)

func _setup_create_button(parent: VBoxContainer):
	parent.add_child(HSeparator.new())
	
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(button_container)
	
	create_button = Button.new()
	create_button.text = "🚀 INICIAR JORNADA POLÍTICA"
	create_button.custom_minimum_size = Vector2(250, 50)
	create_button.add_theme_font_size_override("font_size", 16)
	create_button.pressed.connect(_on_create_character)
	button_container.add_child(create_button)

# =====================================
#  CALLBACKS DOS CONTROLES
# =====================================
func _on_name_changed(new_name: String):
	current_agent.name = new_name
	_update_preview()

func _on_age_changed(new_age: float):
	current_agent.age = int(new_age)
	_update_preview()

func _on_country_changed(index: int):
	current_agent.country = COUNTRIES[index]
	_update_preview()

func _on_background_changed(index: int):
	var bg_keys = BACKGROUNDS.keys()
	current_agent.background = bg_keys[index]
	current_agent._apply_background_modifiers()
	_update_descriptions()
	_update_preview()

func _on_ideology_changed(index: int):
	var ideology_keys = IDEOLOGIES.keys()
	current_agent.ideology = ideology_keys[index]
	current_agent._apply_ideology_modifiers()
	_update_descriptions()
	_update_preview()

func _on_preset_selected(preset: String):
	var preset_agent = PlayerAgent.create_preset_character(preset, COUNTRIES[country_option.selected])
	current_agent = preset_agent
	
	# Atualizar controles
	name_input.text = current_agent.name
	age_spinbox.value = current_agent.age
	
	# Encontrar índices corretos
	var bg_index = BACKGROUNDS.keys().find(current_agent.background)
	if bg_index >= 0:
		background_option.selected = bg_index
	
	var ideology_index = IDEOLOGIES.keys().find(current_agent.ideology)
	if ideology_index >= 0:
		ideology_option.selected = ideology_index
	
	_update_descriptions()
	_update_preview()

func _on_create_character():
	if current_agent.name.is_empty():
		_show_error("Digite um nome para o personagem!")
		return
	
	# Emitir sinal com o agente criado
	character_created.emit(current_agent)
	
	# Esconder esta tela
	visible = false

# =====================================
#  ATUALIZAÇÃO DA INTERFACE
# =====================================
func _create_default_agent():
	current_agent = PlayerAgent.new()
	current_agent.name = ""
	current_agent.age = 30
	current_agent.country = COUNTRIES[0]
	current_agent.background = BACKGROUNDS.keys()[0]
	current_agent.ideology = IDEOLOGIES.keys()[2]  # Social-Democrata como padrão

func _update_descriptions():
	# Atualizar descrição do background
	var bg_text = "[b]%s[/b]\n%s" % [current_agent.background, BACKGROUNDS[current_agent.background]]
	background_description.text = bg_text
	
	# Atualizar descrição da ideologia
	var ideology_text = "[b]%s[/b]\n%s" % [current_agent.ideology, IDEOLOGIES[current_agent.ideology]]
	ideology_description.text = ideology_text

func _update_preview():
	var preview_text = "[center][b]📋 %s[/b][/center]\n" % current_agent.name.to_upper()
	preview_text += "[center]%s, %d anos - %s[/center]\n\n" % [current_agent.country, current_agent.age, current_agent.current_position]
	
	# Atributos pessoais
	preview_text += "[b]🎯 Atributos Pessoais:[/b]\n"
	preview_text += "💬 Carisma: %d/100\n" % current_agent.charisma
	preview_text += "🧠 Inteligência: %d/100\n" % current_agent.intelligence
	preview_text += "🤝 Contatos: %d/100\n" % current_agent.connections
	preview_text += "💰 Riqueza: %d/100\n" % current_agent.wealth
	preview_text += "⚔️ Conhecimento Militar: %d/100\n\n" % current_agent.military_knowledge
	
	# Apoio por grupos
	preview_text += "[b]👥 Apoio dos Grupos:[/b]\n"
	for group_name in current_agent.support:
		var value = current_agent.support[group_name]
		var color = _get_support_color(value)
		var emoji = _get_group_emoji(group_name)
		preview_text += "%s %s: [color=%s]%d/100[/color]\n" % [emoji, group_name.capitalize(), color, value]
	
	preview_text += "\n[b]🌍 Influência das Superpotências:[/b]\n"
	var usa_color = _get_support_color(current_agent.usa_influence)
	var ussr_color = _get_support_color(current_agent.ussr_influence)
	preview_text += "🇺🇸 EUA: [color=%s]%d/100[/color]\n" % [usa_color, current_agent.usa_influence]
	preview_text += "🇷🇺 URSS: [color=%s]%d/100[/color]\n\n" % [ussr_color, current_agent.ussr_influence]
	
	# Apoio total e requisitos
	var total_support = current_agent.get_total_support()
	var required_next = current_agent.get_required_support_for_next_position()
	var next_position = current_agent.get_next_position()
	
	preview_text += "[b]📈 Progressão Política:[/b]\n"
	preview_text += "Apoio Total: [color=%s]%d/700[/color]\n" % [_get_support_color(total_support/7), total_support]
	if next_position != current_agent.current_position:
		preview_text += "Para %s: %d apoio necessário\n" % [next_position, required_next]
	
	# Riscos especiais
	if current_agent.condor_target_level > 0:
		preview_text += "\n[color=red]⚠️ Risco Operação Condor: %d/100[/color]\n" % current_agent.condor_target_level
	
	stats_preview.text = preview_text

func _get_support_color(value: int) -> String:
	if value >= 70:
		return "green"
	elif value >= 40:
		return "yellow"
	elif value >= 20:
		return "orange"
	else:
		return "red"

func _get_group_emoji(group: String) -> String:
	match group:
		"military": return "⚔️"
		"business": return "💼"
		"intellectuals": return "🎓"
		"workers": return "🔨"
		"students": return "📚"
		"church": return "⛪"
		"peasants": return "🌾"
		_: return "👥"

func _show_error(message: String):
	# Criar popup de erro simples
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Erro"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

# =====================================
#  VALIDAÇÃO E UTILIDADES
# =====================================
func validate_character() -> bool:
	if current_agent.name.is_empty():
		return false
	if current_agent.country.is_empty():
		return false
	return true

func get_character_summary() -> String:
	return current_agent.get_summary()

# =====================================
#  INTEGRAÇÃO COM O JOGO PRINCIPAL
# =====================================
func show_creation_screen():
	visible = true
	_create_default_agent()
	_update_descriptions()
	_update_preview()

func hide_creation_screen():
	visible = false

# Para usar na scene principal
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	if not character_created.is_connected(_on_character_ready):
		warnings.append("Conecte o sinal character_created ao jogo principal")
	return warnings

# Callback de exemplo para integração
func _on_character_ready(agent: PlayerAgent):
	print("✅ Personagem criado: %s" % agent.name)
	print("📍 País: %s" % agent.country)
	print("🎭 Background: %s" % agent.background)
	print("⚖️ Ideologia: %s" % agent.ideology)
