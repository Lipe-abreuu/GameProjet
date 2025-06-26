# res://scripts/PartyActions.gd
# Define quais ações o PARTIDO pode realizar em cada fase de desenvolvimento.

extends Node

# A função recebe os dados do partido e retorna uma lista de ações disponíveis.
func get_available_actions(party_data: PartyResource) -> Array:
	var actions = []
	
	# Oferece ações diferentes com base na fase atual do partido.
	match party_data.get_phase_name():
		"Grupo Político Informal":
			actions.append({"name": "Realizar Debate Ideológico", "cost": 5})
			actions.append({"name": "Distribuir Panfletos", "cost": 10})
			
		"Movimento Político Local":
			actions.append({"name": "Organizar Protesto Local", "cost": 25})
			actions.append({"name": "Publicar Manifesto", "cost": 15})
			
		"Partido Emergente":
			actions.append({"name": "Lançar Candidato a Vereador", "cost": 100})
			actions.append({"name": "Buscar Apoio Sindical", "cost": 50})
		
		# Adicione aqui as ações para as outras fases do seu plano:
		# "Partido Relevante", "Partido Grande", "Partido Dominante"
			
	return actions
