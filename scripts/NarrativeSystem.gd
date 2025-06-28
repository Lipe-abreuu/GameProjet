# res://scripts/NotificationSystem.gd - Versão Final Estável
extends Node

const NOTIFICATION_SCENE = preload("res://scenes/NotificationPanel.tscn")

var notification_queue: Array = []
var is_displaying: bool = false
var notification_container: CanvasLayer
var is_ready: bool = false

func setup(container: CanvasLayer):
	notification_container = container
	is_ready = true
	print(">>> Sistema de Notificações pronto. <<<")

func show_notification(title: String, message: String, _type: int = 0):
	notification_queue.append({"title": title, "message": message})

func _process(_delta):
	if not is_ready or is_displaying or notification_queue.is_empty():
		return

	is_displaying = true
	var notification_data = notification_queue.pop_front()
	
	if not is_instance_valid(notification_container):
		print("ERRO CRÍTICO: O container de notificações se tornou inválido.")
		is_displaying = false
		return

	var notification_instance = NOTIFICATION_SCENE.instantiate()
	notification_instance.notification_finished.connect(_on_notification_finished)
	notification_container.add_child(notification_instance)
	notification_instance.display(notification_data.title, notification_data.message)

func _on_notification_finished():
	is_displaying = false

func process_narrative_spread():
	pass

func check_narrative_consequences():
	pass

func create_narrative_from_action(action_name, party_data):
	pass
