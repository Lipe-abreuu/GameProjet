# res://scripts/NotificationSystem.gd
# Este script deve estar anexado ao nó raiz da sua cena NotificationPanel.tscn,
# e essa cena DEVE ser registada como um singleton em Autoload.

extends CanvasLayer

# Enum para os tipos de notificação.
enum NotificationType { INFO, SUCCESS, ERROR }

# --- Acesso Global ao Enum ---
# Esta variável torna o enum acessível a partir de outros scripts
# através de `NotificationSystem.TYPE.SUCCESS`, etc.
var TYPE = NotificationType

# --- Referências aos Nós da Cena ---
@onready var title_label: Label = $TitleLabel
@onready var message_label: Label = $MessageLabel
@onready var timer: Timer = $Timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# --- Variáveis Internas ---
var _notification_queue: Array = []
var _is_showing := false
var _ready_done := false
var notification_duration := 5.0

func _ready() -> void:
	# Verificação de robustez para garantir que a cena está configurada corretamente.
	var all_nodes_found = true
	if not is_instance_valid(title_label):
		print("ERRO DE CENA: Nó 'TitleLabel' não encontrado em NotificationPanel.tscn.")
		all_nodes_found = false
	if not is_instance_valid(message_label):
		print("ERRO DE CENA: Nó 'MessageLabel' não encontrado em NotificationPanel.tscn.")
		all_nodes_found = false
	if not is_instance_valid(timer):
		print("ERRO DE CENA: Nó 'Timer' não encontrado em NotificationPanel.tscn.")
		all_nodes_found = false
	if not is_instance_valid(animation_player):
		print("ERRO DE CENA: Nó 'AnimationPlayer' não encontrado em NotificationPanel.tscn.")
		all_nodes_found = false

	if not all_nodes_found:
		print("!! NotificationSystem desativado devido a nós em falta.")
		set_process(false)
		return

	print("✅ NotificationSystem iniciado com sucesso.")
	_ready_done = true
	# Processa qualquer notificação que tenha sido chamada antes de o nó estar pronto.
	if not _notification_queue.is_empty():
		_play_next_notification()

func show_notification(title: String, msg: String, type: int = NotificationType.INFO) -> void:
	# Adiciona à fila, mesmo que não esteja pronto. O _ready() tratará disso.
	_notification_queue.append({"title": title, "message": msg, "type": type})
	if _ready_done and not _is_showing:
		_play_next_notification()

func _play_next_notification() -> void:
	if not _ready_done or _notification_queue.is_empty():
		_is_showing = false
		return

	_is_showing = true
	var notification_data = _notification_queue.pop_front()

	title_label.text = notification_data.title
	message_label.text = notification_data.message

	match notification_data.type:
		NotificationType.SUCCESS:
			title_label.modulate = Color.GREEN
		NotificationType.ERROR:
			title_label.modulate = Color.RED
		_:
			title_label.modulate = Color.WHITE

	visible = true
	animation_player.play("fade_in")
	timer.start(notification_duration)

func _on_timer_timeout() -> void:
	animation_player.play("fade_out")
	await animation_player.animation_finished
	visible = false
	_play_next_notification()

