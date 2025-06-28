# res://scripts/PartyResource.gd
# Recurso que armazena todos os dados do partido político

class_name PartyResource
extends Resource

# =====================================
# DADOS BÁSICOS DO PARTIDO
# =====================================

@export var party_name: String = "Frente Popular"
@export var country: String = "Chile"
@export var treasury: int = 100
@export var militants: int = 50
@export var influence: float = 5.0

# =====================================
# APOIO DOS GRUPOS SOCIAIS
# =====================================

@export var group_support: Dictionary = {
	"military": 5,
	"business": 8,
	"intellectuals": 10,
	"workers": 15,
	"students": 10,
	"church": 5,
	"middle_class": 12
}

# =====================================
# SISTEMA DE FASES DO PARTIDO
# =====================================

@export var phase: int = 1

var phase_names: Array = [
	"",  # Índice 0 não usado
	"Grupo Político Informal",
	"Movimento Político Local", 
	"Partido Político Regional",
	"Movimento Político Nacional"
]

var phase_requirements: Array = [
	{},  # Índice 0 não usado
	{"militants": 0, "influence": 0},      # Fase 1: Início
	{"militants": 100, "influence": 10},   # Fase 2: 100 militantes, 10 influência
	{"militants": 300, "influence": 25},   # Fase 3: 300 militantes, 25 influência
	{"militants": 800, "influence": 50}    # Fase 4: 800 militantes, 50 influência
]

# =====================================
# SISTEMA DE CONTRIBUIÇÕES DOS MILITANTES
# =====================================

@export var last_contribution_total: int = 0
@export var last_participation_rate: float = 0.0
@export var contribution_pressure: String = "medium"
@export var contribution_demand: String = "medium"
@export var morale: float = 75.0
@export var contribution_boost: int = 0

# =====================================
# ATRIBUTOS AVANÇADOS DO PARTIDO
# =====================================

# Capacidades especiais desenvolvidas através de ações
@export var visibility: int = 0              # Visibilidade para o regime
@export var media_power: int = 0             # Capacidade de propaganda
@export var union_control: int = 0           # Controle sobre sindicatos
@export var military_capacity: int = 0       # Força paramilitar
@export var international_protection: int = 0 # Proteção internacional
@export var legitimacy: int = 0              # Legitimidade política
@export var military_intelligence: int = 0   # Informações militares

# =====================================
# STATUS ESPECIAIS
# =====================================

@export var is_in_exile: bool = false
@export var condor_exposure: int = 0  # Exposição à Operação Condor

# =====================================
# FUNÇÕES PRINCIPAIS
# =====================================

func get_phase_name() -> String:
	"""Retorna o nome da fase atual do partido"""
	if phase < 1 or phase >= phase_names.size():
		return "Fase Desconhecida"
	return phase_names[phase]

func get_average_support() -> float:
	"""Calcula o apoio médio entre todos os grupos sociais"""
	if group_support.is_empty():
		return 0.0
	
	var total_support = 0
	for group_name in group_support:
		total_support += group_support[group_name]
	
	return float(total_support) / float(group_support.size())

func can_advance_phase() -> bool:
	"""Verifica se o partido pode avançar para a próxima fase"""
	var next_phase = phase + 1
	
	if next_phase >= phase_requirements.size():
		return false  # Já está na fase máxima
	
	var requirements = phase_requirements[next_phase]
	
	# Verifica se atende aos requisitos
	if militants >= requirements.get("militants", 0) and influence >= requirements.get("influence", 0):
		return true
	
	return false

func advance_phase() -> bool:
	"""Avança o partido para a próxima fase se possível"""
	if can_advance_phase():
		phase += 1
		print("🎉 PARTIDO AVANÇOU: %s" % get_phase_name())
		return true
	
	return false

func get_next_phase_requirements() -> Dictionary:
	"""Retorna os requisitos para a próxima fase"""
	var next_phase = phase + 1
	
	if next_phase >= phase_requirements.size():
		return {}  # Já está na fase máxima
	
	return phase_requirements[next_phase]

func get_phase_progress() -> float:
	"""Retorna o progresso em direção à próxima fase (0.0 a 1.0)"""
	var requirements = get_next_phase_requirements()
	
	if requirements.is_empty():
		return 1.0  # Já está na fase máxima
	
	# Calcula progresso baseado na média dos requisitos
	var militant_progress = float(militants) / float(requirements.get("militants", 1))
	var influence_progress = influence / requirements.get("influence", 1.0)
	
	# Usa o menor progresso (gargalo)
	return min(militant_progress, influence_progress)

# =====================================
# FUNÇÕES DE CONTRIBUIÇÕES
# =====================================

func get_contribution_summary() -> String:
	"""Retorna resumo das contribuições para exibição"""
	if last_contribution_total <= 0:
		return "Sem dados de contribuições"
	
	return "Última arrecadação: %d recursos (%d%% participação)" % [last_contribution_total, int(last_participation_rate)]

func is_high_morale() -> bool:
	"""Verifica se o partido tem moral alta"""
	return morale >= 70.0

func is_low_morale() -> bool:
	"""Verifica se o partido tem moral baixa"""
	return morale <= 30.0

