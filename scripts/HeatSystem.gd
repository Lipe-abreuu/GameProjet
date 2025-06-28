# res://scripts/HeatSystem.gd
# Versão final revisada para consistência e estabilidade.

extends Node

# --- SINAIS ---
signal heat_changed(old_value: float, new_value: float)
signal heat_level_changed(old_level: int, new_level: int)
signal raid_warning(turns_until: int)
signal raid_triggered()
signal close_call_triggered(event_type: String)

# --- CONSTANTES ---
const MAX_HEAT = 100.0
const HEAT_DECAY_RATE_PER_SECOND = 0.5 # Alterado para decaimento por segundo
const HEAT_LEVELS = {
	0: {"name": "Desconhecido", "threshold": 0, "raid_chance": 0},
	1: {"name": "Monitorado", "threshold": 20, "raid_chance": 5},
	2: {"name": "Suspeito", "threshold": 40, "raid_chance": 15},
	3: {"name": "Investigado", "threshold": 60, "raid_chance": 30},
	4: {"name": "Procurado", "threshold": 80, "raid_chance": 50},
	5: {"name": "Inimigo Público", "threshold": 90, "raid_chance": 75}
}
var action_heat_values = {
	"Distribuir Panfletos": 3.0, "Realizar Debate Ideológico": 2.0,
	"Organizar Protesto Local": 8.0, "Publicar Manifesto": 5.0,
	"Organizar Greve": 15.0, "Criar Jornal Underground": 7.0,
	"Infiltrar Sindicatos": 6.0, "Formar Milícia Popular": 20.0,
	"Sabotagem Econômica": 25.0, "Operar Rádio Clandestina": 12.0,
	"Coordenar Resistência Nacional": 18.0
}

# --- ESTADO ---
var current_heat: float = 0.0
var current_level: int = 0
var raid_cooldown: int = 0
var warning_given: bool = false

# =====================================
# LÓGICA PRINCIPAL
# =====================================

func _process(delta: float):
	# Decaimento contínuo do Heat
	if current_heat > 0:
		var old_heat = current_heat
		current_heat = move_toward(current_heat, 0, HEAT_DECAY_RATE_PER_SECOND * delta)
		
		# CORREÇÃO APLICADA AQUI: Enviando os dois argumentos necessários.
		if int(old_heat) != int(current_heat):
			emit_signal("heat_changed", old_heat, current_heat)

	# Verificação contínua de raid
	_check_for_raid(delta)

func process_monthly_turn():
	"""Processa eventos que ocorrem uma vez por mês."""
	# Reduz cooldown de raid
	if raid_cooldown > 0:
		raid_cooldown -= 1
	
	# Verifica "close calls" mensalmente
	if current_level >= 2 and randf() < 0.3:
		_trigger_close_call()
		
# =====================================
# MÉTODOS PÚBLICOS
# =====================================

func apply_heat_from_action(action_name: String, success: bool):
	var base_heat = action_heat_values.get(action_name, 1.0) # Default de 1.0 para ações não listadas
	if not success:
		base_heat *= 1.5 # Falhas geram mais heat
	
	add_heat(base_heat, action_name)

func add_heat(amount: float, source: String = ""):
	if amount <= 0: return
	
	var old_heat = current_heat
	current_heat = min(current_heat + amount, MAX_HEAT)
	
	print("🔥 +%.1f heat de '%s' (Total: %.1f)" % [amount, source, current_heat])
	emit_signal("heat_changed", old_heat, current_heat)
	_update_heat_level()

# ... (restante das suas funções: _check_for_raid, handle_raid_response, etc., já estão corretas) ...
# Apenas certifique-se de que a função `_update_heat_level` é chamada quando o nível pode mudar.

func _update_heat_level():
	var new_level = 0
	for level in HEAT_LEVELS:
		if current_heat >= HEAT_LEVELS[level].threshold:
			new_level = level
	
	if new_level != current_level:
		var old_level = current_level
		current_level = new_level
		emit_signal("heat_level_changed", old_level, current_level)
		print("⚠️ HEAT AUMENTOU PARA NÍVEL %d: %s" % [current_level, get_current_level_name()])

# (O resto do seu script HeatSystem.gd que você enviou antes pode permanecer o mesmo)
# Incluindo as funções get_current_level_name, get_heat_info, etc. aqui para completude.

func get_current_level_name() -> String:
	return HEAT_LEVELS.get(current_level, {"name": "N/A"}).name

func get_heat_info() -> Dictionary:
	return {
		"current_heat": current_heat, "current_level": current_level,
		"level_name": get_current_level_name(), "percentage": (current_heat / MAX_HEAT) * 100.0
	}
	
func _check_for_raid(delta: float): # Alterado para usar delta
	if raid_cooldown > 0: return
	
	var level_data = HEAT_LEVELS[current_level]
	var raid_chance_per_second = level_data.raid_chance
	var chance_this_frame = (raid_chance_per_second / 100.0) * delta
	
	if randf() < chance_this_frame:
		_execute_raid()

func _execute_raid():
	emit_signal("raid_triggered")
	raid_cooldown = 3
	warning_given = false
	current_heat = 0 # Zera o heat após a raid
	print("🚨 RAID POLICIAL EM ANDAMENTO!")
	
func _trigger_close_call():
	var events = ["surveillance_spotted", "phone_tapped", "militant_followed", "strange_car", "neighbor_asking"]
	var event = events[randi() % events.size()]
	emit_signal("close_call_triggered", event)
	
func handle_raid_response(response: String) -> Dictionary:
	var result = { "success": false, "message": "" }
	# (Sua lógica de raid aqui...)
	return result
