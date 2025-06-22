extends Node

var eventos = []

func _ready():
	carregar_eventos()

func carregar_eventos():
	var file = FileAccess.open("res://data/eventos.json", FileAccess.READ)
	if file:
		var texto = file.get_as_text()
		eventos = JSON.parse_string(texto)
		print("📜 %d eventos carregados." % eventos.size())
	else:
		print("❌ Falha ao carregar eventos.")

func check_for_event(mes: int, ano: int):
	for evento in eventos:
		if evento.has("ano") and evento.has("mes"):
			if evento["ano"] == ano and evento["mes"] == mes:
				mostrar_evento(evento)

func mostrar_evento(evento: Dictionary):
	print("📢 EVENTO: %s" % evento["titulo"])
	print("📖 %s" % evento["descricao"])
