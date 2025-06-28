# res://scripts/NotificationPanel.gd (Versão Simples e Segura)
extends PanelContainer

signal notification_finished

@export var title_label: Label
@export var message_label: Label
@export var lifetime_timer: Timer

func _ready():
	if is_instance_valid(lifetime_timer):
		if not lifetime_timer.timeout.is_connected(_on_lifetime_timer_timeout):
			lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)

func display(title: String, message: String):
	if is_instance_valid(title_label):
		title_label.text = title
	if is_instance_valid(message_label):
		message_label.text = message
	
	if is_instance_valid(lifetime_timer):
		lifetime_timer.start()

func _on_lifetime_timer_timeout():
	emit_signal("notification_finished")
	queue_free()
