
# =====================================
# ARQUIVO 1: PartyActions.gd - VERSÃO EXPANDIDA
# =====================================

# res://scripts/PartyActions.gd
# Define ações expandidas do PARTIDO para cada fase

extends Node

func get_available_actions(party_data: PartyResource) -> Array:
	var actions = []
	
	match party_data.get_phase_name():
		"Grupo Político Informal":
			# AÇÕES BÁSICAS
			actions.append({"name": "Realizar Debate Ideológico", "cost": 5, "description": "Eleva discussão política entre intelectuais"})
			actions.append({"name": "Distribuir Panfletos", "cost": 10, "description": "Conscientiza trabalhadores sobre direitos"})
			
			# NOVAS AÇÕES
			actions.append({"name": "Recrutar Intelectuais", "cost": 15, "description": "Busca acadêmicos e pensadores para o partido"})
			actions.append({"name": "Organizar Célula Clandestina", "cost": 20, "description": "Cria estrutura secreta para resistência"})
			actions.append({"name": "Buscar Financiamento", "cost": 5, "description": "Procura doadores simpáticos à causa"})
			actions.append({"name": "Infiltrar Universidade", "cost": 25, "description": "Ganha influência no movimento estudantil"})
		
		"Movimento Político Local":
			# AÇÕES EXISTENTES
			actions.append({"name": "Organizar Protesto Local", "cost": 25, "description": "Mobiliza manifestação pública"})
			actions.append({"name": "Publicar Manifesto", "cost": 15, "description": "Divulga posições políticas oficiais"})
			
			# NOVAS AÇÕES AVANÇADAS
			actions.append({"name": "Organizar Greve", "cost": 40, "description": "Paralisa setores econômicos estratégicos"})
			actions.append({"name": "Criar Jornal Underground", "cost": 30, "description": "Estabelece mídia alternativa"})
			actions.append({"name": "Infiltrar Sindicatos", "cost": 35, "description": "Ganha controle de organizações trabalhistas"})
			actions.append({"name": "Formar Milícia Popular", "cost": 50, "description": "Cria força paramilitar de autodefesa"})
			actions.append({"name": "Rede de Apoio Internacional", "cost": 45, "description": "Busca suporte de partidos estrangeiros"})
			actions.append({"name": "Sabotagem Econômica", "cost": 60, "description": "Ações diretas contra infraestrutura do regime"})
		
		"Partido Político Regional":
			# AÇÕES DE ALTO NÍVEL
			actions.append({"name": "Coordenar Resistência Nacional", "cost": 80, "description": "Organiza oposição em escala nacional"})
			actions.append({"name": "Operar Rádio Clandestina", "cost": 70, "description": "Transmite propaganda para todo o país"})
			actions.append({"name": "Estabelecer Governo Paralelo", "cost": 100, "description": "Cria estruturas administrativas alternativas"})
			actions.append({"name": "Operação de Exfiltração", "cost": 90, "description": "Retira militantes ameaçados do país"})
			actions.append({"name": "Infiltrar Forças Armadas", "cost": 120, "description": "Busca simpatizantes dentro do regime militar"})
		
		"Movimento Político Nacional":
			# AÇÕES FINAIS
			actions.append({"name": "Preparar Insurreição", "cost": 200, "description": "Planeja levante armado coordenado"})
			actions.append({"name": "Negociar Transição", "cost": 150, "description": "Busca acordo político para democracia"})
			actions.append({"name": "Mobilização Geral", "cost": 180, "description": "Convoca toda oposição para ação final"})
			actions.append({"name": "Operação Libertação", "cost": 250, "description": "Ataque final ao regime militar"})
		
		_:
			# Caso padrão: retorna pelo menos as ações básicas
			actions.append({"name": "Realizar Debate Ideológico", "cost": 5, "description": "Eleva discussão política entre intelectuais"})
			actions.append({"name": "Distribuir Panfletos", "cost": 10, "description": "Conscientiza trabalhadores sobre direitos"})
	
	return actions
