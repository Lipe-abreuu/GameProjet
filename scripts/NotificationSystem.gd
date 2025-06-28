# res://scripts/NotificationSystem.gd
# Versão final com a sintaxe corrigida e lógica de espera.

extends Node
signal narrative_consequence_triggered(group_name, narrative_content)

# Verifique se este caminho para a sua cena de notificação está correto!
const NOTIFICATION_SCENE = preload("res://scenes/NotificationPanel.tscn") 

var notification_queue: Array = []
var is_displaying: bool = false
var notification_container: CanvasLayer

# Esta função é chamada pelo main.gd para dizer onde as notificações devem aparecer.
func setup(container: CanvasLayer):
	notification_container = container

# Função para qualquer script do jogo chamar.
func show_notification(title: String, message: String, _type: int = 0):
	# Adiciona o pedido à fila de espera.
	notification_queue.append({ "title": title, "message": message })
	# Tenta mostrar a notificação.
	_attempt_to_show_next()

# Função que gere a fila e mostra a próxima notificação.
func _attempt_to_show_next():
	# Condições para parar: se já houver algo na tela, ou se a fila estiver vazia.
	if is_displaying or notification_queue.is_empty():
		return

	# Marca que estamos a tentar mostrar algo para evitar chamadas múltiplas.
	is_displaying = true
	
	# Pega o primeiro item da fila.
	var notification_data = notification_queue.pop_front()
	
	# Inicia a rotina de mostrar a notificação, que pode incluir uma espera.
	_show(notification_data)

# Função privada que efetivamente cria e mostra o painel.
# O 'async' foi movido para aqui para garantir que a sintaxe está correta.
func _show(notification_data: Dictionary) -> void:
	# Se o container da UI ainda não estiver pronto, espera um frame.
	# Isto resolve o problema de "timing" do início do jogo.
	if not is_instance_valid(notification_container):
		await get_tree().process_frame
		# Se mesmo depois de esperar o container não for válido, é um erro crítico.
		if not is_instance_valid(notification_container):
			print("ERRO CRÍTICO: O container de notificações nunca foi configurado!")
			is_displaying = false # Liberta a fila
			return

	# Agora é seguro criar e mostrar a notificação.
	var notification_instance = NOTIFICATION_SCENE.instantiate()
	notification_instance.notification_finished.connect(_on_notification_finished)
	
	notification_container.add_child(notification_instance)
	notification_instance.display(notification_data.title, notification_data.message)

# Esta função é chamada quando uma notificação avisa que terminou.
func _on_notification_finished():
	# Liberta a vaga.
	is_displaying = false
	# Tenta imediatamente mostrar a próxima da fila.
	_attempt_to_show_next()
