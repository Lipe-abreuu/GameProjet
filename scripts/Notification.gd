# scripts/Notification.gd

extends PanelContainer

func _ready():
	# Cria um timer para a notificação se destruir sozinha após 4 segundos
	var timer = Timer.new()
	timer.wait_time = 4.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func set_text(message):
	# Assumindo que a cena Notification.tscn tem um Label como filho
	var label = get_node_or_null("Label")
	if label:
		label.text = message
