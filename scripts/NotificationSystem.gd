# res://scripts/NotificationSystem.gd
# Este script deve estar anexado ao nó raiz da sua cena NotificationPanel.tscn,
# e esse nó raiz DEVE ser um CanvasLayer.


extends CanvasLayer

# Enum para os tipos de notificação, para facilitar a leitura do código.
enum NotificationType { INFO, SUCCESS, ERROR }

# --- Referências aos Nós da Cena ---
# ERRO CRÍTICO: O erro "null instance" acontece porque o nome de um destes nós
# no seu editor de cenas não corresponde EXATAMENTE ao nome que o script espera.
# Por favor, garanta que os nomes dos nós na sua cena são:
# - "TitleLabel" (corrigido, com "i")
# - "MessageLabel"
# - "Timer"
# - "AnimationPlayer"
@onready var title_label: Label = $TitleLabel
@onready var message_label: Label = $MessageLabel
@onready var timer: Timer = $Timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# --- Variáveis Internas ---
# Fila para guardar as notificações que ainda não foram mostradas.
var _notification_queue: Array = []
# Flag para controlar se uma notificação já está a ser mostrada.
var _is_showing := false
# Flag para garantir que o nó está pronto antes de mostrar notificações.
var _ready_done := false
# Duração padrão que cada notificação fica no ecrã (em segundos).
var notification_duration := 5.0

func _ready() -> void:
	_ready_done = true
	if not _notification_queue.is_empty():
		_play_next_notification()

# --- Funções Públicas ---

# Esta é a função que você chama de qualquer outro script para mostrar uma notificação.
func show_notification(title: String, msg: String, type: int = NotificationType.INFO) -> void:
	# Adiciona a nova notificação à fila.
	_notification_queue.append({"title": title, "message": msg, "type": type})
	# Se nenhuma notificação estiver a ser mostrada, e o nó estiver pronto, começa o processo.
	if _ready_done and not _is_showing:
		_play_next_notification()

# --- Funções Privadas (Lógica Interna) ---

# Função para processar a próxima notificação na fila.
func _play_next_notification() -> void:
	# Se a fila estiver vazia, para o processo.
	if _notification_queue.is_empty():
		_is_showing = false
		return

	# Marca que uma notificação está a ser mostrada.
	_is_showing = true
	# Retira a notificação mais antiga da fila.
	var notification_data = _notification_queue.pop_front()

	# Define o texto e a cor com base nos dados da notificação.
	title_label.text = notification_data.title
	message_label.text = notification_data.message

	match notification_data.type:
		NotificationType.SUCCESS:
			title_label.modulate = Color.GREEN
		NotificationType.ERROR:
			title_label.modulate = Color.RED
		_: # INFO ou qualquer outro tipo
			title_label.modulate = Color.WHITE

	# Torna o painel visível, inicia a animação de entrada e o temporizador.
	visible = true
	animation_player.play("fade_in")
	timer.start(notification_duration)

# --- Handlers de Sinais ---

# Esta função é chamada automaticamente quando o sinal "timeout" do nó Timer é emitido.
func _on_timer_timeout() -> void:
	# Quando o tempo acaba, inicia a animação de saída.
	animation_player.play("fade_out")
	# Espera a animação terminar antes de continuar.
	await animation_player.animation_finished
	# Esconde o painel e chama a próxima notificação da fila.
	visible = false
	_play_next_notification()
