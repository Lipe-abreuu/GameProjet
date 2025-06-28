# res://scripts/HeatSystem.gd
# Sistema profissional de heat/perseguição para o jogo

extends Node

# =====================================
# SINAIS
# =====================================
signal heat_changed(old_value: float, new_value: float)
signal heat_level_changed(old_level: int, new_level: int)
signal raid_warning(turns_until: int)
signal raid_triggered()
signal close_call_triggered(event_type: String)

# =====================================
# CONSTANTES
# =====================================
const MAX_HEAT = 100.0
const HEAT_DECAY_RATE = 0.92  # Perde 8% por mês
const HEAT_LEVELS = {
	0: {"name": "Desconhecido", "threshold": 0, "raid_chance": 0},
	1: {"name": "Monitorado", "threshold": 20, "raid_chance": 5},
	2: {"name": "Suspeito", "threshold": 40, "raid_chance": 15},
	3: {"name": "Investigado", "threshold": 60, "raid_chance": 30},
	4: {"name": "Procurado", "threshold": 80, "raid_chance": 50},
	5: {"name": "Inimigo Público", "threshold": 90, "raid_chance": 75}
}

# =====================================
# VARIÁVEIS DE ESTADO
# =====================================
var current_heat: float = 0.0
var current_level: int = 0
var raid_cooldown: int = 0  # Evita raids consecutivas
var warning_given: bool = false

# Modificadores de heat por ação
var action_heat_values = {
	"Distribuir Panfletos": 3.0,
	"Realizar Debate Ideológico": 2.0,
	"Organizar Protesto Local": 8.0,
	"Publicar Manifesto": 5.0,
	"Organizar Greve": 15.0,
	"Criar Jornal Underground": 7.0,
	"Infiltrar Sindicatos": 6.0,
	"Formar Milícia Popular": 20.0,
	"Sabotagem Econômica": 25.0,
	"Operar Rádio Clandestina": 12.0,
	"Coordenar Resistência Nacional": 18.0
}

# =====================================
# FUNÇÕES PRINCIPAIS
# =====================================

func _ready():
	set_name("HeatSystem")
	print("🔥 Sistema de Heat inicializado")

func add_heat(amount: float, source: String = "") -> void:
	"""Adiciona heat com validação e feedback"""
	if amount <= 0:
		return
		
	var old_heat = current_heat
	var old_level = current_level
	
	current_heat = min(current_heat + amount, MAX_HEAT)
	_update_heat_level()
	
	emit_signal("heat_changed", old_heat, current_heat)
	
	if current_level > old_level:
		emit_signal("heat_level_changed", old_level, current_level)
		print("⚠️ HEAT AUMENTOU PARA NÍVEL %d: %s" % [current_level, get_current_level_name()])
	
	if source != "":
		print("🔥 +%.1f heat de '%s' (Total: %.1f)" % [amount, source, current_heat])

func reduce_heat(amount: float) -> void:
	"""Reduz heat (para ações de esfriamento)"""
	if amount <= 0:
		return
		
	var old_heat = current_heat
	var old_level = current_level
	
	current_heat = max(current_heat - amount, 0.0)
	_update_heat_level()
	
	emit_signal("heat_changed", old_heat, current_heat)
	
	if current_level < old_level:
		emit_signal("heat_level_changed", old_level, current_level)

func process_monthly_heat() -> void:
	"""Processa heat mensal - decay e verificações"""
	# Decay natural
	var old_heat = current_heat
	current_heat *= HEAT_DECAY_RATE
	
	# Reduz cooldown de raid
	if raid_cooldown > 0:
		raid_cooldown -= 1
	
	_update_heat_level()
	
	# Verifica possibilidade de raid
	_check_for_raid()
	
	# Verifica close calls
	if current_level >= 2 and randf() < 0.3:
		_trigger_close_call()
	
	emit_signal("heat_changed", old_heat, current_heat)

func get_heat_for_action(action_name: String) -> float:
	"""Retorna quanto de heat uma ação específica gera"""
	return action_heat_values.get(action_name, 5.0)  # Default 5.0

# =====================================
# SISTEMA DE RAIDS
# =====================================

func _check_for_raid() -> void:
	"""Verifica se uma raid deve acontecer"""
	if raid_cooldown > 0:
		return
	
	var level_data = HEAT_LEVELS[current_level]
	var raid_chance = level_data.raid_chance
	
	# Modificadores de chance
	if current_heat > 85:
		raid_chance += 20
	
	# Aviso prévio em níveis altos
	if current_level >= 4 and not warning_given and randf() < 0.5:
		warning_given = true
		var turns_until = randi_range(1, 3)
		emit_signal("raid_warning", turns_until)
		print("⚠️ INTELIGÊNCIA: Raid possível em %d turnos!" % turns_until)
		return
	
	# Executa raid
	if randf() * 100 < raid_chance:
		_execute_raid()

func _execute_raid() -> void:
	"""Executa uma operação policial"""
	emit_signal("raid_triggered")
	raid_cooldown = 3  # Sem raids por 3 meses após
	warning_given = false
	print("🚨 RAID POLICIAL EM ANDAMENTO!")

