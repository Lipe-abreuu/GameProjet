# res://scripts/GameMenu.gd
extends PanelContainer

# Sinais que o menu emitirá para o main.gd ouvir
signal resume_game
signal quit_to_main_menu

func _ready():
	# Conecta os sinais 'pressed' dos botões às funções deste script
	$VBoxContainer/ResumeButton.pressed.connect(_on_resume_button_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_resume_button_pressed():
	# Emite um sinal avisando que o jogo deve ser retomado
	emit_signal("resume_game")
	# Esconde o menu
	hide()

func _on_quit_button_pressed():
	# Emite um sinal avisando para voltar ao menu principal
	emit_signal("quit_to_main_menu")
