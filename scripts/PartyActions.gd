# res://scripts/PartyActions.gd
# Define quais ações o PARTIDO pode realizar em cada fase.
extends Node

func get_available_actions(party_data: PartyResource) -> Array:
	var actions = []
	match party_data.get_phase_name():
		"Grupo Político Informal":
			actions.append({"name": "Realizar Debate Ideológico", "cost": 5})
			actions.append({"name": "Distribuir Panfletos", "cost": 10})
		"Movimento Político Local":
			actions.append({"name": "Organizar Protesto Local", "cost": 25})
			actions.append({"name": "Publicar Manifesto", "cost": 15})
		# Adicione as ações para as outras fases aqui
	return actions
