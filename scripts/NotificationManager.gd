# res://scripts/NotificationManager.gd
# Versão corrigida com call_deferred para evitar o erro de "Parent node busy"

extends Node

const NotificationScene = preload("res://scenes/Notification.tscn")
const MAX_NOTIFICATIONS = 2

var notification_container
var queue = []

func _ready():
	# Cria um VBoxContainer para as notificações no canto da tela
	notification_container = VBoxContainer.new()
	notification_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	
	# CORREÇÃO APLICADA AQUI:
	# Usamos call_deferred para adicionar o nó à árvore principal de forma segura.
	get_tree().get_root().call_deferred("add_child", notification_container)
	
	notification_container.child_exiting_tree.connect(_on_notification_closed)

func show(message):
	if notification_container.get_child_count() >= MAX_NOTIFICATIONS:
		queue.append(message)
		return

	var notification = NotificationScene.instantiate()
	notification_container.add_child(notification)
	notification.set_text(message)

func _on_notification_closed(node):
	await get_tree().create_timer(0.1).timeout
	if !queue.is_empty():
		show(queue.pop_front())
