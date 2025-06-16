# =====================================
#  UIManager.gd
#  Gerencia a interface de usuário baseada na fase do jogo.
# =====================================
class_name UIManager
extends Node # Garante que pode ser adicionado à árvore de cena

# =====================================
#  REFERÊNCIAS
# =====================================
var main_node: Node # Referência ao nó principal (Main.gd)
var game_phase_label: Label # Exemplo: Label para exibir a fase do jogo
var agent_info_panel: Control # Exemplo: Painel para informações do agente
var leader_info_panel: Control # Exemplo: Painel para informações do líder nacional

# =====================================
#  INICIALIZAÇÃO
# =====================================
func _init() -> void:
	# Inicialização de variáveis, se necessário
	pass

func setup(main: Node) -> void:
	main_node = main
	# Tentar buscar referências de nós da UI (se existirem na cena)
	# Estes caminhos são exemplos e devem corresponder à sua cena
	game_phase_label = main_node.get_node_or_null("CanvasLayer/TopBar/GamePhaseLabel")
	agent_info_panel = main_node.get_node_or_null("CanvasLayer/Sidepanel/AgentInfoPanel")
	leader_info_panel = main_node.get_node_or_null("CanvasLayer/Sidepanel/LeaderInfoPanel")
	
	if game_phase_label:
		print("UI Manager: GamePhaseLabel encontrado.")
	if agent_info_panel:
		print("UI Manager: AgentInfoPanel encontrado.")
	if leader_info_panel:
		print("UI Manager: LeaderInfoPanel encontrado.")

# =====================================
#  ATUALIZAÇÃO DA UI ESPECÍFICA DA FASE
# =====================================
func update_phase_specific_ui(_current_phase: int, _player_agent: PlayerAgent) -> void: # CORREÇÃO AQUI: adicionado _ aos parâmetros
	# Este é um esqueleto. Você implementaria a lógica para mostrar/ocultar painéis
	# e atualizar informações com base na fase e no player_agent
	
	# Exemplo: Lógica para mostrar/ocultar painéis de acordo com a fase
	# if game_phase_label:
	# 	game_phase_label.text = "Fase: %s" % GamePhase.keys()[_current_phase] # Usar _current_phase
	
	# if _current_phase == main_node.GamePhase.POLITICAL_AGENT:
	# 	if agent_info_panel: agent_info_panel.visible = true
	# 	if leader_info_panel: leader_info_panel.visible = false
	# 	# Atualizar informações específicas do agente usando _player_agent
	# elif _current_phase == main_node.GamePhase.NATIONAL_LEADER:
	# 	if agent_info_panel: agent_info_panel.visible = false
	# 	if leader_info_panel: leader_info_panel.visible = true
	# 	# Atualizar informações específicas do líder usando _player_agent ou Globals
	pass

# =====================================
#  MÉTODOS DE CONTROLE DA UI (Exemplos)
# =====================================
func show_game_over_screen() -> void:
	# Lógica para exibir a tela de Game Over
	print("UI Manager: Exibindo tela de Game Over.")
	# Você precisaria de uma referência à sua tela de game over aqui
	# Por exemplo: main_node.get_node("GameOverScreen").show()
	pass

func hide_game_over_screen() -> void:
	# Lógica para esconder a tela de Game Over
	print("UI Manager: Escondendo tela de Game Over.")
	# Por exemplo: main_node.get_node("GameOverScreen").hide()
	pass

# Adicione outras funções de gerenciamento de UI conforme necessário
# Por exemplo, para popups, menus, etc.
