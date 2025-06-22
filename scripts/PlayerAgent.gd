extends Node
class_name PlayerAgent

# ========================
# ENUMERAÇÕES E ESTADOS
# ========================

enum Position {
	AGENT,
	PRESIDENT
}

# ========================
# VARIÁVEIS PÚBLICAS
# ========================

var agent_name: String = "Agente Padrão"
var country: String = "Chile"
var ideology: String = "indefinida"

var total_support: int = 0
var condor_threat_level: int = 0
var current_position: int = Position.AGENT

# ========================
# SINAIS
# ========================

signal position_advanced
signal support_changed

# ========================
# MÉTODOS
# ========================

func advance_month() -> void:
	# Exemplo de mudança de suporte
	total_support += randi() % 20
	emit_signal("support_changed")

	# Exemplo de possível avanço de posição
	if total_support >= 700 and current_position != Position.PRESIDENT:
		current_position = Position.PRESIDENT
		emit_signal("position_advanced")

func get_position_name() -> String:
	match current_position:
		Position.AGENT:
			return "Agente Político"
		Position.PRESIDENT:
			return "Presidente"
		_:
			return "Desconhecido"
