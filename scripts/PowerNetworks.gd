# res://scripts/PowerNetworks.gd
# Versão simplificada usando dicionários para evitar erros.
extends Node

var hidden_networks: Dictionary = {}

func _ready():
	initialize_chile_networks()

func initialize_chile_networks():
	# Agora usamos dicionários diretamente, sem a classe interna 'PowerNetwork'
	hidden_networks["escola_militar"] = {
		"id": "escola_militar", "name": "Ex-alunos da Escola Militar",
		"members": ["Augusto Pinochet", "Sergio Arellano", "Manuel Contreras"],
		"connection_type": "Educação Militar", "influence_level": 0.8,
		"clues": [
			"Pinochet e Arellano frequentaram a mesma turma.",
			"Decisões militares parecem contornar a hierarquia oficial.",
			"Há reuniões informais frequentes entre certos oficiais."
		],
		"discovered": false
	}
	
	hidden_networks["chicago_boys"] = {
		"id": "chicago_boys", "name": "Tecnocratas de Chicago",
		"members": ["Sergio de Castro", "Hernán Büchi", "Rolf Lüders"],
		"connection_type": "Educação (U. de Chicago)", "influence_level": 0.7,
		"clues": [
			"Um grupo de economistas parece ter uma agenda coordenada.",
			"Todos estudaram na mesma universidade estrangeira.",
			"Eles se apoiam mutuamente para nomeações em ministérios."
		],
		"discovered": false
	}
	
	print("REDES DE PODER (Simplificado) INICIALIZADAS: ", hidden_networks.keys())
