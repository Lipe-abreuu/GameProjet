# =====================================
#  NotificationSystem.gd - COMPONENTE DE NOTIFICAÇÕES
#  Gerencia a criação, exibição e ciclo de vida das notificações.
# =====================================
extends Node

# =====================================
#  ENUM E CONFIGURAÇÕES
# =====================================
enum NotificationType { INFO, WARNING, SUCCESS, ERROR }
const MAX_NOTIFICATIONS: int = 3

# =====================================
#  REFERÊNCIAS E ESTADO
# =====================================
var notification_panel: PanelContainer
var notification_box: VBoxContainer
var notification_history: Array[Dictionary] = []

# =====================================
#  INICIALIZAÇÃO
# =====================================
func _ready() -> void:
	# Este nó se auto-configura ao ser adicionado à cena.
	print("🔧 Configurando sistema de notificações aprimorado...")
	
	# Aguarda um frame para garantir que a viewport esteja pronta
	await get_tree().process_frame
	
	# Procura por um painel existente ou cria um novo
	_setup_notification_panel()
	
	# Aplica o posicionamento e estilo
	_apply_positioning_and_style()
	
	print("✅ Sistema de notificações pronto!")

func _setup_notification_panel() -> void:
	notification_panel = _find_node_by_name(get_tree().root, "NotificationPanel")
	if notification_panel:
		notification_box = notification_panel.find_child("NotificationBox", true, false)
		if not notification_box:
			notification_box = VBoxContainer.new()
			notification_box.name = "NotificationBox"
			notification_panel.add_child(notification_box)
	else:
		_create_notification_panel()

func _create_notification_panel() -> void:
	print("🔧 NotificationPanel não encontrado, criando programaticamente...")
	notification_panel = PanelContainer.new()
	notification_panel.name = "NotificationPanel"
	
	# Adicionar a um CanvasLayer para garantir a renderização sobre tudo
	var canvas = get_tree().root.find_child("CanvasLayer", true, false)
	if canvas:
		canvas.add_child(notification_panel)
	else:
		# Como fallback, adiciona à raiz da cena
		get_tree().root.add_child(notification_panel)
		
	notification_box = VBoxContainer.new()
	notification_box.name = "NotificationBox"
	notification_panel.add_child(notification_box)

func _apply_positioning_and_style() -> void:
	if not notification_panel: return

	var viewport_size = get_viewport().get_visible_rect().size
	notification_panel.custom_minimum_size = Vector2(350, 0) # Largura fixa, altura automática
	notification_panel.size = notification_panel.custom_minimum_size
	
	var margin_right = 20
	var margin_top = 20
	var x_pos = viewport_size.x - notification_panel.size.x - margin_right
	var y_pos = margin_top
	notification_panel.position = Vector2(x_pos, y_pos)

	notification_panel.z_index = 100
	notification_panel.visible = true

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	style_box.border_width_left = 2
	style_box.border_color = Color(0.3, 0.5, 0.7, 0.9)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_bottom_left = 8
	notification_panel.add_theme_stylebox_override("panel", style_box)

# =====================================
#  API PÚBLICA
# =====================================
func show_notification(title: String, message: String, type: NotificationType = NotificationType.INFO, duration: float = 0.0) -> void:
	if not notification_box:
		print("❌ Erro: NotificationBox não está disponível!")
		return
	
	_enforce_notification_limit()
	
	var notification_data = {
		"title": title, "message": message, "type": type,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	notification_history.append(notification_data)
	if notification_history.size() > MAX_NOTIFICATIONS:
		notification_history.remove_at(0)

	var notification_item = _create_notification_item(notification_data)
	
	# Adiciona ao topo
	notification_box.add_child(notification_item)
	notification_box.move_child(notification_item, 0)
	
	# Animação de entrada
	var tween = create_tween()
	notification_item.modulate.a = 0.0
	notification_item.position.x = 50
	tween.parallel().tween_property(notification_item, "modulate:a", 1.0, 0.4).from(0.0)
	tween.parallel().tween_property(notification_item, "position:x", 0.0, 0.4).from(50.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	print("📋 Notificação: %s - %s" % [title, message])

# =====================================
#  LÓGICA INTERNA
# =====================================
func _enforce_notification_limit() -> void:
	while notification_box.get_child_count() >= MAX_NOTIFICATIONS:
		var oldest_notification = notification_box.get_child(notification_box.get_child_count() - 1)
		oldest_notification.queue_free()

func _create_notification_item(data: Dictionary) -> PanelContainer:
	var item = PanelContainer.new()
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 5

	match data.type:
		NotificationType.SUCCESS:
			style.bg_color = Color(0.1, 0.3, 0.15, 0.95)
			style.border_color = Color.PALE_GREEN
		NotificationType.WARNING:
			style.bg_color = Color(0.4, 0.3, 0.1, 0.95)
			style.border_color = Color.GOLD
		NotificationType.ERROR:
			style.bg_color = Color(0.5, 0.1, 0.1, 0.95)
			style.border_color = Color.CRIMSON
		_: # INFO
			style.bg_color = Color(0.1, 0.2, 0.4, 0.95)
			style.border_color = Color.SKY_BLUE

	item.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	item.add_child(margin)

	var vbox = VBoxContainer.new()
	margin.add_child(vbox)

	var title_label = Label.new()
	title_label.text = data.title
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_label)
	
	var message_label = Label.new()
	message_label.text = data.message
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	message_label.add_theme_font_size_override("font_size", 12)
	message_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	vbox.add_child(message_label)
	
	return item

func _find_node_by_name(root_node: Node, target_name: String) -> Node:
	if root_node.name == target_name:
		return root_node
	for child in root_node.get_children():
		var found = _find_node_by_name(child, target_name)
		if found:
			return found
	return null