# =====================================
# FUNÇÕES DE CAPACIDADES ESPECIAIS
# =====================================

func get_total_special_capacity() -> int:
	"""Retorna a soma de todas as capacidades especiais"""
	return media_power + union_control + military_capacity + international_protection + legitimacy + military_intelligence

func has_media_influence() -> bool:
	"""Verifica se o partido tem influência na mídia"""
	return media_power > 0

func has_military_capability() -> bool:
	"""Verifica se o partido tem capacidade militar"""
	return military_capacity > 0

func is_internationally_protected() -> bool:
	"""Verifica se o partido tem proteção internacional"""
	return international_protection > 0

# =====================================
# FUNÇÕES DE STATUS
# =====================================

func get_risk_level() -> String:
	"""Retorna o nível de risco atual do partido"""
	var risk_score = visibility + condor_exposure
	
	if is_in_exile:
		risk_score += 10
	
	if risk_score <= 5:
		return "Baixo"
	elif risk_score <= 15:
		return "Médio"
	elif risk_score <= 25:
		return "Alto"
	else:
		return "Crítico"

func get_operational_capacity() -> String:
	"""Retorna a capacidade operacional atual"""
	if is_in_exile:
		return "Limitada (Exílio)"
	elif morale >= 80 and militants >= 100:
		return "Excelente"
	elif morale >= 60 and militants >= 50:
		return "Boa"
	elif morale >= 40 and militants >= 20:
		return "Regular"
	else:
		return "Precária"

# =====================================
# FUNÇÕES DE DEBUG E INFORMAÇÃO
# =====================================

func get_detailed_status() -> Dictionary:
	"""Retorna status completo do partido para debug"""
	return {
		"basic": {
			"name": party_name,
			"phase": get_phase_name(),
			"militants": militants,
			"influence": influence,
			"treasury": treasury
		},
		"support": {
			"average": get_average_support(),
			"by_group": group_support.duplicate()
		},
		"contributions": {
			"last_total": last_contribution_total,
			"participation": last_participation_rate,
			"morale": morale,
			"demand_level": contribution_demand
		},
		"capabilities": {
			"media_power": media_power,
			"union_control": union_control,
			"military_capacity": military_capacity,
			"legitimacy": legitimacy,
			"total_capacity": get_total_special_capacity()
		},
		"status": {
			"risk_level": get_risk_level(),
			"operational_capacity": get_operational_capacity(),
			"in_exile": is_in_exile,
			"condor_exposure": condor_exposure
		},
		"progression": {
			"current_phase": phase,
			"can_advance": can_advance_phase(),
			"progress": get_phase_progress(),
			"next_requirements": get_next_phase_requirements()
		}
	}

func debug_print_full_status():
	"""Imprime status completo do partido no console"""
	var status = get_detailed_status()
	
	print("=== STATUS COMPLETO DO PARTIDO ===")
	print("Nome: %s (%s)" % [status.basic.name, status.basic.phase])
	print("Militantes: %d | Influência: %.1f | Tesouraria: %d" % [status.basic.militants, status.basic.influence, status.basic.treasury])
	print("")
	print("--- APOIO SOCIAL ---")
	print("Apoio Médio: %.1f%%" % status.support.average)
	for group in status.support.by_group:
		print("  %s: %d%%" % [group.capitalize(), status.support.by_group[group]])
	print("")
	print("--- SISTEMA DE CONTRIBUIÇÕES ---")
	print("Última Arrecadação: %d recursos" % status.contributions.last_total)
	print("Participação: %.1f%%" % status.contributions.participation)
	print("Moral: %.1f" % status.contributions.morale)
	print("Nível de Cobrança: %s" % status.contributions.demand_level.capitalize())
	print("")
	print("--- CAPACIDADES ESPECIAIS ---")
	print("Poder na Mídia: %d" % status.capabilities.media_power)
	print("Controle Sindical: %d" % status.capabilities.union_control)
	print("Capacidade Militar: %d" % status.capabilities.military_capacity)
	print("Legitimidade: %d" % status.capabilities.legitimacy)
	print("Total: %d" % status.capabilities.total_capacity)
	print("")
	print("--- STATUS OPERACIONAL ---")
	print("Nível de Risco: %s" % status.status.risk_level)
	print("Capacidade: %s" % status.status.operational_capacity)
	if status.status.in_exile:
		print("⚠️ PARTIDO NO EXÍLIO")
	if status.status.condor_exposure > 0:
		print("🕸️ EXPOSIÇÃO CONDOR: %d" % status.status.condor_exposure)
	print("")
	print("--- PROGRESSÃO ---")
	print("Fase Atual: %d/%d" % [status.progression.current_phase, phase_names.size() - 1])
	print("Progresso: %.1f%%" % (status.progression.progress * 100))
	if status.progression.can_advance:
		print("✅ PODE AVANÇAR DE FASE!")
	else:
		var req = status.progression.next_requirements
		if not req.is_empty():
			print("📋 Próximos Requisitos:")
			if "militants" in req:
				print("  Militantes: %d/%d" % [militants, req.militants])
			if "influence" in req:
				print("  Influência: %.1f/%.1f" % [influence, req.influence])
	print("===================================")
