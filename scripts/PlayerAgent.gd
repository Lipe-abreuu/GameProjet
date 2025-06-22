# =====================================
#  PLAYERAGENT.GD - VERSÃO FINAL E COMPLETA
# =====================================
class_name PlayerAgent
extends Node
const NotificationSystem = preload("res://scripts/NotificationSystem.gd")

# =====================================
# SINAIS (Signals)
# =====================================
# Emitido quando o jogador avança de posição
signal position_advanced(old_position, new_position)
# Emitido quando o apoio de algum grupo muda
signal support_changed(group, old_value, new_value)

# =====================================
# DADOS PESSOAIS
# =====================================
var agent_name: String = "Lautaro Silva"
var age: int = 35
var ideology: String = "Socialista Reformista"
var country: String = "Chile"
var background: String = "Intelectual"

# =====================================
# ATRIBUTOS PRINCIPAIS (0-100)
# =====================================
var charisma: int = 50
var intelligence: int = 50
var connections: int = 50
var wealth: int = 300
var military_knowledge: int = 10
var political_experience: int = 0

# =====================================
# POSIÇÃO POLÍTICA
# =====================================
var position_hierarchy = ["Cidadão", "Ativista", "Deputado", "Senador", "Ministro", "Presidente"]
var position_level: int = 0

# =====================================
# APOIO DE GRUPOS (0-100)
# =====================================
var personal_support = {
	"military": 10,
	"business": 10,
	"intellectual": 10,
	"worker": 10,
	"student": 10,
	"church": 10,
	"peasant": 10
}

# =====================================
# STATS DERIVADOS E DE ESTADO
# =====================================
var condor_threat_level: int = 0
var total_support: int = 0

# ================================================================
# FUNÇÕES DE INICIALIZAÇÃO E CICLO DE VIDA
# ================================================================

func _ready():
	_update_total_support()

# Esta função é chamada a cada mês pelo main.gd
func advance_month():
	# A idade agora é incrementada anualmente no main.gd
	pass

# ================================================================
# GETTERS E SETTERS
# ================================================================

# Retorna o nome da posição atual (Ex: "Ativista")
func get_position_name() -> String:
	if position_level >= 0 and position_level < position_hierarchy.size():
		return position_hierarchy[position_level]
	return "Desconhecido"

# Define o nível da posição do jogador e emite um sinal de promoção
func set_position_level(new_level: int):
	var old_level = position_level
	if new_level != old_level and new_level >= 0 and new_level < position_hierarchy.size():
		var old_pos_name = get_position_name()
		position_level = new_level
		var new_pos_name = get_position_name()
		emit_signal("position_advanced", old_pos_name, new_pos_name)
		print("Player position updated to: ", new_pos_name)

# Define o apoio de um grupo, atualiza o total e emite um sinal
func set_support(group_name: String, new_value: int):
	if personal_support.has(group_name):
		var old_value = personal_support[group_name]
		var clamped_value = clamp(new_value, 0, 100)
		personal_support[group_name] = clamped_value
		
		_update_total_support()
		emit_signal("support_changed", group_name, old_value, clamped_value)
	else:
		push_error("Tentativa de mudar apoio de grupo inexistente: " + group_name)

# Calcula o apoio total somando o apoio de todos os grupos
func _update_total_support():
	total_support = 0
	for group_name in personal_support:
		total_support += personal_support[group_name]

# ================================================================
# LÓGICA DE PROGRESSÃO E AÇÕES
# ================================================================

# Verifica se o jogador tem experiência suficiente para ser promovido
func check_for_promotion():
	# Condição para virar Ativista: ser Cidadão (nível 0) e ter mais de 50 de experiência
	if position_level == 0 and political_experience > 50:
		set_position_level(1) # Nível 1 = Ativista

		var notif_system = get_tree().get_root().get_node_or_null("Main/NotificationSystem")
		if notif_system:
			notif_system.show_notification(
				"🎉 PROMOÇÃO!",
				"Sua influência cresceu! Você agora é um Ativista.",
				NotificationSystem.NotificationType.SUCCESS,
				5.0
			)

# Retorna uma lista de ações disponíveis para a posição atual
func get_available_actions() -> Array:
	var actions = []
	match position_level:
		0: # Cidadão
			actions.append({"name": "Distribuir Panfletos", "cost": 5, "type": "charisma"})
		1: # Ativista
			actions.append({"name": "Fazer Discurso", "cost": 10, "type": "charisma"})
			actions.append({"name": "Organizar Reunião", "cost": 5, "type": "connections"})
	return actions

# Executa uma ação, retorna o resultado e verifica a promoção
func execute_action(action: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "A ação não teve o efeito esperado."}
	
	if wealth < action.get("cost", 0):
		result.message = "Recursos insuficientes!"
		return result

	wealth -= action.get("cost", 0)
	
	# A variável é declarada com 'var' APENAS UMA VEZ aqui.
	var success_chance = (charisma + intelligence) / 200.0
	
	if randf() < success_chance:
		result.success = true
		var support_gain = 5
		set_support("worker", personal_support["worker"] + support_gain)
		
		result.message = "Você distribuiu panfletos e ganhou +%d de apoio com os trabalhadores!" % support_gain
		
		self.political_experience += 5
		check_for_promotion()
	else:
		result.success = false
		result.message = "Sua tentativa de distribuir panfletos não foi notada pelas pessoas."

	return result
# Adiciona uma ação especial que dura alguns turnos
func add_temporary_action(action_data: Dictionary):
	# Função de placeholder para o futuro
	print("DEBUG: Ação temporária oferecida: ", action_data.get("name", "N/A"))
