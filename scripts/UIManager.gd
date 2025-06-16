# Arquivo: UIManager.gd
extends Node
class_name UIManager

var main_game_node: Node

# Função para receber referências importantes
func setup(main_node: Node) -> void:
	main_game_node = main_node
	print("✅ UIManager configurado.")

# Função para atualizar a UI específica da fase do jogo
# O main.gd chama essa função, então ela precisa existir.
func update_phase_specific_ui(current_phase, player_agent) -> void:
	# Você pode adicionar a lógica aqui no futuro.
	# Por exemplo: mostrar/esconder painéis de ações políticas, etc.
	pass