func _trigger_close_call() -> void:
	"""Eventos menores de tensão"""
	var events = [
		"surveillance_spotted",  # Vigilância notada
		"phone_tapped",         # Telefone grampeado
		"militant_followed",    # Militante seguido
		"strange_car",         # Carro suspeito
		"neighbor_asking"      # Vizinho fazendo perguntas
	]
	
	var event = events[randi() % events.size()]
	emit_signal("close_call_triggered", event)

# =====================================
# FUNÇÕES AUXILIARES
# =====================================

func _update_heat_level() -> void:
	"""Atualiza o nível baseado no heat atual"""
	var new_level = 0
	
	for level in HEAT_LEVELS:
		if current_heat >= HEAT_LEVELS[level].threshold:
			new_level = level
	
	if new_level != current_level:
		current_level = new_level

func get_current_level_name() -> String:
	"""Retorna o nome do nível atual"""
	return HEAT_LEVELS[current_level].name

func get_heat_percentage() -> float:
	"""Retorna heat como percentual (0-100)"""
	return (current_heat / MAX_HEAT) * 100.0

func get_raid_chance() -> float:
	"""Retorna chance atual de raid"""
	if raid_cooldown > 0:
		return 0.0
	return HEAT_LEVELS[current_level].raid_chance

func is_heat_critical() -> bool:
	"""Verifica se heat está em nível crítico"""
	return current_heat > 80.0 or current_level >= 4

# =====================================
# INTEGRAÇÃO COM PARTY CONTROLLER
# =====================================

func apply_heat_from_action(action_name: String, success: bool) -> void:
	"""Aplica heat baseado em uma ação do partido"""
	var base_heat = get_heat_for_action(action_name)
	
	# Modificadores
	if not success:
		base_heat *= 1.5  # Falha gera mais heat
	
	# Condor reduz heat se ação é clandestina
	if Globals.is_condor_active() and _is_clandestine_action(action_name):
		base_heat *= 0.7
	
	add_heat(base_heat, action_name)

func _is_clandestine_action(action_name: String) -> bool:
	"""Verifica se ação é clandestina (menos heat)"""
	var clandestine = [
		"Organizar Célula Clandestina",
		"Infiltrar Universidade",
		"Infiltrar Sindicatos",
		"Criar Jornal Underground"
	]
	return action_name in clandestine

# =====================================
# HANDLERS DE RAID
# =====================================

func handle_raid_response(response: String) -> Dictionary:
	"""Processa resposta do jogador a uma raid"""
	var result = {
		"success": false,
		"militants_lost": 0,
		"treasury_lost": 0,
		"influence_lost": 0.0,
		"message": ""
	}
	
	match response:
		"destroy_evidence":
			result.success = true
			result.influence_lost = 2.0
			result.message = "Provas destruídas. Influência reduzida mas partido seguro."
			current_heat *= 0.7  # Reduz heat
			
		"hide_militants":
			result.success = randf() > 0.3
			if result.success:
				result.message = "Militantes escondidos com sucesso!"
			else:
				result.militants_lost = randi_range(3, 8)
				result.message = "Alguns militantes foram capturados!"
			
		"bribe_officer":
			var bribe_cost = randi_range(100, 300)
			result.treasury_lost = bribe_cost
			result.success = randf() > 0.4
			if result.success:
				result.message = "Oficial subornado. Raid cancelada."
				current_heat *= 0.8
			else:
				result.message = "Suborno falhou! Oficial era incorruptível."
				result.militants_lost = randi_range(2, 5)
			
		"resist":
			result.success = randf() > 0.7
			if result.success:
				result.message = "Resistência heroica! Polícia recuou!"
				result.influence_lost = -1.0  # Ganha influência
			else:
				result.militants_lost = randi_range(5, 15)
				result.treasury_lost = randi_range(50, 200)
				result.message = "Resistência esmagada. Perdas pesadas."
		
		"collaborate":
			# Trai aliados para reduzir heat drasticamente
			result.success = true
			current_heat *= 0.3
			result.influence_lost = 5.0
			result.message = "Informações fornecidas. Heat reduzido mas reputação destruída."
			# TODO: Adicionar consequências de longo prazo
	
	return result

# =====================================
# DEBUG E INFORMAÇÕES
# =====================================

func get_heat_info() -> Dictionary:
	"""Retorna informações completas do sistema"""
	return {
		"current_heat": current_heat,
		"current_level": current_level,
		"level_name": get_current_level_name(),
		"percentage": get_heat_percentage(),
		"raid_chance": get_raid_chance(),
		"raid_cooldown": raid_cooldown,
		"is_critical": is_heat_critical()
	}

func debug_set_heat(value: float) -> void:
	"""Função de debug para testar"""
	current_heat = clamp(value, 0.0, MAX_HEAT)
	_update_heat_level()
	emit_signal("heat_changed", current_heat, current_heat)
	print("DEBUG: Heat definido para %.1f" % current_heat)
