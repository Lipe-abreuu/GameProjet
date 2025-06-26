# res://scripts/NotificationSystem.gd
extends Node

enum NotificationType { INFO, SUCCESS, ERROR }

var notification_container: VBoxContainer

func setup(canvas_layer: CanvasLayer):
	if not is_instance_valid(canvas_layer):
		printerr("NotificationSystem: CanvasLayer inválido.")
		return

	notification_container = VBoxContainer.new()
	notification_container.name = "NotificationPanel"
	notification_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	notification_container.position = Vector2(-320, 20)
	notification_container.size.x = 300
	notification_container.alignment = BoxContainer.ALIGNMENT_END
	
	canvas_layer.add_child(notification_container)
	print("✅ Sistema de notificações anexado ao CanvasLayer!")

func show_notification(title: String, message: String, type: NotificationType = NotificationType.INFO):
	if not is_instance_valid(notification_container):
		printerr("Não é possível mostrar notificação, o container não é válido.")
		return

	var panel = PanelContainer.new()
	var style_box = StyleBoxFlat.new()
	style_box.set_corner_radius_all(5)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	
	var vbox = VBoxContainer.new()
	
	var title_label = Label.new()
	title_label.text = title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	var message_label = Label.new()
	message_label.text = message
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	match type:
		NotificationType.SUCCESS:
			style_box.bg_color = Color(0.2, 0.5, 0.2, 0.9)
			# CORREÇÃO: A função correta é 'add_theme_color_override'
			title_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		NotificationType.ERROR:
			style_box.bg_color = Color(0.6, 0.2, 0.2, 0.9)
			# CORREÇÃO: A função correta é 'add_theme_color_override'
			title_label.add_theme_color_override("font_color", Color.PALE_VIOLET_RED)
		_: # INFO
			style_box.bg_color = Color(0.2, 0.3, 0.5, 0.9)
			# CORREÇÃO: A função correta é 'add_theme_color_override'
			title_label.add_theme_color_override("font_color", Color.LIGHT_CYAN)
			
	panel.add_theme_stylebox_override("panel", style_box)
	
	vbox.add_child(title_label)
	vbox.add_child(message_label)
	margin.add_child(vbox)
	panel.add_child(margin)
	
	notification_container.add_child(panel)
	
	var timer = get_tree().create_timer(5.0)
	await timer.timeout
	
	if is_instance_valid(panel):
		panel.queue_free()
