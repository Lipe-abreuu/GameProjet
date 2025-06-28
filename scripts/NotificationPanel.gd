extends PanelContainer

@onready var label = $Label
var timer = Timer.new()

func _ready():
	timer.wait_time = 3.0 # A notificação desaparece após 3 segundos
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func show_message(message, type):
	label.text = message
	# Pode adicionar lógica para mudar a cor com base no 'type'
	match type:
		"warning":
			modulate = Color.YELLOW
		"error":
			modulate = Color.RED
		_:
			modulate = Color.WHITE
