# res://scripts/RaidManager.gd
extends Node

# Referência ao painel de escolha da raid na UI.
@onready var raid_choice_dialog: Panel = get_node("/root/Main/CanvasLayer/ChoiceDialog") # Adapte este caminho para a sua cena

func _ready():
	# Conecta ao sinal de raid do HeatSystem.
	HeatSystem.raid_triggered.connect(on_raid_triggered)

# Função chamada quando uma raid é acionada.
func on_raid_triggered():
	# Pausa o jogo ou entra em um estado de "alerta".
	get_tree().paused = true
	
	# Exibe o diálogo de escolha da raid.
	raid_choice_dialog.show()
	
	# TODO: Preencher o diálogo com as opções de raid.
	# Exemplo:
	# raid_choice_dialog.set_title("A POLÍCIA ESTÁ AQUI!")
	# raid_choice_dialog.set_description("O que você faz?")
	# raid_choice_dialog.add_choice("Subornar (-$1000)", "bribe")
	# raid_choice_dialog.add_choice("Resistir (Combate)", "resist")
	# raid_choice_dialog.add_choice("Destruir Provas (-10 Influência)", "destroy_evidence")

	# A lógica para lidar com a escolha do jogador seria conectada
	# a um sinal do seu ChoiceDialog.
	# Ex: raid_choice_dialog.choice_made.connect(handle_raid_choice)

func handle_raid_choice(choice_id: String):
	match choice_id:
		"bribe":
			# Lógica de suborno.
			# PartyController.money -= 1000
			print("Você subornou os oficiais.")
		"resist":
			# Lógica de combate.
			print("Você escolheu resistir!")
			# Iniciar cena de combate...
		"destroy_evidence":
			# Lógica para destruir provas.
			# PartyController.influence -= 10
			print("Você destruiu as provas.")
	
	# Despausa o jogo.
	get_tree().paused = false
	raid_choice_dialog.hide()
