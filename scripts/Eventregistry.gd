extends Node
"""
EventRegistry – carrega eventos de JSON externo e dispara quando
 mês/ano coincidem. Se o arquivo não existir, usa um fallback embutido.
"""

var eventos: Array = []

func _ready() -> void:
	_carregar_eventos()

# ---------------------------------------------------------
func _carregar_eventos() -> void:
	const path := "res://data/eventos.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		eventos = JSON.parse_string(f.get_as_text())
		print("📜 %d eventos carregados de %s." % [eventos.size(), path])
	else:
		print("⚠  Arquivo eventos.json não encontrado, usando fallback.")
		_carregar_fallback()

func _carregar_fallback() -> void:
	eventos = [
		{"id":"independencia_brasil","titulo":"Independência do Brasil","descricao":"O Brasil declarou independência.","ano":1822,"mes":9},
		{"id":"rev_francesa","titulo":"Revolução Francesa","descricao":"O povo derrubou a monarquia.","ano":1789,"mes":7}
	]

# ---------------------------------------------------------
func check_for_event(mes:int, ano:int) -> void:
	for evento in eventos:
		if evento["ano"] == ano and evento["mes"] == mes:
			_disparar_evento(evento)

func _disparar_evento(evt:Dictionary) -> void:
	# Aqui apenas printa; depois você pode trocar por UI pop-up
	print("🔔 EVENTO HISTÓRICO: %s" % evt["titulo"])
	print("    %s" % evt["descricao"])
