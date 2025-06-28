# res://scripts/HeatUIComponent.gd
# Componente de UI para mostrar o nível de heat/perseguição.
# Anexe este script ao nó raiz (um PanelContainer) da sua cena HeatUIComponent.tscn

extends PanelContainer

# =====================================
# REFERÊNCIAS DA UI (Expostas no Editor)
# =====================================
# Conecte estes nós no Inspetor do Godot, arrastando-os da árvore da cena
# para estes campos depois de anexar o script.
@export var heat_bar: ProgressBar
@export var heat_label: Label
@export var level_label: Label
@export var stars_container: HBoxContainer
@export var warning_panel: Panel

# =====================================
# RECURSOS E CONSTANTES
# =====================================
const STAR_EMPTY = "☆"
const STAR_FILLED = "★"
const MAX_STARS = 5

# =====================================
# FUNÇÃO DE CONEXÃO PRINCIPAL
# =====================================

# O main.gd chama esta função para ligar a UI ao sistema de lógica.
func connect_to_heat_system(heat_system_node: Node):
	if not is_instance_valid(heat_system_node):
		print("ERRO na UI do Heat: Tentativa de conectar a um HeatSystem inválido.")
		return

	# Conecta as funções deste script aos sinais emitidos pelo HeatSystem.
	# Usamos has_signal para evitar que o jogo quebre se um sinal for renomeado ou removido.
	if heat_system_node.has_signal("heat_changed"):
		heat_system_node.heat_changed.connect(_on_heat_changed)
	
	if heat_system_node.has_signal("heat_level_changed"):
		heat_system_node.heat_level_changed.connect(_on_level_changed)
	
	if heat_system_node.has_signal("raid_warning"):
		heat_system_node.raid_warning.connect(_on_raid_warning)

	if heat_system_node.has_signal("raid_triggered"):
		heat_system_node.raid_triggered.connect(_on_raid_triggered)

	if heat_system_node.has_signal("close_call_triggered"):
		heat_system_node.close_call_triggered.connect(_on_close_call)

	# Força a UI a se atualizar com os valores iniciais do sistema.
	if heat_system_node.has_method("get_heat_info"):
		var info = heat_system_node.get_heat_info()
		_update_display(info.current_heat, info.current_level, info.level_name)

# =====================================
# FUNÇÕES DE CALLBACK (Reagem aos Sinais)
# =====================================

func _on_heat_changed(_old_value: float, new_value: float):
	"""Atualiza a barra de progresso e o texto de porcentagem."""
	if heat_bar:
		heat_bar.value = new_value
	if heat_label:
		heat_label.text = "%.0f%%" % new_value

func _on_level_changed(_old_level: int, new_level: int):
	"""Atualiza as estrelas e o nome do nível de perseguição."""
	var heat_system = get_node_or_null("/root/HeatSystem")
	if not heat_system: return

	var level_name = heat_system.get_current_level_name()
	if level_label:
		level_label.text = level_name
	
	_update_stars(new_level)
	_flash_stars(Color.ORANGE_RED if new_level > _old_level else Color.GREEN)

func _on_raid_warning(turns_until: int):
	"""Mostra o painel de aviso de raid iminente."""
	if not warning_panel: return
	
	var warning_text_node = warning_panel.get_node_or_null("WarningText")
	if warning_text_node:
		warning_text_node.text = "AVISO DE INTELIGÊNCIA\nRAID POSSÍVEL EM %d MESES!" % turns_until
	
	warning_panel.visible = true
	var tween = create_tween()
	tween.tween_property(warning_panel, "modulate:a", 0.5, 0.4).set_loops(4).as_relative().set_trans(Tween.TRANS_SINE)
	tween.tween_callback(warning_panel.hide)

func _on_raid_triggered():
	"""Cria um flash vermelho na tela inteira para indicar a raid."""
	var flash = ColorRect.new()
	flash.color = Color(1.0, 0.0, 0.0, 0.5)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(flash)
	
	var tween = create_tween().set_ease(Tween.EASE_IN)
	tween.tween_property(flash, "color:a", 0.0, 0.6)
	tween.tween_callback(flash.queue_free)

func _on_close_call(event_type: String):
	"""Mostra um aviso rápido na tela para eventos de 'quase chamado'."""
	var messages = {
		"surveillance_spotted": "Vigilância detectada!",
		"phone_tapped": "Telefone pode estar grampeado!",
		"militant_followed": "Militante sendo seguido!",
		"strange_car": "Carro suspeito na rua!",
		"neighbor_asking": "Vizinho fazendo perguntas!"
	}
	var message = messages.get(event_type, "Atividade suspeita!")
	# Esta função pode criar um label que sobe e desaparece, por exemplo.

# =====================================
# FUNÇÕES AUXILIARES DE UI
# =====================================

func _update_display(heat: float, level: int, level_name: String):
	"""Função geral para atualizar todos os elementos da UI de uma só vez."""
	if heat_bar: heat_bar.value = heat
	if heat_label: heat_label.text = "%.0f%%" % heat
	if level_label: level_label.text = level_name
	_update_stars(level)

func _update_stars(level: int):
	"""Preenche as estrelas de acordo com o nível de perseguição."""
	if not stars_container: return
	
	var stars = stars_container.get_children()
	for i in range(stars.size()):
		var star_label = stars[i]
		if i < level:
			star_label.text = STAR_FILLED
			star_label.modulate = _get_star_color(level)
		else:
			star_label.text = STAR_EMPTY
			star_label.modulate = Color.GRAY

func _get_star_color(level: int) -> Color:
	"""Retorna a cor apropriada para o nível de perseguição."""
	match level:
		1: return Color.YELLOW
		2: return Color.GOLD
		3: return Color.ORANGE
		4: return Color.ORANGE_RED
		5: return Color.RED
		_: return Color.GRAY

func _flash_stars(color: Color):
	"""Anima um 'flash' nas estrelas para chamar a atenção."""
	if not stars_container: return
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(stars_container, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(stars_container, "modulate", color, 0.2)
	tween.tween_property(stars_container, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_property(stars_container, "modulate", Color.WHITE, 0.3)
