# =====================================
#  PLAYERAGENT.GD - VERSÃO COMPLETA E CORRIGIDA
# =====================================
class_name PlayerAgent
extends Node

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
# APOIO DE GRUPOS (0-100) - Usando um dicionário para robustez
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
var total_support: int = 0 # Será sempre calculado

# ================================================================
# FUNÇÕES DE INICIALIZAÇÃO E CICLO DE VIDA
# ================================================================

func _ready():
	_update_total_support()

# Esta função será chamada a cada mês pelo main.gd
func advance_month():
	# Não vamos mais incrementar a idade a cada mês para evitar o problema de float vs int.
	# A idade só será incrementada quando o ano mudar, o que podemos fazer no main.gd
	pass

# ================================================================
# GETTERS E SETTERS (Funções para obter e definir valores)
# ================================================================

# Retorna o nome da posição atual (Ex: "Ativista")
func get_position_name() -> String:
	if position_level >= 0 and position_level < position_hierarchy.size():
		return position_hierarchy[position_level]
	return "Desconhecido"

# Define o nível da posição do jogador e emite um sinal
func set_position_level(new_level: int):
	var old_level = position_level
	if new_level != old_level and new_level >= 0 and new_level < position_hierarchy.size():
		var old_pos_name = get_position_name()
		position_level = new_level
		var new_pos_name = get_position_name()
		emit_signal("position_advanced", old_pos_name, new_pos_name)
		print("Player position updated to: ", new_pos_name)

# Define o apoio de um grupo e emite um sinal
func set_support(group_name: String, new_value: int):
	# Agora a verificação 'has' funciona, pois 'personal_support' é um dicionário
	if personal_support.has(group_name):
		var old_value = personal_support[group_name]
		var clamped_value = clamp(new_value, 0, 100)
		personal_support[group_name] = clamped_value
		
		_update_total_support() # Recalcula o apoio total
		emit_signal("support_changed", group_name, old_value, clamped_value)
	else:
		push_error("Tentativa de mudar apoio de grupo inexistente: " + group_name)

# Calcula o apoio total somando o apoio de todos os grupos
func _update_total_support():
	total_support = 0
	for group_name in personal_support:
		total_support += personal_support[group_name]

# ================================================================
# LÓGICA DE AÇÕES (main.gd precisa destas funções)
# ================================================================

# Retorna uma lista de ações disponíveis para a posição atual
func get_available_actions() -> Array:
	# LÓGICA DE EXEMPLO - PRECISAMOS EXPANDIR COM BASE NO PLANO
	var actions = []
	match position_level:
		0: # Cidadão
			actions.append({"name": "Distribuir Panfletos", "cost": 5, "type": "charisma"})
		1: # Ativista
			actions.append({"name": "Fazer Discurso", "cost": 10, "type": "charisma"})
			actions.append({"name": "Organizar Reunião", "cost": 5, "type": "connections"})
	return actions

# Executa uma ação e retorna o resultado
func execute_action(action: Dictionary) -> Dictionary:
	# LÓGICA DE EXEMPLO - PRECISAMOS EXPANDIR COM BASE NO PLANO
	var result = {"success": false, "message": "Ação não implementada."}
	
	if wealth < action.get("cost", 0):
		result.message = "Recursos insuficientes!"
		return result

	wealth -= action.get("cost", 0)
	
	# Simular sucesso com base nos atributos
	var success_chance = (charisma + intelligence) / 200.0
	if randf() < success_chance:
		result.success = true
		result.message = "Ação bem-sucedida!"
		set_support("worker", personal_support["worker"] + 5) # Exemplo de efeito
	else:
		result.success = false
		result.message = "Ação falhou em ter impacto."

	return result

# Adiciona uma ação especial que dura alguns turnos
func add_temporary_action(action_data: Dictionary):
	# Esta é uma função mais avançada que podemos implementar depois,
	# mas ela precisa existir para o main.gd não dar erro.
	print("DEBUG: Ação temporária oferecida: ", action_data.get("name", "N/A"))
